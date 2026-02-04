;; SPDX-License-Identifier: PMPL-1.0-or-later
;;
;; PanLL eNSAID - Meta Information
;; Architecture Decisions & Development Practices

(meta
  (architecture-decisions
    (adr-001
      (status accepted)
      (date "2026-01-16")
      (title "Use ReScript-TEA over React/Zustand")
      (context "Gemini suggested React/Zustand but this conflicts with
                hyperpolymath language policy (no TypeScript/raw JS)
                and doesn't align with the deterministic 'Gravitational
                Synchronicity' vision")
      (decision "Use ReScript with TEA (The Elm Architecture) pattern.
                 TEA's deterministic Model-Update-View cycle mirrors
                 the Binary Star co-orbit concept better than React's
                 component-based model")
      (consequences
        "Pros: Type safety, predictable state, aligns with spec vision"
        "Cons: Smaller ecosystem, may need custom rescript-tea fork"))

    (adr-002
      (status accepted)
      (date "2026-01-16")
      (title "Three-Pane Parallel Architecture")
      (context "Need to implement HTI (Human-Things Interface) with
                visibility into both symbolic and neural subsystems")
      (decision "Implement Pane-L (Symbolic), Pane-N (Neural), Pane-W (World)
                 as semantically synchronised TEA components with shared
                 state and cross-pane linking")
      (consequences
        "Pros: Clear separation of concerns, explicit sync points"
        "Cons: Complex state management, potential sync latency"))

    (adr-003
      (status proposed)
      (date "2026-01-16")
      (title "Echidna for Symbolic Validation")
      (context "Anti-Crash Library needs formal verification capability
                to validate neural tokens against symbolic constraints")
      (decision "Integrate Echidna (or similar SAT/SMT solver) as the
                 Logical Circuit Breaker backend")
      (consequences
        "Pros: Formal guarantees, proven technology"
        "Cons: Integration complexity, performance overhead")))

  (development-practices
    (code-style
      (language "ReScript")
      (pattern "TEA (The Elm Architecture)")
      (formatting "rescript format")
      (naming "descriptive, British English spelling"))

    (security
      (constraint-validation "All neural tokens must pass Anti-Crash")
      (no-eval "Never use dynamic code execution")
      (type-safety "ReScript strict mode enforced")

      ;; Cryptographic Requirements (for future auth/crypto features)
      (password-hashing "Argon2id (512 MiB, 8 iter, 4 lanes) - max resistance to GPU/ASIC attacks")
      (general-hashing "SHAKE3-512 (512-bit output, FIPS 202) - post-quantum for provenance/key derivation")
      (pq-signatures "Dilithium5-AES hybrid (ML-DSA-87, FIPS 204) with SPHINCS+ backup")
      (pq-key-exchange "Kyber-1024 + SHAKE256-KDF (ML-KEM-1024, FIPS 203)")
      (classical-sigs "Ed448 + Dilithium5 hybrid - TERMINATE Ed25519/SHA-1 immediately")
      (symmetric "XChaCha20-Poly1305 (256-bit key) - larger nonce space for quantum margin")
      (key-derivation "HKDF-SHAKE512 (FIPS 202) - post-quantum KDF for all secret material")
      (rng "ChaCha20-DRBG (512-bit seed, SP 800-90Ar1) - CSPRNG for high-entropy needs")
      (database-hashing "BLAKE3 (512-bit) + SHAKE3-512 - speed + long-term storage")
      (formal-verification "Idris2/Coq for crypto primitives - proactive attestation required")
      (protocol-stack "QUIC + HTTP/3 + IPv6 ONLY - terminate HTTP/1.1, IPv4, SHA-1")
      (fallback "SPHINCS+ as conservative PQ backup for all hybrid systems"))

    (testing
      (unit "rescript-test for pure functions")
      (integration "Tauri test harness")
      (e2e "Playwright when applicable"))

    (versioning
      (scheme "semver")
      (changelog "CHANGELOG.md"))

    (documentation
      (inline "ReScript doc comments")
      (architecture "ADRs in META.scm")
      (user "README.adoc"))

    (branching
      (main "stable releases")
      (develop "integration branch")
      (feature "feature/* branches")))

  (design-rationale
    (why-tea "TEA's deterministic update cycle provides the
              'Gravitational Synchronicity' needed for Binary Star
              co-orbit between Human and Machine")

    (why-rescript "Type safety without TypeScript. Compiles to clean JS.
                   Aligns with hyperpolymath language policy")

    (why-tauri "Native performance, minimal footprint, Rust backend
                for Anti-Crash validation performance")

    (why-vexometer "Proactive cognitive ergonomics - the environment
                    should adapt to the operator, not vice versa")

    (why-anti-crash "LLM output is probabilistic and can drift.
                     Symbolic constraints provide guardrails.
                     No neural token reaches the Barycentre without
                     passing the Logical Circuit Breaker")))
