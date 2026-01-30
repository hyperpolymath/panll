;; SPDX-License-Identifier: PMPL-1.0-or-later
;;
;; PanLL eNSAID - Ecosystem Position

(ecosystem
  (version "1.0")
  (name "panll")
  (type "application")
  (purpose "Environment for NeSy-Agentic Integrated Development")

  (position-in-ecosystem
    (category "developer-tools")
    (subcategory "neurosymbolic-ide")
    (uniqueness "First HTI (Human-Things Interface) that implements
                 Binary Star co-orbit between human operator and
                 neurosymbolic machine agent"))

  (related-projects
    (project "bunsenite"
      (relationship sibling-standard)
      (description "Nickel-based configuration used for Tractatus (Pane-L)
                    constraint definitions"))

    (project "echidnabot"
      (relationship potential-consumer)
      (description "May provide backend for formal verification in
                    Anti-Crash Library"))

    (project "git-hud"
      (relationship sibling-standard)
      (description "Shares STATE.scm format and checkpoint file protocol"))

    (project "rescript-tea"
      (relationship external-dependency)
      (description "TEA implementation for ReScript - may need fork"))

    (project "proven-library"
      (relationship planned-dependency)
      (description "Anti-Crash algorithms and safety protocols"))

    (project "contractiles"
      (relationship planned-extraction)
      (description "Adaptive state contracts - may be extracted as
                    standalone library"))

    (project "tauri"
      (relationship external-dependency)
      (description "Native shell for cross-platform deployment"))

    (project "elm-architecture"
      (relationship inspiration)
      (description "The Elm Architecture pattern that TEA implements")))

  (what-this-is
    "An eNSAID (Environment for NeSy-Agentic Integrated Development)"
    "A Human-Things Interface for neurosymbolic AI co-development"
    "A three-pane IDE with Symbolic, Neural, and World views"
    "A Vexometer-driven adaptive environment"
    "A Binary Star system for human-machine co-orbit")

  (what-this-is-not
    "Not a traditional text editor or IDE"
    "Not a chat interface for LLMs"
    "Not a code completion tool"
    "Not a passive observation window"
    "Not a React/TypeScript application"))
