// SPDX-License-Identifier: MPL-2.0
use base64::{engine::general_purpose::STANDARD, Engine};
use fips204::{
    ml_dsa_65,
    traits::{KeyGen, SerDes},
};
use panll_provenance::*;
use proptest::prelude::*;

fn fixture() -> (Contribution, Vec<PublicKey>) {
    let (author, secret) = ml_dsa_65::KG::keygen_from_seed(&[1; 32]);
    let (witness, witness_secret) = ml_dsa_65::KG::keygen_from_seed(&[2; 32]);
    let keys: Vec<_> = [
        (author, "Author <author@example.org>"),
        (witness, "Witness <w@example.org>"),
    ]
    .into_iter()
    .map(|(key, identity)| {
        let bytes = key.into_bytes();
        PublicKey {
            key_id: hash(&bytes),
            author_identity: identity.into(),
            algorithm: ALGORITHM.into(),
            public_key: STANDARD.encode(bytes),
            valid_from: "2026-11-05T00:00:00Z".into(),
            valid_until: "2027-11-05T00:00:00Z".into(),
            revoked: false,
        }
    })
    .collect();
    let record = Record {
        version: 1,
        algorithm: ALGORITHM.into(),
        key_id: keys[0].key_id.clone(),
        author_identity: keys[0].author_identity.clone(),
        timestamp: "2026-11-06T12:00:00Z".into(),
        content_hash: hash(b"contribution"),
        parent_hash: None,
        platform: Some("test".into()),
        witnesses: vec![keys[1].key_id.clone()],
    };
    let signature = Some(sign(&record, &secret).unwrap());
    let attestations = vec![attest(&record, keys[1].key_id.clone(), &witness_secret).unwrap()];
    (
        Contribution {
            envelope: Envelope {
                record,
                signature,
                attestations,
            },
            content_base64: STANDARD.encode(b"contribution"),
        },
        keys,
    )
}

fn verify(entries: &[Contribution], keys: Vec<PublicKey>) -> Vec<Verdict> {
    verify_chain(
        entries,
        &Registry::new(keys).unwrap(),
        "2026-11-05T00:00:00Z",
        "2026-11-07T00:00:00Z",
    )
    .unwrap()
}

#[test]
fn signed_witnessed_round_trip_and_json_order() {
    let (entry, keys) = fixture();
    assert_eq!(
        verify(std::slice::from_ref(&entry), keys)[0].status,
        Status::Verified
    );
    let bytes = canonical(&entry.envelope.record).unwrap();
    let parsed: Record = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(
        record_hash(&parsed).unwrap(),
        record_hash(&entry.envelope.record).unwrap()
    );
    let duplicate = r#"{"version":1,"version":2}"#;
    assert!(serde_json::from_str::<Record>(duplicate).is_err());
    for field in ["parent-hash", "platform"] {
        let mut payload = serde_json::to_value(&entry.envelope.record).unwrap();
        payload.as_object_mut().unwrap().remove(field);
        assert!(
            serde_json::from_value::<Record>(payload).is_err(),
            "missing {field}"
        );
    }
}

#[test]
fn every_signed_field_is_bound() {
    let (entry, keys) = fixture();
    for field in [
        "version",
        "algorithm",
        "key-id",
        "author-identity",
        "timestamp",
        "content-hash",
        "parent-hash",
        "platform",
        "witnesses",
    ] {
        let mut json = serde_json::to_value(&entry).unwrap();
        let record = &mut json["envelope"]["record"];
        record[field] = match field {
            "version" => serde_json::json!(2),
            "witnesses" => serde_json::json!([]),
            "content-hash" | "key-id" | "parent-hash" => serde_json::json!("a".repeat(64)),
            "timestamp" => serde_json::json!("2026-11-06T13:00:00Z"),
            _ => serde_json::json!("changed"),
        };
        let tampered: Contribution = serde_json::from_value(json).unwrap();
        // An unknown author key is claimed, never verified.
        assert_ne!(
            verify(&[tampered], keys.clone())[0].status,
            Status::Verified,
            "{field}"
        );
    }
}

