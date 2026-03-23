; SPDX-License-Identifier: PMPL-1.0-or-later
; ECOSYSTEM.scm — Ecosystem position for PanLL
; Last updated: 2026-03-23

(ecosystem
  (version "1.3.0")
  (name "panll")
  (full-name "PanLL eNSAID")
  (type "application")
  (category "neurosymbolic-tools")
  (maturity "alpha")

  (purpose
    "Human-Things Interface (HTI) for genuine co-working between Human Operators
     and Neurosymbolic Machines. Binary Star architecture with three-panel layout
     (Symbolic/Neural/World), Anti-Crash validation, Vexometer cognitive load
     monitoring, and Gossamer (Zig + WebKitGTK) desktop runtime.")

  (position-in-ecosystem
    (domain "neurosymbolic-tooling")
    (role "development-environment")
    (scope "Human-Machine co-working for NeSy-Agentic tasks")
    (unique-value "First IDE treating AI as equal co-worker (Binary Star) rather than subordinate tool."))

  (related-projects
    (panic-attack
      (relationship "producer")
      (nature "Exports ambush event-chain timelines for PanLL ingestion and visualisation")
      (integration-status "active"))

    (typell
      (relationship "core-dependency")
      (criticality "load-bearing")
      (nature "Unified type verification kernel — Robinson unification, bidirectional inference,
               QTT linear/affine tracking, algebraic effects, session types, dependent types.")
      (integration-status "active"))

    (boj-server
      (relationship "primary-backend-gateway")
      (nature "18 cartridges as MCP-compatible backend services")
      (integration-status "active"))

    (verisimdb
      (relationship "primary-backend-module")
      (nature "8-modality versioned database. VQL-DT maps to three-panel layout.")
      (integration-status "active"))

    (echidna
      (relationship "primary-prover-backend")
      (nature "Multi-solver theorem prover dispatch — PanLL's primary proof backend")
      (integration-status "active"))

    (hypatia
      (relationship "potential-consumer")
      (nature "Neurosymbolic CI/CD could use PanLL UI for visualising build reasoning chains")
      (integration-status "future"))

    (idaptik
      (relationship "game-development-module")
      (nature "PanLL as development environment for IDApTIK game. 11 eNSAID panels.")
      (integration-status "active"))

    (gossamer
      (relationship "runtime-shell")
      (nature "Zig + WebKitGTK webview shell — replaced Tauri 2.0 as desktop runtime")
      (integration-status "active"))

    (gitbot-fleet
      (relationship "automation-orchestration-module")
      (nature "PanLL as command center for gitbot-fleet bots")
      (integration-status "partial")))

  (dependencies
    (runtime
      (deno (version "1.x") (purpose "Build orchestration, Tailwind CSS") (license "MIT"))
      (gossamer (version "0.1.0") (purpose "Desktop webview shell") (license "PMPL-1.0-or-later")))
    (build-time
      (rescript (version "11.1.4") (purpose "Type-safe frontend compilation") (license "MIT"))
      (tailwind (version "4.1.18") (purpose "Styling framework") (license "MIT")))
    (libraries
      (custom-tea (version "internal") (purpose "Custom TEA — 18 modules, VDOM diffing, ARIA")
                  (license "PMPL-1.0-or-later") (note "Permanent. rescript-tea rejected."))))

  (governance
    (maintainer "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>")
    (maintainer-github "hyperpolymath")
    (contribution-model "open-source")
    (license "PMPL-1.0-or-later")))
