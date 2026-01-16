;; SPDX-License-Identifier: AGPL-3.0-or-later
;;
;; PanLL eNSAID - Project State
;; Last Updated: 2026-01-16

(state
  (metadata
    (version "0.0.1")
    (schema-version "1.0")
    (created "2026-01-16")
    (updated "2026-01-16")
    (project "panll")
    (repo "https://github.com/hyperpolymath/panll"))

  (project-context
    (name "PanLL eNSAID")
    (tagline "Environment for NeSy-Agentic Integrated Development")
    (tech-stack
      (frontend "ReScript" "rescript-tea" "Tailwind CSS")
      (backend "Rust" "Tauri 2.0")
      (runtime "Deno")
      (middleware "Elixir/BEAM" "planned")))

  (current-position
    (phase "scaffolding")
    (overall-completion 15)
    (components
      (tea-architecture 80 "Model, Msg, Update, View, App created")
      (pane-components 70 "PaneL, PaneN, PaneW, Vexometer, FeedbackOTron created")
      (core-modules 60 "AntiCrash, Contractiles, OrbitalSync created")
      (tauri-backend 40 "Basic commands, needs Echidna integration")
      (styling 50 "Tailwind configured, base CSS ready")
      (elixir-middleware 0 "Not started"))
    (working-features
      "Three-pane layout structure"
      "TEA state management model"
      "Anti-Crash validation framework"
      "Vexometer metrics structure"
      "Feedback-O-Tron modal structure"))

  (route-to-mvp
    (milestone "v0.0.1" "TEA-Base (MVE)"
      (items
        (item "Complete rescript-tea integration" pending)
        (item "Wire up keyboard shortcuts (Ctrl+Shift+L/N/B)" pending)
        (item "Implement Dark Start view mode" done)
        (item "Basic Tauri shell working" pending)
        (item "Tailwind CSS build pipeline" pending)))

    (milestone "v0.1.0" "Symbolic Synchroniser"
      (items
        (item "Elixir/BEAM state management" pending)
        (item "Echidna integration for Anti-Crash" pending)
        (item "Contractiles enforcement" pending)
        (item "OODA loop visibility in Pane-N" pending)
        (item "Vexometer real-time tracking" pending)))

    (milestone "v1.0.0" "Bionic Standard (GA)"
      (items
        (item "V-lang acceleration paths" pending)
        (item "Full Anti-Crash Library" pending)
        (item "Information Humidity system" pending)
        (item "Orbital Drift Aura rendering" pending))))

  (blockers-and-issues
    (critical)
    (high
      (issue "rescript-tea package may need custom fork or bindings"))
    (medium
      (issue "Echidna solver integration undefined")
      (issue "V-lang acceleration path unclear"))
    (low
      (issue "Need to define Feedback-O-Tron backend API")))

  (critical-next-actions
    (immediate
      "Test ReScript compilation"
      "Verify Tauri build")
    (this-week
      "Wire up basic TEA message flow"
      "Implement pane toggle shortcuts")
    (this-month
      "Research Echidna integration options"
      "Design Elixir middleware architecture"))

  (session-history
    (session "2026-01-16"
      (accomplishments
        "Initial scaffold created"
        "TEA architecture files (Model, Msg, Update, View, App)"
        "Component files (PaneL, PaneN, PaneW, Vexometer, FeedbackOTron)"
        "Core modules (AntiCrash, Contractiles, OrbitalSync)"
        "Tauri backend with basic commands"
        "Tailwind config and base CSS"))))
