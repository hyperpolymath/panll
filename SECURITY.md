# Security Policy

We take security seriously. We appreciate your efforts to responsibly disclose vulnerabilities and will make every effort to acknowledge your contributions.

## Table of Contents

- [Reporting a Vulnerability](#reporting-a-vulnerability)
- [Cryptographic Requirements](#cryptographic-requirements)
- [Response Timeline](#response-timeline)
- [Disclosure Policy](#disclosure-policy)
- [Scope](#scope)
- [Safe Harbour](#safe-harbour)
- [Security Updates](#security-updates)
- [Security Best Practices](#security-best-practices)

---

## Reporting a Vulnerability

### Preferred Method: GitHub Security Advisories

The preferred method for reporting security vulnerabilities is through GitHub's Security Advisory feature:

1. Navigate to [Report a Vulnerability](https://github.com/hyperpolymath/panll/security/advisories/new)
2. Click **"Report a vulnerability"**
3. Complete the form with as much detail as possible
4. Submit — we'll receive a private notification

This method ensures:

- End-to-end encryption of your report
- Private discussion space for collaboration
- Coordinated disclosure tooling
- Automatic credit when the advisory is published

### Alternative: Encrypted Email

If you cannot use GitHub Security Advisories, you may email us directly at:

**Email:** jonathan.jewell@open.ac.uk

> **⚠️ Important:** Do not report security vulnerabilities through public GitHub issues, pull requests, discussions, or social media.

---

## Cryptographic Requirements

When implementing cryptographic features in this project, the following standards MUST be followed:

### Password Hashing
- **Algorithm:** Argon2id
- **Parameters:** 512 MiB memory, 8 iterations, 4 lanes
- **Rationale:** Maximum resistance to GPU/ASIC attacks

### General Hashing
- **Algorithm:** SHAKE3-512 (512-bit output)
- **Standard:** FIPS 202
- **Use Cases:** Provenance, key derivation, long-term storage
- **Rationale:** Post-quantum secure

### Post-Quantum Signatures
- **Primary:** Dilithium5-AES (hybrid)
- **Standard:** ML-DSA-87 (FIPS 204)
- **Fallback:** SPHINCS+ (conservative backup)
- **Rationale:** Hybrid with AES-256 for belt-and-suspenders security

### Post-Quantum Key Exchange
- **Algorithm:** Kyber-1024 + SHAKE256-KDF
- **Standard:** ML-KEM-1024 (FIPS 203)
- **Fallback:** SPHINCS+
- **Rationale:** Maximum PQ security level

### Classical Signatures
- **Algorithm:** Ed448 + Dilithium5 (hybrid)
- **Fallback:** SPHINCS+
- **⚠️ CRITICAL:** TERMINATE Ed25519/SHA-1 immediately - do not use in new code

### Symmetric Encryption
- **Algorithm:** XChaCha20-Poly1305
- **Key Size:** 256-bit
- **Rationale:** Larger nonce space, quantum margin

### Key Derivation
- **Algorithm:** HKDF-SHAKE512
- **Standard:** FIPS 202
- **Use:** All secret key material
- **Rationale:** Post-quantum secure KDF

### Random Number Generation
- **Algorithm:** ChaCha20-DRBG
- **Seed Size:** 512-bit
- **Standard:** SP 800-90Ar1
- **Use:** CSPRNG for deterministic, high-entropy needs

### Database Hashing
- **Primary:** BLAKE3 (512-bit)
- **Long-term:** SHAKE3-512
- **Rationale:** BLAKE3 for speed, SHAKE3-512 for archival with semantic XML/ARIA tags

### Protocol Stack
- **Required:** QUIC + HTTP/3 + IPv6 only
- **⚠️ TERMINATED:** HTTP/1.1, IPv4, SHA-1 (danger zone)

### Formal Verification
- **Tool:** Idris2/Coq
- **Requirement:** All cryptographic primitives must have formal proofs
- **Rationale:** Proactive attestation and transparent logic

---

## Response Timeline

We commit to the following response times:

| Stage | Timeframe | Description |
|-------|-----------|-------------|
| **Initial Response** | 48 hours | We acknowledge receipt and confirm we're investigating |
| **Triage** | 7 days | We assess severity, confirm the vulnerability, and estimate timeline |
| **Status Update** | Every 7 days | Regular updates on remediation progress |
| **Resolution** | 90 days | Target for fix development and release (complex issues may take longer) |
| **Disclosure** | 90 days | Public disclosure after fix is available (coordinated with you) |

---

## Disclosure Policy

We follow **coordinated disclosure** (also known as responsible disclosure):

1. **You report** the vulnerability privately
2. **We acknowledge** and begin investigation
3. **We develop** a fix and prepare a release
4. **We coordinate** disclosure timing with you
5. **We publish** security advisory and fix simultaneously
6. **You may publish** your research after disclosure

---

## Scope

### In Scope ✅

- This repository (`hyperpolymath/panll`) and all its code
- Official releases and packages published from this repository
- Documentation that could lead to security issues
- Build and deployment configurations in this repository
- Dependencies (report here, we'll coordinate with upstream)

### Qualifying Vulnerabilities

We're particularly interested in:

- Remote code execution
- SQL injection, command injection, code injection
- Authentication/authorisation bypass
- Cross-site scripting (XSS) and cross-site request forgery (CSRF)
- Server-side request forgery (SSRF)
- Path traversal / local file inclusion
- Information disclosure (credentials, PII, secrets)
- **Cryptographic weaknesses** (especially deviation from requirements above)
- Deserialisation vulnerabilities
- Memory safety issues (buffer overflows, use-after-free, etc.)
- Supply chain vulnerabilities (dependency confusion, etc.)
- Significant logic flaws in Anti-Crash validation

---

## Safe Harbour

We support security research conducted in good faith.

### Our Promise

If you conduct security research in accordance with this policy:

- ✅ We will not initiate legal action against you
- ✅ We will not report your activity to law enforcement
- ✅ We will work with you in good faith to resolve issues
- ✅ We consider your research authorised

---

## Security Updates

### Receiving Updates

To stay informed about security updates:

- **Watch this repository**: Click "Watch" → "Custom" → "Security alerts"
- **GitHub Security Advisories**: Published at [Security Advisories](https://github.com/hyperpolymath/panll/security/advisories)

### Supported Versions

| Version | Supported | Notes |
|---------|-----------|-------|
| `main` branch | ✅ Yes | Latest development |
| Latest release | ✅ Yes | Current stable |
| Older versions | ❌ No | Please upgrade |

---

## Security Best Practices

When using PanLL eNSAID, we recommend:

### General

- Keep dependencies up to date
- Use the latest stable release
- Subscribe to security notifications
- Review configuration against security documentation
- Follow principle of least privilege

### For Contributors

- Never commit secrets, credentials, or API keys
- Use signed commits (`git config commit.gpgsign true`)
- Review dependencies before adding them
- Run security linters locally before pushing
- Report any concerns about existing code
- **NEVER use deprecated crypto:** Ed25519, SHA-1, MD5, DES, RC4
- **ALWAYS use approved algorithms** from the Cryptographic Requirements section

---

*Thank you for helping keep PanLL and its users safe.* 🛡️

---

<sub>Last updated: 2026-02-04 · Policy version: 2.0.0</sub>
