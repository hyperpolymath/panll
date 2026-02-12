;; SPDX-License-Identifier: PMPL-1.0-or-later
;; META.scm - Architecture decisions and meta-level information for PanLL

(meta
  (version "1.0.0")
  (last-updated "2026-02-12")
  (format-spec "hyperpolymath/rsr-template-repo/spec/META-FORMAT-SPEC.adoc")

  (architecture-decisions
    ((adr-001
      (title "Binary Star Human-Machine Architecture")
      (status "accepted")
      (date "2026-01-15")
      (context
        "Traditional IDEs treat AI as tool or assistant (Human-as-primary, Machine-as-subordinate). "
        "This creates friction when complex tasks require sustained AI autonomy. "
        "Need architecture that enables genuine co-working without subordination.")
      (decision
        "Model Human and Machine as Binary Star system - two gravitationally bound entities "
        "orbiting a shared Barycentre (the task/artifact). Neither is primary. "
        "Three panes: Pane-L (Symbolic/Human), Pane-N (Neural/Machine), Pane-W (World/Barycentre).")
      (consequences
        (positive
          ("Enables sustained co-working without constant context switching")
          ("Operator can see Machine's reasoning stream in real-time (Pane-N)")
          ("Machine constrained by symbolic rules (Pane-L) visible to both parties")
          ("Shared output space (Pane-W) validates mutual understanding"))
        (negative
          ("More complex UI than traditional editor")
          ("Requires both parties to adapt to synchronous co-orbit")
          ("Higher cognitive load initially until workflow internalised")))
      (alternatives-considered
        ("Traditional assistant model - rejected, too asymmetric")
        ("Pair programming UI - rejected, still implies Human-as-driver")
        ("Full automation - rejected, removes Human agency")))

    ((adr-002
      (title "The Elm Architecture (TEA) for State Management")
      (status "accepted")
      (date "2026-01-20")
      (context
        "Binary Star system requires deterministic, auditable state synchronisation. "
        "Complex UI with multiple interacting panes (L/N/W), cognitive load monitoring (Vexometer), "
        "orbital stability tracking, and anti-crash validation. "
        "Need architecture that prevents state corruption and makes reasoning transparent.")
      (decision
        "Use The Elm Architecture (Model-Update-View with Commands and Subscriptions). "
        "Custom TEA implementation for v0.1.0 (migration to official rescript-tea deferred to v0.2.0). "
        "All state changes flow through typed messages, ensuring deterministic updates.")
      (consequences
        (positive
          ("Predictable state transitions - easier to debug")
          ("Time-travel debugging possible")
          ("Pure functions enable comprehensive testing")
          ("Enforced separation of effects (Commands) from state updates")
          ("Official library provides battle-tested runtime"))
        (negative
          ("Steeper learning curve for contributors unfamiliar with TEA")
          ("More boilerplate than imperative state updates")
          ("Custom subscriptions needed for keyboard (not built-in to rescript-tea)")))
      (alternatives-considered
        ("Redux - rejected, too imperative")
        ("React hooks - rejected, not deterministic enough")
        ("Custom state management - rejected, reinventing wheel")))

    ((adr-003
      (title "ReScript for Type-Safe Frontend")
      (status "accepted")
      (date "2026-01-18")
      (context
        "Need type safety for complex state model (constraints, tokens, OODA phases, orbital metrics). "
        "JavaScript/TypeScript too permissive for safety-critical anti-crash validation. "
        "Hyperpolymath policy requires ReScript for frontend.")
      (decision
        "Use ReScript 11.1+ compiling to JavaScript. "
        "Leverages OCaml's type system for compile-time guarantees. "
        "Follows hyperpolymath language policy.")
      (consequences
        (positive
          ("Compile-time type safety eliminates entire classes of bugs")
          ("Pattern matching on variant types models state machines cleanly")
          ("Fast compilation, good error messages")
          ("Compiles to readable JavaScript for debugging")
          ("Policy-compliant"))
        (negative
          ("Smaller ecosystem than TypeScript")
          ("Learning curve for OCaml-style syntax")
          ("Some JavaScript interop friction")))
      (alternatives-considered
        ("TypeScript - rejected, violates hyperpolymath policy")
        ("Elm - rejected, no Tauri integration")
        ("PureScript - rejected, steeper learning curve")))

    ((adr-004
      (title "Tauri 2.0 for Desktop App Framework")
      (status "accepted")
      (date "2026-01-22")
      (context
        "Need cross-platform desktop app (Linux, macOS, Windows). "
        "Require native performance for anti-crash validation and orbital sync. "
        "Hyperpolymath policy favours Rust-based solutions.")
      (decision
        "Use Tauri 2.0 with Rust backend. "
        "Frontend (ReScript/HTML/CSS) runs in webview, backend handles system operations. "
        "Eight Tauri commands: validate_inference, record_vexation_event, get_vexation_index, "
        "submit_feedback, import_panic_attacker_report, import_latest_panic_attacker_report, "
        "get_panic_attacker_capability, run_panic_attack_ambush.")
      (consequences
        (positive
          ("Small binary size (~5-10MB vs 50-100MB for Electron)")
          ("Native performance for validation logic")
          ("Rust memory safety for backend")
          ("Cross-platform with single codebase")
          ("Policy-compliant (Rust backend)"))
        (negative
          ("Smaller community than Electron")
          ("Webview differences across platforms (WebKit/WebView2)")
          ("More complex debugging (frontend + backend)")))
      (alternatives-considered
        ("Electron - rejected, bloated binaries")
        ("Flutter - rejected, not policy-compliant")
        ("Native Qt/GTK - rejected, too much platform-specific code")))

    ((adr-005
      (title "Anti-Crash Library as Circuit Breaker")
      (status "accepted")
      (date "2026-01-25")
      (context
        "Neural inference can generate invalid/unsafe outputs. "
        "Need mechanical enforcement of symbolic constraints before output reaches Barycentre (Pane-W). "
        "Cannot rely on Human Operator to manually validate every token.")
      (decision
        "Implement Anti-Crash Library as circuit breaker between Pane-N and Pane-W. "
        "Every neural token must pass symbolic validation (validate_inference Tauri command). "
        "Failed tokens trigger RequestOperatorIntervention message, not automatic passage.")
      (consequences
        (positive
          ("Prevents unvalidated neural output from corrupting shared workspace")
          ("Makes constraint violations explicit and visible")
          ("Operator intervention only when actually needed")
          ("Auditable validation log"))
        (negative
          ("Adds latency to neural→world pipeline")
          ("Requires well-specified symbolic constraints")
          ("False positives may interrupt flow")))
      (alternatives-considered
        ("Post-hoc validation - rejected, too late to prevent corruption")
        ("Manual approval - rejected, too much cognitive load")
        ("No validation - rejected, unsafe")))

    ((adr-006
      (title "Vexometer for Cognitive Load Monitoring")
      (status "accepted")
      (date "2026-01-28")
      (context
        "Binary Star co-orbit can increase cognitive load (monitoring Machine reasoning, managing constraints). "
        "Need real-time feedback on operator stress to prevent inertia/burnout. "
        "UI should adapt to reduce friction when vexation high.")
      (decision
        "Implement Vexometer tracking cancellations, corrections, and dwell time. "
        "Vexation Index (0.0-1.0) triggers anti-inflammatory UI adjustments. "
        "get_vexation_index Tauri command polls system stress indicators.")
      (consequences
        (positive
          ("Operator receives feedback on stress level")
          ("UI adapts to reduce visual noise when stress high")
          ("Detects inertia (prolonged inaction)")
          ("Prevents burnout by forcing breaks"))
        (negative
          ("More UI complexity")
          ("Risk of false positives (misidentifying stress)")
          ("Requires tuning thresholds per operator")))
      (alternatives-considered
        ("Manual stress reporting - rejected, adds cognitive load")
        ("No monitoring - rejected, ignores ergonomics")
        ("AI-inferred stress - rejected, too invasive")))

    ((adr-007
      (title "Deno + npm Hybrid Build System")
      (status "accepted")
      (date "2026-02-02")
      (context
        "Hyperpolymath policy requires Deno for runtime, but ReScript compiler requires Node.js/npm. "
        "Need build system that uses Deno where possible, npm only for ReScript compilation.")
      (decision
        "Use Deno tasks for Tailwind CSS and Tauri orchestration. "
        "Use npm scripts only for ReScript compilation (res:build, res:watch). "
        "Plan future migration to eliminate npm entirely (pending ReScript Deno support).")
      (consequences
        (positive
          ("Follows hyperpolymath policy (Deno primary)")
          ("Minimal npm surface area")
          ("Clear separation: Deno = orchestration, npm = ReScript only"))
        (negative
          ("Dual package managers increase complexity")
          ("npm dependency remains until ReScript supports Deno")
          ("Contributors need both Deno and Node.js installed")))
      (alternatives-considered
        ("Pure npm - rejected, violates policy")
        ("Pure Deno - rejected, ReScript doesn't support it yet")
        ("Bun - rejected, not policy-compliant"))))

  (development-practices
    (testing-strategy
      "Test-driven development for core logic (Model, Update, Commands, Subscriptions). "
      "Deno.test for 97 JavaScript unit tests; cargo test for 12 Rust backend tests (109 total). "
      "Integration tests for Tauri backend commands. "
      "Manual testing for UI/UX flows.")

    (versioning-scheme
      "Semantic versioning (MAJOR.MINOR.PATCH). "
      "v0.x.y indicates pre-1.0 (breaking changes allowed). "
      "v1.0.0+ follows strict semver (breaking changes bump MAJOR).")

    (documentation-approach
      "Code documentation via ReScript doc comments. "
      "Architecture documentation in docs/ (ADRs, guides). "
      "Migration guides for breaking changes. "
      "README.adoc for quickstart, ROADMAP.adoc for planning.")

    (code-review-process
      "All changes via pull requests. "
      "CI/CD runs tests, linters, formatters. "
      "At least one approval required for merge. "
      "No force-pushes to main.")

    (license-policy
      "All original code PMPL-1.0-or-later (Palimpsest License). "
      "Third-party dependencies respect original licenses. "
      "SPDX headers in all source files."))

  (design-rationale
    (three-pane-layout
      "Parallel layout (L/N/W side-by-side) emphasises simultaneity. "
      "Pane-L (left) = Symbolic, Pane-N (middle) = Neural, Pane-W (right) = World. "
      "Layout inspired by music production DAWs (multiple simultaneous views).")

    (binary-star-metaphor
      "Metaphor from astrophysics: two stars orbiting shared centre of mass. "
      "Human = symbolic star (constraints, logic), Machine = neural star (inference, learning). "
      "Barycentre = task/artifact, gravitational force = shared goal. "
      "Orbital stability sigma = measure of synchronicity.")

    (keyboard-first-interaction
      "Keyboard shortcuts for pane toggles (Ctrl+Shift+L/N/W). "
      "Minimises mouse dependency for expert users. "
      "Allows rapid context switching without disrupting flow.")

    (information-humidity
      "Concept: UI detail density adapts to operator stress level. "
      "High humidity (low stress) = show more detail, tooltips, hints. "
      "Low humidity (high stress) = shed visual noise, essential info only. "
      "Inspired by responsive design, but driven by cognitive load not screen size.")

    (feedback-o-tron-community
      "Collective feedback pool for performance bottlenecks and constraint suggestions. "
      "Operator submits snapshots (Pane-L + Pane-N + Pane-W state). "
      "Community analyses patterns, proposes constraint refinements. "
      "Inspired by issue trackers but for cognitive ergonomics.")

    (dark-start-mode
      "Startup mode: Binary Star topology diagram on Pane-W, other panes empty. "
      "Operator-initiated activation (first keypress/mouse click). "
      "Reduces startup anxiety, emphasises intentionality."))

  (cross-cutting-concerns
    (security
      "Tauri enforces CSP (Content Security Policy) for webview. "
      "Validate all Tauri command inputs (prevent injection). "
      "No eval() or unsafe JavaScript. "
      "Future: Echidna-based formal verification for Anti-Crash logic.")

    (performance
      "ReScript compiles to optimised JavaScript. "
      "Tauri Rust backend for CPU-intensive tasks (validation). "
      "Virtual DOM diffing for efficient UI updates. "
      "Lazy-load components when possible.")

    (accessibility
      "Comprehensive ARIA attributes across all components (role, ariaLabel, ariaPressed, "
      "ariaCurrent, ariaValueNow/Min/Max, ariaDescribedBy, ariaLive, ariaExpanded, ariaHidden). "
      "Keyboard navigation for all features (Ctrl+Shift+L/N/B/W). "
      "High-contrast mode support. "
      "Screen reader compatibility (future).")

    (internationalisation
      "English-only for v0.x (alpha/beta). "
      "i18n framework planned for v1.0. "
      "Right-to-left language support (future).")))