#[test]
fn trust_expiry_revocation_missing_witnesses_and_bad_signatures() {
    let (entry, keys) = fixture();
    assert_eq!(
        verify(std::slice::from_ref(&entry), vec![])[0].status,
        Status::Claimed
    );
    let mut revoked = keys.clone();
    revoked[0].revoked = true;
    assert_eq!(
        verify(std::slice::from_ref(&entry), revoked)[0].status,
        Status::Invalid
    );
    let mut expired = keys.clone();
    expired[0].valid_until = "2026-11-06T11:00:00Z".into();
    assert_eq!(
        verify(std::slice::from_ref(&entry), expired)[0].status,
        Status::Invalid
    );
    let mut unsigned = entry.clone();
    unsigned.envelope.signature = None;
    assert_eq!(verify(&[unsigned], keys.clone())[0].status, Status::Claimed);
    let mut missing = entry.clone();
    missing.envelope.attestations.clear();
    assert_eq!(verify(&[missing], keys.clone())[0].status, Status::Claimed);
    let mut bad = entry.clone();
    bad.envelope.signature = Some(STANDARD.encode([0; ml_dsa_65::SIG_LEN]));
    assert_eq!(verify(&[bad], keys.clone())[0].status, Status::Invalid);
    let mut bad = entry.clone();
    bad.envelope.attestations[0].signature = "bad".into();
    assert_eq!(verify(&[bad], keys.clone())[0].status, Status::Invalid);
    assert!(Registry::new(vec![keys[0].clone(), keys[0].clone()]).is_err());
    let mut same_identity = keys.clone();
    same_identity[1].author_identity = same_identity[0].author_identity.clone();
    assert_eq!(verify(&[entry], same_identity)[0].status, Status::Invalid);
}

fn child(parent: &Contribution, keys: &[PublicKey]) -> Contribution {
    let mut entry = parent.clone();
    entry.envelope.record.parent_hash = Some(record_hash(&parent.envelope.record).unwrap());
    entry.envelope.record.timestamp = "2026-11-06T13:00:00Z".into();
    let (_, author) = ml_dsa_65::KG::keygen_from_seed(&[1; 32]);
    let (_, witness) = ml_dsa_65::KG::keygen_from_seed(&[2; 32]);
    entry.envelope.signature = Some(sign(&entry.envelope.record, &author).unwrap());
    entry.envelope.attestations =
        vec![attest(&entry.envelope.record, keys[1].key_id.clone(), &witness).unwrap()];
    entry
}

#[test]
fn chain_removal_splice_reorder_and_untrusted_ancestors() {
    let (root, keys) = fixture();
    let next = child(&root, &keys);
    assert!(verify(&[root.clone(), next.clone()], keys.clone())
        .iter()
        .all(|v| v.status == Status::Verified));
    assert_eq!(
        verify(std::slice::from_ref(&next), keys.clone())[0].status,
        Status::Invalid
    );
    assert_eq!(
        verify(&[next.clone(), root.clone()], keys.clone())[1].status,
        Status::Invalid
    );
    assert_eq!(
        verify(&[root.clone(), root.clone()], keys.clone())[1].status,
        Status::Invalid
    );
    let mut claimed = root.clone();
    claimed.envelope.signature = None;
    assert_eq!(
        verify(&[claimed, next.clone()], keys.clone())[1].status,
        Status::Claimed
    );
    let mut invalid = root;
    invalid.content_base64 = STANDARD.encode(b"changed");
    assert_eq!(verify(&[invalid, next], keys)[1].status, Status::Invalid);
}

proptest! {
    #![proptest_config(ProptestConfig::with_cases(48))]
    #[test]
    fn arbitrary_content_mutations_are_invalid(bytes in proptest::collection::vec(any::<u8>(), 0..256)) {
        let (mut entry, keys) = fixture();
        prop_assume!(bytes != b"contribution");
        entry.content_base64 = STANDARD.encode(bytes);
        prop_assert_eq!(verify(&[entry], keys)[0].status, Status::Invalid);
    }
    #[test]
    fn arbitrary_metadata_mutations_never_verify(suffix in "[a-zA-Z0-9]{1,40}") {
        let (mut entry, keys) = fixture();
        entry.envelope.record.platform = Some(format!("test{suffix}"));
        prop_assert_eq!(verify(&[entry], keys)[0].status, Status::Invalid);
    }
    #[test]
    fn arbitrary_chain_splices_never_verify(bytes in any::<[u8; 32]>()) {
        let (root, keys) = fixture();
        let mut next = child(&root, &keys);
        let spliced = hash(&bytes);
        prop_assume!(Some(&spliced) != next.envelope.record.parent_hash.as_ref());
        next.envelope.record.parent_hash = Some(spliced);
        prop_assert_eq!(verify(&[root, next], keys)[1].status, Status::Invalid);
    }
}
