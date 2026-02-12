;; SPDX-License-Identifier: PMPL-1.0-or-later
;; ECOSYSTEM.scm - PanLL's position in the hyperpolymath ecosystem

(ecosystem
  (version "1.0.0")
  (last-updated "2026-02-09")
  (format-spec "hyperpolymath/rsr-template-repo/spec/ECOSYSTEM-FORMAT-SPEC.adoc")

  (identity
    (name "panll")
    (full-name "PanLL eNSAID")
    (tagline "Environment for NeSy-Agentic Integrated Development")
    (type "application")
    (category "neurosymbolic-tools")
    (maturity "alpha")
    (version "0.1.0"))

  (purpose
    "PanLL is a Human-Things Interface (HTI) designed for genuine co-working between "
    "Human Operators and Neurosymbolic Machines. It implements a 'Binary Star' architecture "
    "where Human and Machine orbit a shared task Barycentre, with real-time constraint "
    "validation (Anti-Crash), cognitive load monitoring (Vexometer), and synchronous "
    "three-pane layout (Symbolic/Neural/World).")

  (position-in-ecosystem
    (domain "neurosymbolic-tooling")
    (role "development-environment")
    (scope "Human-Machine co-working for NeSy-Agentic tasks")

    (unique-value-proposition
      "First IDE treating AI as equal co-worker (Binary Star) rather than subordinate tool. "
      "Combines symbolic constraints (Pane-L) with neural inference stream (Pane-N) and "
      "validated output (Pane-W). Anti-Crash circuit breaker prevents unvalidated neural "
      "output from corrupting workspace. Vexometer tracks cognitive load and adapts UI.")

    (target-users
      ("Researchers developing neurosymbolic AI systems")
      ("Developers building agentic applications")
      ("Operators working with AI agents on complex tasks")
      ("Teams exploring Human-AI co-working patterns"))

    (integration-points
      ("Tauri 2.0 - Desktop app framework")
      ("ReScript - Type-safe frontend compilation")
      ("Custom TEA - The Elm Architecture state management")
      ("Deno - Runtime and test infrastructure")
      ("Tailwind CSS - Styling framework")
      ("@tauri-apps/api - Tauri command bridge")))

  (related-projects
    ((project "panic-attack")
     (relationship "producer")
     (nature "Panic-attack exports ambush event-chain timelines for PanLL ingestion and visualisation")
     (integration-status "active")
     (notes "Use panic-attack panll export to feed event-chain data into PanLL workflows"))

    ((project "hypatia")
     (relationship "potential-consumer")
     (nature "Hypatia (neurosymbolic CI/CD) could use PanLL UI for visualising build reasoning chains")
     (integration-status "future")
     (notes "Pane-N could show Hypatia's OODA loop during CI/CD runs"))

    ((project "gitvisor")
     (relationship "sibling-tool")
     (nature "Both are Human-Machine co-working tools (PanLL for general dev, gitvisor for Git archaeology)")
     (integration-status "none")
     (notes "Complementary: PanLL for active development, gitvisor for repository analysis"))

    ((project "git-seo")
     (relationship "sibling-tool")
     (nature "Both improve developer experience (PanLL for co-working, git-seo for discoverability)")
     (integration-status "none")
     (notes "git-seo could benefit from PanLL's constraint-based interface design"))

    ((project "0-ai-gatekeeper-protocol")
     (relationship "dependency")
     (nature "PanLL follows AI Gatekeeper Protocol (0-AI-MANIFEST.a2ml, .machine_readable/ SCM files)")
     (integration-status "active")
     (notes "PanLL has 0-AI-MANIFEST.a2ml declaring canonical locations and invariants"))

    ((project "rsr-template-repo")
     (relationship "template-source")
     (nature "PanLL should follow RSR (Repository Structure Requirements) template")
     (integration-status "partial")
     (notes "Has AI manifest, PMPL license, but missing .machine_readable/ SCM files (being added now)"))

    ((project "scaffoldia")
     (relationship "potential-tool")
     (nature "Scaffoldia (project scaffolding) could generate PanLL-compatible project templates")
     (integration-status "future")
     (notes "PanLL projects might have specific structure (L/N/W panes, constraint files)"))

    ((project "ochrance")
     (relationship "sibling-standard")
     (nature "Both explore Human-Machine foundations (PanLL for co-working, ochrance for access control)")
     (integration-status "none")
     (notes "Ochrance's PALIMPSEST-PMPL license = PanLL's PMPL-1.0-or-later license"))

    ((project "gitbot-fleet")
     (relationship "potential-automation")
     (nature "gitbot-fleet (rhodibot, echidnabot, etc.) could benefit from PanLL's constraint-based validation")
     (integration-status "future")
     (notes "PanLL's Anti-Crash pattern applicable to bot guardrails"))

    ((project "git-hud")
     (relationship "potential-integration")
     (nature "git-hud (Git HUD overlay) could show PanLL's orbital stability metrics in dashboard")
     (integration-status "future")
     (notes "Sigma (stability), vexation index as real-time metrics"))

    ((project "eclexia")
     (relationship "potential-language-backend")
     (nature "Eclexia programming language with shadow pricing and carbon-aware scheduling could serve as PanLL's symbolic constraint language")
     (integration-status "future")
     (notes "Integration path: Eclexia constraint expressions in Pane-L, shadow-priced inference in Pane-N. Eclexia's formal proofs could power Anti-Crash validation. DB connectors follow Idris2 ABI + Zig FFI pattern. Requires Eclexia runtime stabilisation (currently ~45% complete).")))

  (dependencies
    (runtime
      ((name "Deno")
       (version "1.x")
       (purpose "Build orchestration, Tailwind CSS compilation")
       (license "MIT")
       (criticality "high"))

      ((name "Node.js")
       (version "18.x+")
       (purpose "ReScript compiler runtime (temporary, until Deno support)")
       (license "MIT")
       (criticality "medium")
       (planned-removal "When ReScript adds Deno support")))

    (build-time
      ((name "ReScript")
       (version "11.1.4")
       (purpose "Type-safe frontend compilation")
       (license "MIT")
       (criticality "critical"))

      ((name "Tailwind CSS")
       (version "4.1.18")
       (purpose "Styling framework")
       (license "MIT")
       (criticality "medium"))

      ((name "Tauri CLI")
       (version "2.0.0")
       (purpose "Desktop app bundling")
       (license "MIT/Apache-2.0")
       (criticality "critical")))

    (libraries
      ((name "rescript-tea")
       (version "0.16.0")
       (purpose "The Elm Architecture (TEA) state management")
       (license "MIT")
       (criticality "critical")
       (migration-note "Migrating from custom TEA to this official library"))

      ((name "rescript-webapi")
       (version "0.10.0")
       (purpose "Browser API bindings")
       (license "MIT")
       (criticality "medium"))

      ((name "@rescript/core")
       (version "1.6.1")
       (purpose "ReScript standard library")
       (license "MIT")
       (criticality "high")))

    (dev-dependencies
      ((name "Deno.test")
       (version "built-in")
       (purpose "Native test runner (replaced Vitest)")
       (license "MIT")
       (criticality "high"))

      ((name "@std/assert")
       (version "jsr:@std/assert")
       (purpose "Test assertions (assertEquals, assertExists, etc.)")
       (license "MIT")
       (criticality "high"))))

  (consumers
    (known-users ())
    (potential-users
      ("Neurosymbolic AI research labs")
      ("Agentic application developers")
      ("Human-AI interaction researchers")
      ("Teams building complex AI-assisted workflows")))

  (governance
    (maintainers
      ((name "Jonathan D.A. Jewell")
       (email "jonathan.jewell@open.ac.uk")
       (role "creator")
       (github "hyperpolymath")))

    (contribution-model "open-source")
    (decision-making "BDFL with community input")
    (license "PMPL-1.0-or-later")
    (repository "https://github.com/hyperpolymath/panll"))

  (roadmap-highlights
    ((milestone "v0.2.0")
     (target "Q1 2026")
     (focus "Enhanced UI & functional components"))

    ((milestone "v0.3.0")
     (target "Q2 2026")
     (focus "Neurosymbolic reasoning engine integration"))

    ((milestone "v0.4.0")
     (target "Q3 2026")
     (focus "Multi-agent coordination"))

    ((milestone "v1.0.0")
     (target "Q1 2027")
     (focus "Production-ready, stable API")))

  (metadata
    (tags "neurosymbolic" "htmi" "eNSAID" "binary-star" "human-machine-co-working" "TEA" "rescript" "tauri")
    (keywords "neurosymbolic" "agentic" "human-ai-collaboration" "TEA" "elm-architecture")
    (repository-url "https://github.com/hyperpolymath/panll")
    (documentation-url "https://github.com/hyperpolymath/panll/blob/main/README.adoc")
    (issues-url "https://github.com/hyperpolymath/panll/issues")
    (discussions-url "https://github.com/hyperpolymath/panll/discussions")))
