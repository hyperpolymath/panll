;; SPDX-License-Identifier: PMPL-1.0-or-later
;; SECURITY.scm - PanLL cryptographic requirements (machine-readable)

(define user-security-requirements
  '(
    ;; Category, Algorithm/Standard, NIST/FIPS Standard, Notes
    (PasswordHashing "Argon2id (512 MiB, 8 iter, 4 lanes)" "N/A"
      "Max memory/iterations for GPU/ASIC resistance; aligns with proactive security stance.")
    (GeneralHashing "SHAKE3-512 (512-bit output)" "FIPS 202"
      "Post-quantum; use for provenance, key derivation, and long-term storage.")
    (PQSignatures "Dilithium5-AES (hybrid)" "ML-DSA-87 (FIPS 204)"
      "Hybrid with AES-256 for belt-and-suspenders security. SPHINCS+ as conservative backup.")
    (PQKeyExchange "Kyber-1024 + SHAKE256-KDF" "ML-KEM-1024 (FIPS 203)"
      "Kyber-1024 for KEM, SHAKE256 for key derivation. SPHINCS+ as backup.")
    (ClassicalSigs "Ed448 + Dilithium5 (hybrid)" "N/A"
      "Ed448 for classical compatibility; Dilithium5 for PQ. SPHINCS+ as backup. Terminate Ed25519/SHA-1 immediately.")
    (Symmetric "XChaCha20-Poly1305 (256-bit key)" "N/A"
      "Larger nonce space; 256-bit keys for quantum margin.")
    (KeyDerivation "HKDF-SHAKE512" "FIPS 202"
      "Post-quantum KDF; use with all secret key material.")
    (RNG "ChaCha20-DRBG (512-bit seed)" "SP 800-90Ar1"
      "CSPRNG for deterministic, high-entropy needs.")
    (UserFriendlyHashNames "Base32(SHAKE256(hash)) -> Wordlist" "N/A"
      "Memorable, deterministic mapping (e.g., \"Gigantic-Giraffe-7\" for drivers).")
    (DatabaseHashing "BLAKE3 (512-bit) + SHAKE3-512" "N/A"
      "BLAKE3 for speed, SHAKE3-512 for long-term storage (semantic XML/ARIA tags).")
    (SemanticXMLGraphQL "Virtuoso (VOS) + SPARQL 1.2" "N/A"
      "Supports WCAG 2.3 AAA, ARIA, and formal verification for accessibility/compliance.")
    (VMExecution "GraalVM (with formal verification)" "N/A"
      "Aligns with preference for introspective, reversible design.")
    (ProtocolStack "QUIC + HTTP/3 + IPv6 (IPv4 disabled)" "N/A"
      "Terminate HTTP/1.1, IPv4, and SHA-1 per \"danger zone\" policy.")
    (Accessibility "WCAG 2.3 AAA + ARIA + Semantic XML" "N/A"
      "CSS-first, HTML-second; full compliance with accessibility requirements.")
    (Fallback "SPHINCS+" "N/A"
      "Conservative PQ backup for all hybrid classical+PQ systems; use if primary PQ algorithm is ever compromised.")
    (FormalVerification "Coq/Isabelle (for crypto primitives)" "N/A"
      "Proactive attestation and transparent logic per system design principles.")
  )
)
