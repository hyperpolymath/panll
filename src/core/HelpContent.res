// SPDX-License-Identifier: PMPL-1.0-or-later

/// HelpContent — Static help content data for the PanLL help system.
///
/// This module provides all the help entries and glossary terms that
/// populate the help panel. Content is organised by category and
/// optionally linked to specific panels via panelId references.
///
/// The module is pure data — no logic, no side effects. Functions
/// return fresh arrays of content records on each call, ensuring
/// immutability and preventing accidental mutation of shared state.
///
/// Content covers five categories:
/// - GettingStarted: orientation and first steps
/// - PanelGuide: one entry per major panel/tool
/// - Shortcuts: keyboard shortcut reference
/// - FAQ: common questions and troubleshooting
/// - Architecture: system design and neurosymbolic concepts
///
/// The glossary provides accessible definitions for all neurosymbolic
/// terminology used throughout PanLL, making the interface learnable
/// even for users unfamiliar with formal methods or neural-symbolic AI.

/// Returns all help entries for the PanLL help system.
///
/// Each entry has a unique string ID, a human-readable title, a body
/// of explanatory text, a category for filtering, an optional panelId
/// for contextual scoping, and an array of keyword strings for search.
///
/// Entries are returned in a logical reading order within each category:
/// GettingStarted first, then PanelGuide, Shortcuts, FAQ, Architecture.
///
/// @returns The complete array of help entries
let allEntries = (): array<HelpModel.helpEntry> => {
  [
    // =========================================================================
    // Getting Started
    // =========================================================================

    /// Welcome entry — the first thing a new user should read.
    {
      id: "welcome",
      title: "Welcome to PanLL",
      body: "PanLL (formally eNSAID: Environment for NeSy-Agentic Integrated Development) is a neurosymbolic mission control interface. It combines symbolic reasoning (formal proofs, type systems, constraints) with neural computation (language models, learned heuristics) in a unified three-panel workspace. PanLL is designed for accessibility-first interaction, putting the operator in control of both symbolic and neural subsystems at all times.",
      category: GettingStarted,
      panelId: None,
      keywords: ["welcome", "introduction", "ensaid", "neurosymbolic", "mission control", "getting started"],
    },
    /// Explains the fundamental three-panel layout.
    {
      id: "three-panel-layout",
      title: "Understanding the Three-Panel Layout",
      body: "PanLL organises work into three panels. Panel-L (left) displays constraints, formal structure, and symbolic state — it is where you define what must be true. Panel-N (centre) hosts agent reasoning, OODA loops, and decision-making processes — it is where thinking happens. Panel-W (right) shows results, output, and verification status — it is where you see outcomes. This left-to-right flow mirrors the progression from specification through reasoning to results.",
      category: GettingStarted,
      panelId: None,
      keywords: ["panels", "layout", "three-panel", "panel-l", "panel-n", "panel-w", "workspace"],
    },
    /// How to use the panel switcher to navigate between tools.
    {
      id: "panel-switcher",
      title: "Navigating with the Panel Switcher",
      body: "The panel switcher is the primary navigation mechanism in PanLL. It appears as a bar or sidebar listing all available panels grouped by clade (taxonomic function). Click or use keyboard shortcuts to switch the active panel. Each panel represents a different tool or view — from theorem proving to database simulation to security scanning. The switcher also shows panel status indicators so you can see at a glance which panels need attention.",
      category: GettingStarted,
      panelId: None,
      keywords: ["navigation", "switcher", "panel switcher", "clade", "tabs"],
    },
    /// The Dark Start splash screen and how to transition to standard mode.
    {
      id: "dark-start",
      title: "Dark Start and Standard Mode",
      body: "When PanLL launches, it shows the Dark Start screen — a brief animated splash displaying the Binary Star architecture. This is not just decorative: it runs startup diagnostics and establishes connections to backend services (ECHIDNA, TypeLL, VeriSimDB). Once initialisation completes, PanLL transitions to Standard Mode where all panels become interactive. If Dark Start stalls, check your backend service connections.",
      category: GettingStarted,
      panelId: None,
      keywords: ["dark start", "splash", "startup", "boot", "initialisation", "standard mode"],
    },

    // =========================================================================
    // Panel Guides
    // =========================================================================

    /// Guide for the ECHIDNA theorem prover panel.
    {
      id: "panel-echidna",
      title: "ECHIDNA — Theorem Prover",
      body: "The ECHIDNA panel connects to the ECHIDNA theorem prover backend for formal verification. Use it to submit proof obligations, inspect proof states, and track verification progress. ECHIDNA handles dependent types, refinement types, and constructive proofs. The panel shows proof trees, goal states, and tactic suggestions. Proof results feed into the provenance system, raising the trust level of verified code to 'Verified'.",
      category: PanelGuide,
      panelId: Some(PanelSwitcherModel.PanelDatabases),
      keywords: ["echidna", "theorem prover", "formal verification", "proofs", "dependent types", "tactics"],
    },
    /// Guide for the TypeLL verification kernel panel.
    {
      id: "panel-typell",
      title: "TypeLL — Verification Kernel",
      body: "TypeLL is PanLL's type checking and inference engine. It operates as a verification kernel that checks code against type-level specifications. The TypeLL panel shows type errors, inferred types, and refinement constraints in real time. It integrates with ECHIDNA for proofs that go beyond what the type system alone can verify. Use TypeLL to ensure your code satisfies its contracts before committing.",
      category: PanelGuide,
      panelId: Some(PanelSwitcherModel.PanelTypeLL),
      keywords: ["typell", "type checking", "type inference", "verification", "kernel", "contracts"],
    },
    /// Guide for the VeriSimDB simulation database panel.
    {
      id: "panel-verisimdb",
      title: "VeriSimDB — Simulation Database",
      body: "VeriSimDB is a verification-aware simulation database. It stores simulation runs, test results, and verification outcomes with full provenance tracking. The VeriSimDB panel lets you query past simulations, compare runs, and inspect how changes affected verification status over time. It serves as the persistent memory of your verification workflow, ensuring no proof or test result is ever lost.",
      category: PanelGuide,
      panelId: Some(PanelSwitcherModel.PanelDatabases),
      keywords: ["verisimdb", "database", "simulation", "test results", "provenance", "history"],
    },
    /// Guide for the Farm panel (repo management).
    {
      id: "panel-farm",
      title: "Farm — Repository Management",
      body: "The Farm panel manages your repository fleet. It shows the status of all repos registered in the git-private-farm manifest, including mirror sync status (GitHub, GitLab, Bitbucket), CI/CD pipeline results, and RSR compliance scores. Use Farm to bulk-manage repos, trigger mirror syncs, and identify repos that need attention. The Farm integrates with gitbot-fleet for automated maintenance.",
      category: PanelGuide,
      panelId: Some(PanelSwitcherModel.PanelFarm),
      keywords: ["farm", "repositories", "git", "mirrors", "gitlab", "bitbucket", "rsr"],
    },
    /// Guide for the Fleet panel (bot orchestration).
    {
      id: "panel-fleet",
      title: "Fleet — Bot Orchestration",
      body: "The Fleet panel provides visibility into the gitbot-fleet — the collection of automated bots that maintain your repositories. Bots include rhodibot (RSR compliance), echidnabot (formal verification flagging), sustainabot (dependency updates), glambot (documentation), seambot (integration testing), and finishbot (completion tracking). The Fleet panel shows bot activity, queued tasks, and confidence thresholds for automated fixes.",
      category: PanelGuide,
      panelId: Some(PanelSwitcherModel.PanelFleet),
      keywords: ["fleet", "bots", "gitbot", "rhodibot", "echidnabot", "sustainabot", "automation"],
    },
    /// Guide for the Hypatia security scanning panel.
    {
      id: "panel-hypatia",
      title: "Hypatia — Security Intelligence",
      body: "Hypatia is the neurosymbolic security scanning system. The Hypatia panel shows scan results, vulnerability findings, and security posture across your repositories. Hypatia goes beyond traditional SAST/DAST by combining symbolic analysis (formal reasoning about code properties) with neural pattern recognition (learned vulnerability signatures). Findings are ranked by severity and include remediation suggestions.",
      category: PanelGuide,
      panelId: Some(PanelSwitcherModel.PanelHypatia),
      keywords: ["hypatia", "security", "scanning", "vulnerabilities", "sast", "neurosymbolic security"],
    },
    /// Guide for the Aerie network analysis panel.
    {
      id: "panel-aerie",
      title: "Aerie — Network Analysis",
      body: "The Aerie panel provides network analysis and simulation capabilities. It visualises network topologies, analyses BGP routing, and monitors IPv6 connectivity. Aerie integrates with the proven cryptographic library for protocol verification. Use Aerie to simulate network changes before deploying them, verify routing policies, and monitor the health of distributed systems.",
      category: PanelGuide,
      panelId: Some(PanelSwitcherModel.PanelAerie),
      keywords: ["aerie", "network", "bgp", "ipv6", "routing", "topology", "simulation"],
    },
    /// Guide for the Playgrounds panel (experimental code execution).
    {
      id: "panel-playgrounds",
      title: "Playgrounds — Experimental Execution",
      body: "The Playgrounds panel provides sandboxed environments for experimental code execution. Run ReScript, Rust, Gleam, or Elixir snippets in isolated containers with full type checking and verification. Playground results can be saved to VeriSimDB for later reference. Use Playgrounds to prototype ideas, test hypotheses, and explore APIs without affecting your main codebase.",
      category: PanelGuide,
      panelId: Some(PanelSwitcherModel.PanelPlaygrounds),
      keywords: ["playgrounds", "sandbox", "experimental", "repl", "execution", "prototype"],
    },
    /// Guide for the Security panel (trust and provenance).
    {
      id: "panel-security",
      title: "Security — Trust and Provenance",
      body: "The Security panel displays the provenance and trust surface of your codebase. It shows who wrote each piece of code, how it was reviewed, and what trust level it carries (Verified, Human Reviewed, AI Assisted, Unreviewed AI, Unknown). The Hostile UX system applies deliberate friction to unreviewed AI code, demanding explicit human review before it can be deployed. The Security panel also shows contractile enforcement status.",
      category: PanelGuide,
      panelId: Some(PanelSwitcherModel.PanelSecurity),
      keywords: ["security", "provenance", "trust", "hostile ux", "code review", "contractiles"],
    },
    /// Guide for the Workspace panel (project overview).
    {
      id: "panel-workspace",
      title: "Workspace — Project Overview",
      body: "The Workspace panel gives you a high-level view of the current project state. It shows task progress, milestone tracking, blocker status, and the overall completion dashboard. The workspace integrates data from all other panels — verification status from ECHIDNA, test results from VeriSimDB, security findings from Hypatia — into a unified project health summary. The Task Barycentre indicator shows where the current work sits on the symbolic-neural spectrum.",
      category: PanelGuide,
      panelId: Some(PanelSwitcherModel.PanelWorkspace),
      keywords: ["workspace", "project", "overview", "tasks", "milestones", "dashboard", "barycentre"],
    },

    // =========================================================================
    // Shortcuts
    // =========================================================================

    /// Comprehensive keyboard shortcut reference.
    {
      id: "keyboard-shortcuts",
      title: "Keyboard Shortcuts Reference",
      body: "PanLL supports extensive keyboard navigation. Global shortcuts: Ctrl+/ (toggle help), Ctrl+K (command palette), Escape (close active overlay). Panel navigation: Ctrl+1 through Ctrl+9 (switch to panel by position), Ctrl+[ and Ctrl+] (previous/next panel). Within panels: Tab (cycle focus), Enter (activate), Arrow keys (navigate lists). The panel switcher responds to type-ahead filtering — just start typing a panel name. All shortcuts are customisable in Settings.",
      category: Shortcuts,
      panelId: None,
      keywords: ["keyboard", "shortcuts", "hotkeys", "keybindings", "accessibility", "navigation", "ctrl"],
    },

    // =========================================================================
    // FAQ
    // =========================================================================

    /// Troubleshooting ECHIDNA connection issues.
    {
      id: "faq-echidna-connection",
      title: "Why can't I connect to ECHIDNA?",
      body: "ECHIDNA runs as a separate backend service. If the connection fails: (1) Check that the ECHIDNA service is running — it should be accessible on its configured port. (2) Verify the connection URL in PanLL settings matches your ECHIDNA deployment. (3) Check your network/firewall rules. (4) Look at the Dark Start diagnostic output for connection errors. (5) If using a containerised ECHIDNA, ensure the container is healthy with `podman ps`. The ECHIDNA panel status indicator will show red when disconnected.",
      category: Faq,
      panelId: Some(PanelSwitcherModel.PanelDatabases),
      keywords: ["echidna", "connection", "error", "troubleshooting", "backend", "service"],
    },
    /// Explains the provenance bar and trust levels.
    {
      id: "faq-provenance-bar",
      title: "What does the Provenance bar show?",
      body: "The Provenance bar is a horizontal stacked bar chart showing the trust composition of your codebase. Each segment represents a trust level: green for Verified (formally proven), blue for Human Reviewed, yellow for AI Assisted (human-reviewed AI code), orange for Unreviewed AI (needs review), and grey for Unknown. The bar updates in real time as code is verified, reviewed, or added. Click any segment to drill down into the specific files at that trust level. The goal is to minimise orange and grey segments.",
      category: Faq,
      panelId: Some(PanelSwitcherModel.PanelSecurity),
      keywords: ["provenance", "bar", "trust level", "verified", "human reviewed", "ai assisted", "unreviewed"],
    },
    /// How to change the PanLL colour palette.
    {
      id: "faq-colour-palettes",
      title: "How do I switch colour palettes?",
      body: "PanLL supports multiple colour palettes for accessibility and preference. Open Settings (gear icon or Ctrl+,) and navigate to the Appearance section. Available palettes include the default neurosymbolic theme (dark with drift aura), a high-contrast mode for maximum readability, and several colour-blind-safe palettes (deuteranopia, protanopia, tritanopia). Each palette adjusts the drift aura colours, panel borders, and syntax highlighting to remain distinguishable. Changes apply immediately — no restart needed.",
      category: Faq,
      panelId: None,
      keywords: ["colour", "color", "palette", "theme", "accessibility", "appearance", "settings", "contrast"],
    },

    // =========================================================================
    // Architecture
    // =========================================================================

    /// The Binary Star architectural model.
    {
      id: "arch-binary-star",
      title: "Binary Star Architecture",
      body: "PanLL's core architecture models the relationship between symbolic and neural computation as a binary star system. Neither subsystem is primary — they co-orbit a shared barycentre, each influencing the other through gravitational coupling. The symbolic star provides formal guarantees (proofs, types, contracts). The neural star provides learned heuristics (pattern recognition, natural language understanding, probabilistic reasoning). Orbital stability measures how well these subsystems stay in sync. When they drift apart, the Drift Aura shifts colour to alert the operator.",
      category: Architecture,
      panelId: None,
      keywords: ["binary star", "architecture", "symbolic", "neural", "co-orbital", "barycentre", "drift"],
    },
    /// How the TEA update loop drives the PanLL UI.
    {
      id: "arch-tea-loop",
      title: "TEA Update Loop",
      body: "PanLL's UI is driven by The Elm Architecture (TEA): a unidirectional data flow where the entire application state is a single immutable value. Every user action produces a message (Msg), which is processed by an update function to produce a new state and optional side-effect commands (Cmd). The view function renders the state to virtual DOM, and the runtime diffs and patches the real DOM. This architecture guarantees predictable state transitions, makes time-travel debugging possible, and eliminates an entire class of UI bugs related to shared mutable state.",
      category: Architecture,
      panelId: None,
      keywords: ["tea", "elm architecture", "update loop", "unidirectional", "state", "msg", "cmd", "view"],
    },
    /// How symbolic and neural systems integrate in PanLL.
    {
      id: "arch-neurosymbolic",
      title: "Neurosymbolic Integration",
      body: "PanLL integrates symbolic and neural computation at multiple levels. At the data level, VeriSimDB stores both formal proofs and neural predictions with unified provenance. At the reasoning level, ECHIDNA proofs can constrain neural outputs, and neural heuristics can guide proof search. At the UI level, the three-panel layout makes the symbolic-neural interaction visible and controllable. The Task Barycentre shows where each task sits on the spectrum. Contractiles enforce boundaries — for example, requiring that neural suggestions pass type checking before being presented to the operator.",
      category: Architecture,
      panelId: None,
      keywords: ["neurosymbolic", "integration", "symbolic", "neural", "barycentre", "contractiles", "proofs"],
    },
  ]
}

