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
      (type-safety "ReScript strict mode enforced"))

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
