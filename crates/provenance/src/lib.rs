// SPDX-License-Identifier: MPL-2.0
//! Exhibit B v1. Trust comes from an independently approved key registry,
//! never from a key shipped inside a record. Git attribution stays claimed.
use base64::{engine::general_purpose::STANDARD, Engine};
use chrono::{DateTime, FixedOffset};
use fips204::{
    ml_dsa_65,
    traits::{SerDes, Signer, Verifier},
};
use serde::{Deserialize, Serialize};
use sha3::{Digest, Sha3_256};
use std::collections::{HashMap, HashSet};

pub const ALGORITHM: &str = "ML-DSA-65";
pub fn utc_timestamp(seconds: u64) -> Result<String, String> {
    let seconds = i64::try_from(seconds).map_err(|_| "clock overflow")?;
    chrono::DateTime::from_timestamp(seconds, 0)
        .map(|t| t.to_rfc3339())
        .ok_or_else(|| "timestamp outside supported range".into())
}
// Domain separation prevents signatures being reused by another protocol.
const CONTEXT: &[u8] = b"PanLL/Exhibit-B/v1";

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case", deny_unknown_fields)]
pub struct Record {
    pub version: u8,
    pub algorithm: String,
    pub key_id: String,
    pub author_identity: String,
    pub timestamp: String,
    pub content_hash: String,
    pub parent_hash: NullableString,
    pub platform: NullableString,
    /// Required witness key fingerprints, covered by the author's signature.
    pub witnesses: Vec<String>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case", deny_unknown_fields)]
pub struct Attestation {
    pub key_id: String,
    pub signature: String,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case", deny_unknown_fields)]
pub struct Envelope {
    pub record: Record,
    pub signature: NullableString,
    pub attestations: Vec<Attestation>,
}

/// A required wire field whose value can be a string or explicit JSON null.
/// Unlike Option, an absent field is an error: deleting it is not normalised.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(untagged)]
pub enum NullableString {
    Value(String),
    Null,
}

impl NullableString {
    pub fn as_ref(&self) -> Option<&String> {
        match self {
            Self::Value(value) => Some(value),
            Self::Null => None,
        }
    }
}

impl From<Option<String>> for NullableString {
    fn from(value: Option<String>) -> Self {
        match value {
            Some(value) => Self::Value(value),
            None => Self::Null,
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case", deny_unknown_fields)]
pub struct PublicKey {
    pub key_id: String,
    pub author_identity: String,
    pub algorithm: String,
    pub public_key: String,
    pub valid_from: String,
    pub valid_until: String,
    pub revoked: bool,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case", deny_unknown_fields)]
pub struct Contribution {
    pub envelope: Envelope,
    /// Actual bytes, not a hash reported by the distribution.
    pub content_base64: String,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum Status {
    Verified,
    Claimed,
    Invalid,
}

#[derive(Debug, Serialize)]
pub struct Verdict {
    pub status: Status,
    pub record_hash: String,
    pub reasons: Vec<String>,
}

pub fn hash(bytes: &[u8]) -> String {
    Sha3_256::digest(bytes)
        .iter()
        .map(|b| format!("{b:02x}"))
        .collect()
}

pub fn canonical(record: &Record) -> Result<Vec<u8>, String> {
    serde_jcs::to_vec(record).map_err(|e| e.to_string())
}

pub fn record_hash(record: &Record) -> Result<String, String> {
    canonical(record).map(|bytes| hash(&bytes))
}

pub fn sign(record: &Record, key: &ml_dsa_65::PrivateKey) -> Result<String, String> {
    key.try_sign(&canonical(record)?, CONTEXT)
        .map(|sig| STANDARD.encode(sig))
        .map_err(str::to_owned)
}

pub fn attest(
    record: &Record,
    key_id: String,
    key: &ml_dsa_65::PrivateKey,
) -> Result<Attestation, String> {
    if !record.witnesses.contains(&key_id) || record.key_id == key_id {
        return Err("witness must be declared and distinct from author".into());
    }
    Ok(Attestation {
        key_id,
        signature: sign(record, key)?,
    })
}

fn timestamp(value: &str) -> Result<DateTime<FixedOffset>, String> {
    DateTime::parse_from_rfc3339(value).map_err(|_| "timestamp must be RFC 3339 with a zone".into())
}

fn digest_format(value: &str) -> bool {
    value.len() == 64
        && value
            .bytes()
            .all(|c| c.is_ascii_digit() || (b'a'..=b'f').contains(&c))
}

/// Registry construction fails closed on duplicate fingerprints,
/// malformed keys or validity periods longer than the annual rotation limit.
pub struct Registry(HashMap<String, PublicKey>);
impl Registry {
    pub fn new(keys: Vec<PublicKey>) -> Result<Self, String> {
        let mut registry = HashMap::new();
        for key in keys {
            let bytes = STANDARD
                .decode(&key.public_key)
                .map_err(|e| e.to_string())?;
            let from = timestamp(&key.valid_from)?;
            let until = timestamp(&key.valid_until)?;
            let duration = until.signed_duration_since(from);
            if key.algorithm != ALGORITHM
                || key.author_identity.trim().is_empty()
                || key.key_id != hash(&bytes)
                || duration.num_seconds() <= 0
                || duration.num_seconds() > 366 * 86400
            {
                return Err("invalid public key metadata or rotation window".into());
            }
            let raw: [u8; ml_dsa_65::PK_LEN] =
                bytes.try_into().map_err(|_| "wrong public key length")?;
            ml_dsa_65::PublicKey::try_from_bytes(raw).map_err(str::to_owned)?;
            if registry.insert(key.key_id.clone(), key).is_some() {
                return Err("duplicate public key fingerprint".into());
            }
        }
        Ok(Self(registry))
    }

    fn verify_signature(
        &self,
        id: &str,
        identity: Option<&str>,
        time: DateTime<FixedOffset>,
        message: &[u8],
        signature: &str,
    ) -> Result<bool, String> {
        // Reject malformed signatures even if their key is not trusted.
        let signature: [u8; ml_dsa_65::SIG_LEN] = STANDARD
            .decode(signature)
            .map_err(|_| "invalid signature encoding")?
            .try_into()
            .map_err(|_| "wrong signature length")?;
        let Some(key) = self.0.get(id) else {
            return Ok(false);
        };
        if key.revoked
            || identity.is_some_and(|identity| identity != key.author_identity)
            || time < timestamp(&key.valid_from)?
            || time > timestamp(&key.valid_until)?
        {
            return Err("revoked, expired, not-yet-valid or identity-mismatched key".into());
        }
        let raw: [u8; ml_dsa_65::PK_LEN] = STANDARD
            .decode(&key.public_key)
            .map_err(|e| e.to_string())?
            .try_into()
            .map_err(|_| "wrong public key length")?;
        let public = ml_dsa_65::PublicKey::try_from_bytes(raw).map_err(str::to_owned)?;
        if !public.verify(message, &signature, CONTEXT) {
            return Err("signature mismatch".into());
        }
        Ok(true)
    }
}

struct ChainState {
    parent: Option<String>,
    parent_status: Status,
    parent_time: Option<DateTime<FixedOffset>>,
    seen: HashSet<String>,
    earliest: DateTime<FixedOffset>,
    latest: DateTime<FixedOffset>,
}

fn verify_witnesses(
    envelope: &Envelope,
    keys: &Registry,
    time: DateTime<FixedOffset>,
    message: &[u8],
) -> Result<bool, String> {
    let record = &envelope.record;
    let declared: HashSet<_> = record.witnesses.iter().collect();
    if declared.len() != record.witnesses.len()
        || declared.contains(&record.key_id)
        || record.witnesses.iter().any(|id| !digest_format(id))
    {
        return Err("duplicate, malformed or self witness".into());
    }
    let mut supplied = HashSet::new();
    let mut complete = !declared.is_empty();
    for attestation in &envelope.attestations {
        if !declared.contains(&attestation.key_id) || !supplied.insert(attestation.key_id.clone()) {
            return Err("undeclared or duplicate witness attestation".into());
        }
        if let (Some(author), Some(witness)) =
            (keys.0.get(&record.key_id), keys.0.get(&attestation.key_id))
        {
            if author.author_identity == witness.author_identity {
                return Err("author cannot witness own record".into());
            }
        }
        complete &= keys.verify_signature(
            &attestation.key_id,
            None,
            time,
            message,
            &attestation.signature,
        )?;
    }
    Ok(complete && supplied.len() == declared.len())
}

fn verify_entry(
    entry: &Contribution,
    keys: &Registry,
    id: &str,
    state: &mut ChainState,
) -> Result<(bool, DateTime<FixedOffset>), String> {
    let record = &entry.envelope.record;
    if record.version != 1
        || record.algorithm != ALGORITHM
        || record.author_identity.trim().is_empty()
        || !digest_format(&record.key_id)
        || !digest_format(&record.content_hash)
    {
        return Err("unsupported or malformed record".into());
    }
    let time = timestamp(&record.timestamp)?;
    if time < state.earliest || time > state.latest || state.parent_time.is_some_and(|p| time < p) {
        return Err("timestamp outside policy window or before parent".into());
    }
    if record.parent_hash.as_ref() != state.parent.as_ref() || !state.seen.insert(id.to_owned()) {
        return Err("missing, reordered, duplicate or spliced chain link".into());
    }
    let content = STANDARD
        .decode(&entry.content_base64)
        .map_err(|_| "invalid content encoding")?;
    if hash(&content) != record.content_hash {
        return Err("content hash mismatch".into());
    }
    let message = canonical(record)?;
    let author_verified = match entry.envelope.signature.as_ref() {
        Some(sig) => keys.verify_signature(
            &record.key_id,
            Some(&record.author_identity),
            time,
            &message,
            sig,
        )?,
        None => false,
    };
    // Evaluate witnesses even when the author is unknown: a supplied invalid
    // witness signature is invalid, rather than merely incomplete evidence.
    let witnesses_verified = verify_witnesses(&entry.envelope, keys, time, &message)?;
    Ok((author_verified && witnesses_verified, time))
}

/// Verify a complete, ordered chain from its adoption root. The caller supplies
/// a trusted time window; no record is permitted to select its own clock.
/// A verified child cannot promote an unverified ancestor to verified.
pub fn verify_chain(
    entries: &[Contribution],
    keys: &Registry,
    earliest: &str,
    latest: &str,
) -> Result<Vec<Verdict>, String> {
    let earliest = timestamp(earliest)?;
    let latest = timestamp(latest)?;
    if earliest > latest {
        return Err("inverted timestamp window".into());
    }
    let mut state = ChainState {
        parent: None,
        parent_status: Status::Verified,
        parent_time: None,
        seen: HashSet::new(),
        earliest,
        latest,
    };
    let mut results = Vec::new();
    for entry in entries {
        let id = record_hash(&entry.envelope.record)?;
        let mut reasons = Vec::new();
        let status = match verify_entry(entry, keys, &id, &mut state) {
            Err(reason) => {
                reasons.push(reason);
                Status::Invalid
            }
            Ok((complete, time)) => {
                state.parent_time = Some(time);
                match (state.parent_status, complete) {
                    (Status::Invalid, _) => {
                        reasons.push("invalid ancestor".into());
                        Status::Invalid
                    }
                    (Status::Verified, true) => Status::Verified,
                    _ => {
                        reasons.push(
                            "unsigned, unknown key, incomplete witnesses or claimed ancestor"
                                .into(),
                        );
                        Status::Claimed
                    }
                }
            }
        };
        state.parent = Some(id.clone());
        state.parent_status = status;
        results.push(Verdict {
            status,
            record_hash: id,
            reasons,
        });
    }
    Ok(results)
}
