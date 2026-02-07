;; SPDX-License-Identifier: PMPL-1.0-or-later
;; AGENTIC.scm - AI agent interaction patterns for PanLL development

(agentic
  (version "1.0.0")
  (last-updated "2026-02-07")
  (manifest-reference "0-AI-MANIFEST.a2ml")

  (agent-protocols
    (session-startup
      "1. Read 0-AI-MANIFEST.a2ml FIRST (mandatory, before any file operations)"
      "2. Acknowledge canonical locations (.machine_readable/, .bot_directives/)"
      "3. Read STATE.scm for current project status, progress, blockers"
      "4. Read META.scm for architecture decisions and design rationale"
      "5. Read ECOSYSTEM.scm for ecosystem position and dependencies"
      "6. Read AGENTIC.scm (this file) for interaction patterns"
      "7. Read NEUROSYM.scm for neurosymbolic integration config"
      "8. Read PLAYBOOK.scm for operational procedures"
      "9. Log session start in .machine_readable/session-log.txt (optional)"
      "10. Declare understanding of canonical file locations")

    (session-exit
      "1. Update STATE.scm if changes made (completion-percentage, work-completed, blockers)"
      "2. Update ECOSYSTEM.scm if dependencies changed"
      "3. Update META.scm if architecture decisions made"
      "4. Log session end in .machine_readable/session-log.txt (optional)"
      "5. Summarise outcomes in session-history section of STATE.scm")

    (file-modification-rules
      "1. NEVER create SCM files in repository root (STATE.scm, META.scm, etc.)"
      "2. SCM files ONLY in .machine_readable/ directory"
      "3. Always preserve SPDX license headers (PMPL-1.0-or-later)"
      "4. Always use author 'Jonathan D.A. Jewell <jonathan.jewell@open.ac.uk>'"
      "5. Follow ReScript style guide for .res files"
      "6. Follow Rust style guide for .rs files (rustfmt)"
      "7. Update STATE.scm when completing milestone steps"))

  (task-patterns
    (feature-implementation
      (approach "Test-driven development")
      (steps
        "1. Read STATE.scm to understand current position and blockers"
        "2. Identify affected modules (Model, Msg, Update, View, components)"
        "3. Write tests first (tests/*.test.js)"
        "4. Implement feature in ReScript"
        "5. Ensure rescript build compiles without errors"
        "6. Run tests (npm run test)"
        "7. Update STATE.scm (work-completed, completion-percentage)"
        "8. Update ROADMAP.adoc if milestone changed"))

    (bug-fixing
      (approach "Root cause analysis first")
      (steps
        "1. Reproduce bug reliably"
        "2. Identify root cause (check Model state transitions, Update logic)"
        "3. Add regression test"
        "4. Fix bug in minimal way"
        "5. Verify test passes"
        "6. Document fix in STATE.scm session-history"))

    (refactoring
      (approach "Incremental with tests")
      (steps
        "1. Ensure all tests passing before refactoring"
        "2. Make small, atomic changes"
        "3. Run tests after each change"
        "4. Update documentation if API changed"
        "5. Document rationale in META.scm if architecture changed"))

    (migration-work
      (approach "Follow migration guide, test incrementally")
      (current-migration "custom TEA → rescript-tea@0.16.0")
      (tracking-doc "MIGRATION-TO-RESCRIPT-TEA.md")
      (steps
        "1. Read migration guide to understand changes"
        "2. Update imports in one module at a time"
        "3. Run rescript build to check compilation"
        "4. Test module in isolation"
        "5. Commit after each working module"
        "6. Update STATE.scm work-in-progress section")))

  (code-generation-guidelines
    (rescript
      (style "OCaml-influenced, functional-first")
      (conventions
        "- Use pattern matching for variant types (msg, viewMode, oodaPhase)"
        "- Prefer immutable updates (record spread: {...model, field: newValue})"
        "- Use option<'a> for nullable values (never null/undefined)"
        "- Type annotations for public functions"
        "- SPDX header: // SPDX-License-Identifier: PMPL-1.0-or-later"
        "- Doc comments: /// for module/function descriptions"))

    (rust
      (style "Tauri backend, memory-safe")
      (conventions
        "- #[tauri::command] for exposed commands"
        "- Result<T, String> for fallible operations"
        "- serde for JSON serialisation"
        "- SPDX header: // SPDX-License-Identifier: PMPL-1.0-or-later"
        "- Doc comments: /// for public functions"))

    (tests
      (framework "Vitest")
      (conventions
        "- One test file per module (Tea_Cmd.test.js, Tea_App.test.js)"
        "- describe() blocks for logical grouping"
        "- test() for individual cases"
        "- Aim for 95%+ coverage"
        "- Test pure functions (Model, Update) thoroughly"
        "- Integration tests for Tauri commands")))

  (interaction-preferences
    (communication-style
      "Direct, technical, focused on implementation. "
      "Prefer code examples over abstract explanations. "
      "Use Binary Star metaphors when discussing architecture. "
      "Reference ADRs in META.scm when discussing design decisions.")

    (decision-making
      "Agent should propose solutions with rationale, but defer major architecture decisions to maintainer. "
      "Safe to make: Bug fixes, refactoring within existing patterns, test additions, documentation updates. "
      "Requires approval: New features, API changes, dependency additions, architecture changes.")

    (error-handling
      "When encountering errors:"
      "1. Include full error message and context"
      "2. Propose fix with explanation"
      "3. Update STATE.scm blockers if cannot resolve"
      "4. Never silently ignore errors")

    (documentation-updates
      "Update documentation when:"
      "- Adding new features (README.adoc, ROADMAP.adoc)"
      "- Making architecture decisions (META.scm ADRs)"
      "- Changing build process (README.adoc, PLAYBOOK.scm)"
      "- Completing milestones (STATE.scm, ROADMAP.adoc)"))

  (collaboration-patterns
    (with-human-maintainer
      "PanLL is alpha software with active development. "
      "Maintainer (Jonathan D.A. Jewell) reviews all changes. "
      "Agent should:"
      "- Propose changes with clear rationale"
      "- Highlight breaking changes explicitly"
      "- Defer UX decisions to maintainer"
      "- Document assumptions when making design choices")

    (with-other-agents
      "If multiple agents working on PanLL:"
      "- Use STATE.scm as source of truth for current state"
      "- Log session starts/ends to avoid conflicts"
      "- Coordinate on blockers via STATE.scm active-blockers"
      "- Commit frequently with clear messages")

    (with-gitbot-fleet
      "PanLL may integrate with gitbot-fleet automation:"
      "- rhodibot: Git operations, branch management"
      "- echidnabot: Code quality, formal verification"
      "- sustainabot: Dependency updates"
      "- glambot: Documentation generation"
      "Instructions in .bot_directives/ (when created)"))

  (anti-patterns
    "NEVER:"
    "- Create SCM files in repository root (STATE.scm, META.scm, etc.)"
    "- Use TypeScript (policy violation, use ReScript)"
    "- Use npm for runtime (policy violation, use Deno)"
    "- Use AGPL license (superseded by PMPL-1.0-or-later)"
    "- Hardcode author as 'hyperpolymath' (use Jonathan D.A. Jewell)"
    "- Force-push to main branch"
    "- Commit node_modules/ or generated .js files from ReScript"
    "- Skip tests when making changes")

  (tools-and-workflows
    (build-commands
      "npm run res:build     - Compile ReScript to JavaScript"
      "npm run res:watch     - Watch ReScript files, recompile on change"
      "deno task css:build   - Compile Tailwind CSS (minified)"
      "deno task css:watch   - Watch Tailwind, recompile on change"
      "deno task dev         - Run Tailwind watch + Tauri dev"
      "deno task build       - Full production build (CSS + Tauri)")

    (test-commands
      "npm run test          - Run all tests"
      "npm run test:watch    - Watch mode for tests"
      "npm run test:ui       - Interactive test UI"
      "npm run test:coverage - Generate coverage report")

    (tauri-commands
      "npm run tauri:dev     - Run Tauri in development mode"
      "npm run tauri:build   - Build production Tauri app")

    (git-workflow
      "1. Create feature branch: git checkout -b feature/description"
      "2. Make changes, commit frequently"
      "3. Push to origin"
      "4. Create pull request"
      "5. CI/CD runs tests, linters"
      "6. After approval, merge to main")))
