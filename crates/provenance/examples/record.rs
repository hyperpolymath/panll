// SPDX-License-Identifier: MPL-2.0
//! Offline signing helper. Secret keys never pass through desktop IPC.
use base64::{engine::general_purpose::STANDARD, Engine};
use fips204::{
    ml_dsa_65,
    traits::{KeyGen, SerDes},
};
use panll_provenance::*;
use std::{fs, io::Write, path::Path};

fn read<T: serde::de::DeserializeOwned>(path: &str) -> Result<T, String> {
    serde_json::from_slice(&fs::read(path).map_err(|e| e.to_string())?).map_err(|e| e.to_string())
}

fn write_new(path: &str, bytes: &[u8], secret: bool) -> Result<(), String> {
    let mut options = fs::OpenOptions::new();
    options.write(true).create_new(true);
    #[cfg(unix)]
    {
        use std::os::unix::fs::OpenOptionsExt;
        options.mode(if secret { 0o600 } else { 0o644 });
    }
    #[cfg(not(unix))]
    let _ = secret; // On Windows, use a directory with a private inherited ACL.
    options
        .open(path)
        .and_then(|mut f| f.write_all(bytes))
        .map_err(|e| e.to_string())
}

fn secret(path: &str) -> Result<ml_dsa_65::PrivateKey, String> {
    let encoded = fs::read_to_string(path).map_err(|e| e.to_string())?;
    let bytes: [u8; ml_dsa_65::SK_LEN] = STANDARD
        .decode(encoded.trim())
        .map_err(|e| e.to_string())?
        .try_into()
        .map_err(|_| "wrong private key length")?;
    ml_dsa_65::PrivateKey::try_from_bytes(bytes).map_err(str::to_owned)
}

fn run(args: &[String]) -> Result<(), String> {
    match args {
        [command, identity, from, until, public, private] if command == "keygen" => {
            // Refuse a private key inside any Git working tree.
            let directory = Path::new(private).parent().filter(|p| !p.as_os_str().is_empty()).unwrap_or(Path::new("."));
            if std::process::Command::new("git").args(["rev-parse", "--is-inside-work-tree"])
                .current_dir(directory).output().map_err(|e| e.to_string())?.status.success() {
                return Err("store the private key outside a Git working tree".into());
            }
            let (pk, sk) = ml_dsa_65::KG::try_keygen().map_err(str::to_owned)?;
            let bytes = pk.into_bytes();
            let key = PublicKey { key_id: hash(&bytes), author_identity: identity.clone(), algorithm: ALGORITHM.into(),
                public_key: STANDARD.encode(bytes), valid_from: from.clone(), valid_until: until.clone(), revoked: false };
            Registry::new(vec![key.clone()])?;
            write_new(private, STANDARD.encode(sk.into_bytes()).as_bytes(), true)?;
            write_new(public, &serde_json::to_vec_pretty(&key).map_err(|e| e.to_string())?, false)
        },
        [command, record, private, output] if command == "sign" => {
            let record: Record = read(record)?;
            let signature = Some(sign(&record, &secret(private)?)?);
            let envelope = Envelope { record, signature, attestations: vec![] };
            write_new(output, &serde_json::to_vec_pretty(&envelope).map_err(|e| e.to_string())?, false)
        },
        [command, input, public, private, output] if command == "witness" => {
            let mut envelope: Envelope = read(input)?;
            let key: PublicKey = read(public)?;
            Registry::new(vec![key.clone()])?;
            envelope.attestations.push(attest(&envelope.record, key.key_id, &secret(private)?)?);
            write_new(output, &serde_json::to_vec_pretty(&envelope).map_err(|e| e.to_string())?, false)
        },
        _ => Err("usage: record keygen IDENTITY FROM UNTIL PUBLIC.json PRIVATE.key | sign RECORD.json PRIVATE.key OUT.json | witness ENVELOPE.json PUBLIC.json PRIVATE.key OUT.json".into()),
    }
}

fn main() {
    if let Err(error) = run(&std::env::args().skip(1).collect::<Vec<_>>()) {
        eprintln!("{error}");
        std::process::exit(1);
    }
}