/// Returns the complete glossary of neurosymbolic terms used in PanLL.
///
/// Each glossary term has a human-readable name and an accessible
/// definition written for users who may not have a background in
/// formal methods or neural-symbolic AI. Definitions explain both
/// what the term means and how it manifests in the PanLL interface.
///
/// Terms are returned in a logical grouping order: core architectural
/// concepts first, then UI concepts, then specific subsystem names.
///
/// @returns The complete array of glossary terms
let allGlossaryTerms = (): array<HelpModel.glossaryTerm> => {
  [
    /// The centre of gravity of a task on the symbolic-neural spectrum.
    {
      term: "Task Barycentre",
      definition: "The centre of gravity of a task on the symbolic-neural spectrum. A task with high symbolic mass (many proofs, strict types) has its barycentre closer to the symbolic side. A task relying heavily on neural heuristics (ML inference, pattern matching) shifts toward the neural side. PanLL displays the barycentre as a position indicator, helping operators understand the nature of their current work and allocate attention accordingly.",
      relatedTerms: [],
      extendedDescription: None,
    },
    /// The weight of formal structure in a computation.
    {
      term: "Symbolic Mass",
      definition: "The weight or density of formal structure in a computation — proofs, type constraints, contractiles, invariants, and specifications. High symbolic mass means the task is heavily constrained by formal reasoning. In PanLL, symbolic mass contributes to the Task Barycentre calculation and influences how much formal verification overhead a task carries. Increasing symbolic mass generally increases trust but also increases the cost of change.",
      relatedTerms: [],
      extendedDescription: None,
    },
    /// The flow of statistical and learned computation.
    {
      term: "Neural Stream",
      definition: "The flow of statistical, learned, and probabilistic computation through the system. Neural streams carry predictions, generated text, pattern matches, and heuristic suggestions. In PanLL, neural streams are always visible and auditable — they flow through Panel-N where the operator can inspect, redirect, or halt them. Neural stream output that has not been formally verified carries a lower trust level.",
      relatedTerms: [],
      extendedDescription: None,
    },
    /// PanLL's co-orbital architecture model.
    {
      term: "Binary Star",
      definition: "PanLL's co-orbital architecture model where the symbolic subsystem and neural subsystem orbit each other like a gravitationally bound binary star. Neither is primary — they exert mutual influence. The symbolic star provides rigour and guarantees; the neural star provides flexibility and learning. The system's health depends on orbital stability: if the two drift too far apart, reasoning becomes unreliable. The Drift Aura visualises this relationship.",
      relatedTerms: [],
      extendedDescription: None,
    },
    /// The agent reasoning cycle.
    {
      term: "OODA Loop",
      definition: "Observe-Orient-Decide-Act: a decision cycle used for agent reasoning in PanLL. Agents observe the current state (panel data, verification results), orient by analysing context (symbolic constraints, neural predictions), decide on an action (suggest a fix, request a proof), and act (execute the decision). PanLL makes OODA loops visible in Panel-N so operators can inspect agent reasoning at each stage and intervene if needed.",
      relatedTerms: [],
      extendedDescription: None,
    },
    /// An elastic constraint with enforcement levels.
    {
      term: "Contractile",
      definition: "An elastic constraint that can be enforced at different levels: Strict (hard failure on violation), Adaptive (warning with escalation), or Warn (informational only). Contractiles define boundaries for code quality, security, and correctness. For example, a contractile might require that all public functions have type annotations (Strict) or that neural suggestions are reviewed within 24 hours (Adaptive). Contractiles are defined in Trustfile.a2ml and enforced by the security system.",
      relatedTerms: [],
      extendedDescription: None,
    },
    /// A measure of operator frustration.
    {
      term: "Vexation Index",
      definition: "A measure of operator frustration and friction in the interface. PanLL tracks interaction patterns (rapid undo sequences, repeated failed commands, dismissed suggestions) to estimate vexation. High vexation triggers adaptive UI responses: simplifying the interface, offering guided help, or reducing notification frequency. The vexation index is part of PanLL's accessibility-first design philosophy — the tool should reduce cognitive load, not add to it.",
      relatedTerms: [],
      extendedDescription: None,
    },
    /// How well the symbolic and neural subsystems stay in sync.
    {
      term: "Orbital Stability",
      definition: "A measure of how well the symbolic and neural subsystems remain in synchronisation. High stability means proofs align with neural predictions, types match inferred behaviour, and formal specifications agree with learned models. Low stability indicates drift — the two subsystems are producing contradictory results. PanLL computes orbital stability continuously and displays it via the Drift Aura. Operators should investigate when stability drops below threshold.",
      relatedTerms: [],
      extendedDescription: None,
    },
    /// The visual indicator of orbital stability.
    {
      term: "Drift Aura",
      definition: "A visual indicator of orbital stability rendered as a subtle background colour shift across the PanLL interface. When symbolic and neural subsystems are well-synchronised, the aura is calm and neutral. As drift increases, the aura shifts colour — typically toward warmer tones — alerting the operator that the Binary Star system needs attention. The aura's opacity is affected by the Humidity parameter. It is designed to be noticeable without being distracting.",
      relatedTerms: [],
      extendedDescription: None,
    },
    /// Deliberate friction for unreviewed AI code.
    {
      term: "Hostile UX",
      definition: "A deliberate design pattern where PanLL applies friction to unreviewed AI-generated code. Rather than letting AI output flow smoothly into the codebase, Hostile UX demands explicit human review by making unreviewed code visually distinct (orange provenance highlighting), requiring additional confirmation steps, and blocking automated deployment. This is not a bug — it is a safety feature that ensures human oversight of AI contributions.",
      relatedTerms: [],
      extendedDescription: None,
    },
    /// The code trust surface.
    {
      term: "Provenance",
      definition: "The trust surface of code showing who wrote it, how it was generated, and how much review it has received. PanLL tracks provenance at the function level, recording whether code was hand-written by a verified human, generated by AI with human review, generated by AI without review, or of unknown origin. Provenance data feeds into the Security panel's trust bar and the Hostile UX system. Higher provenance means higher deployment confidence.",
      relatedTerms: [],
      extendedDescription: None,
    },
    /// Classification of code authorship.
    {
      term: "Trust Level",
      definition: "A classification of code authorship and review status. Five levels exist: Verified (formally proven correct), Human Reviewed (read and approved by a human), AI Assisted (AI-generated but human-reviewed), Unreviewed AI (AI-generated, not yet reviewed — triggers Hostile UX), and Unknown (no provenance data available). Trust levels are displayed in the provenance bar and determine what automated actions are permitted on the code.",
      relatedTerms: [],
      extendedDescription: None,
    },
    /// The cognitive governance system.
    {
      term: "Anti-Crash",
      definition: "A cognitive governance system built into PanLL that halts operations when safety violations are detected. Anti-Crash monitors for conditions like unchecked believe_me in proofs, deployment of unreviewed AI code, contractile violations above threshold, and orbital stability collapse. When triggered, Anti-Crash pauses the pipeline and requires explicit operator acknowledgement before proceeding. It is the last line of defence against automated systems running off the rails.",
      relatedTerms: [],
      extendedDescription: None,
    },
    /// PanLL's initial splash screen.
    {
      term: "Dark Start",
      definition: "PanLL's initial splash screen displayed during startup. Dark Start shows an animated visualisation of the Binary Star architecture while running backend diagnostics — checking connections to ECHIDNA, TypeLL, VeriSimDB, and other services. It provides visual feedback on initialisation progress. Once all systems are online, Dark Start fades into Standard Mode. A stalled Dark Start usually indicates a backend connectivity issue.",
      relatedTerms: [],
      extendedDescription: None,
    },
    /// Environmental parameter affecting drift aura.
    {
      term: "Humidity",
      definition: "An environmental parameter that affects the opacity and visual prominence of the Drift Aura. Higher humidity makes the aura more visible; lower humidity makes it more subtle. Operators can adjust humidity in settings to match their preference — some prefer a clearly visible aura for constant awareness, while others prefer a faint one that only becomes noticeable during significant drift events. Humidity has no effect on the underlying orbital stability calculation.",
      relatedTerms: [],
      extendedDescription: None,
    },
    /// Taxonomic grouping of panels by function.
    {
      term: "Clade",
      definition: "A taxonomic grouping of panels by function. PanLL organises its panels into clades: AI (neural reasoning panels), Bridge (integration and communication panels), Builder (development and construction panels), Verifier (formal verification panels), Monitor (observability panels), and others. Clades appear in the panel switcher as visual groupings, making it easier to find the right panel. The term is borrowed from biology, where a clade is a group sharing a common ancestor.",
      relatedTerms: [],
      extendedDescription: None,
    },
    /// The theorem prover backend.
    {
      term: "ECHIDNA",
      definition: "The theorem prover backend used by PanLL for formal verification. ECHIDNA handles dependent types, refinement types, and constructive proofs. It runs as a separate service that PanLL connects to via its protocol. ECHIDNA proof results are stored in VeriSimDB and reflected in the provenance system. The name references the echidna — a creature that, like formal proofs, is spiny, resilient, and hard to argue with.",
      relatedTerms: [],
      extendedDescription: None,
    },
    /// The verification kernel.
    {
      term: "TypeLL",
      definition: "PanLL's verification kernel for type checking and type inference. TypeLL operates as a lightweight, fast type checker that runs continuously as code is edited, providing immediate feedback on type errors and inferred types. For properties that go beyond what the type system can express, TypeLL delegates to ECHIDNA for full theorem proving. TypeLL is the first line of formal verification — fast and always-on.",
      relatedTerms: [],
      extendedDescription: None,
    },
    /// The verification-aware simulation database.
    {
      term: "VeriSimDB",
      definition: "A verification-aware simulation database that stores test results, proof outcomes, simulation runs, and their provenance metadata. VeriSimDB is not just a data store — it understands the verification status of its contents and can answer queries like 'show me all functions whose proofs were invalidated by the last commit'. It serves as the persistent memory layer for the entire PanLL verification pipeline.",
      relatedTerms: [],
      extendedDescription: None,
    },
    /// The combination of neural and symbolic reasoning.
    {
      term: "Neurosymbolic",
      definition: "An approach to artificial intelligence that combines neural networks (statistical learning from data) with symbolic reasoning (logical inference over structured representations). PanLL is a neurosymbolic system because it uses both: neural models for language understanding, code generation, and pattern recognition alongside symbolic systems for theorem proving, type checking, and formal verification. The Binary Star architecture makes this combination explicit and controllable.",
      relatedTerms: [],
      extendedDescription: None,
    },
    /// PanLL's full formal name.
    {
      term: "eNSAID",
      definition: "Environment for NeSy-Agentic Integrated Development — the full formal name for PanLL. 'NeSy' stands for Neural-Symbolic, reflecting the neurosymbolic architecture. 'Agentic' refers to the autonomous agent reasoning capabilities (OODA loops, gitbot-fleet). 'Integrated Development' indicates that PanLL is a complete development environment, not just a viewer or monitor. In practice, everyone just calls it PanLL.",
      relatedTerms: [],
      extendedDescription: None,
    },
  ]
}
