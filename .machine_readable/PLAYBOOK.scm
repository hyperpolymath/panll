;; SPDX-License-Identifier: PMPL-1.0-or-later
;; PLAYBOOK.scm - Operational runbook for PanLL development and usage

(playbook
  (version "1.0.0")
  (last-updated "2026-02-07")

  (migration-notice
    "⚠️  npm→Deno migration completed (2026-02-07). Many npm commands in this file are outdated."
    "CURRENT TEST COMMAND: deno task test (not npm run test)"
    "CURRENT DEV COMMAND: deno task dev"
    "ReScript compilation: node_modules/rescript/rescript build (or npm run res:build still works)"
    "Test results: 33 tests passing in 719ms with Deno.test"
    "This file will be comprehensively updated in a future session.")

  (setup-procedures
    (initial-setup
      "Setting up PanLL development environment for the first time."

      (prerequisites
        "- Deno 1.x installed (https://deno.land/)"
        "- Node.js 18.x+ and npm (for ReScript compiler)"
        "- Rust toolchain (for Tauri backend)"
        "- Git")

      (steps
        "1. Clone repository: git clone https://github.com/hyperpolymath/panll.git"
        "2. cd panll"
        "3. Install npm dependencies: npm install"
        "4. Compile ReScript: npm run res:build"
        "5. Build Tailwind CSS: deno task css:build"
        "6. Run Tauri dev: deno task dev"
        "7. Verify app launches, three panes visible"
        "8. Run tests: npm run test (should see 33 passing tests)"))

    (updating-dependencies
      "Keeping dependencies up-to-date."

      (npm-updates
        "1. Check outdated: npm outdated"
        "2. Update package.json versions"
        "3. npm install"
        "4. Test: npm run test"
        "5. Commit: git commit -m 'chore: update npm dependencies'")

      (deno-updates
        "1. Check Deno version: deno --version"
        "2. Update Deno: deno upgrade"
        "3. Test Deno tasks: deno task css:build"
        "4. No package.json changes needed (Deno uses JSR/npm specifiers)"))

    (troubleshooting-setup
      ((issue "ReScript compilation fails")
       (symptoms "npm run res:build errors, .res.js files not generated")
       (diagnosis "Check rescript.json config, ensure @rescript/core installed")
       (solution "npm run res:clean && npm install && npm run res:build"))

      ((issue "Tauri fails to start")
       (symptoms "deno task dev errors, no app window appears")
       (diagnosis "Check Rust toolchain, Tauri CLI version")
       (solution "cargo --version (ensure Rust installed), npm list @tauri-apps/cli"))

      ((issue "Tests failing")
       (symptoms "npm run test shows failures")
       (diagnosis "Check node_modules, happy-dom version")
       (solution "npm install && npm run test"))))

  (development-workflows
    (feature-development
      "Adding a new feature to PanLL."

      (workflow
        "1. Read STATE.scm to understand current state, blockers"
        "2. Create feature branch: git checkout -b feature/description"
        "3. Write tests first (tests/*.test.js)"
        "4. Implement feature in ReScript (src/*.res)"
        "5. Compile: npm run res:build"
        "6. Run tests: npm run test"
        "7. Test manually: deno task dev"
        "8. Update STATE.scm (work-completed, completion-percentage)"
        "9. Update ROADMAP.adoc if milestone affected"
        "10. Commit: git commit -m 'feat: description'"
        "11. Push: git push origin feature/description"
        "12. Create pull request"))

    (bug-fixing
      "Fixing a bug in PanLL."

      (workflow
        "1. Reproduce bug reliably (record steps)"
        "2. Create bug branch: git checkout -b fix/description"
        "3. Add regression test to tests/*.test.js"
        "4. Run test to confirm it fails: npm run test"
        "5. Fix bug in src/*.res"
        "6. Compile: npm run res:build"
        "7. Run test to confirm it passes: npm run test"
        "8. Test manually: deno task dev"
        "9. Commit: git commit -m 'fix: description'"
        "10. Push and create pull request"))

    (refactoring
      "Refactoring code without changing behaviour."

      (workflow
        "1. Ensure all tests passing: npm run test"
        "2. Create refactor branch: git checkout -b refactor/description"
        "3. Make small, atomic changes"
        "4. Compile and test after each change"
        "5. Commit frequently: git commit -m 'refactor: description'"
        "6. Update META.scm if architecture changed (ADR)"
        "7. Push and create pull request"))

    (migration-work
      "Completing the custom TEA → rescript-tea migration."

      (current-status "IN PROGRESS (see MIGRATION-TO-RESCRIPT-TEA.md)")

      (workflow
        "1. Read MIGRATION-TO-RESCRIPT-TEA.md for current status"
        "2. Update one module at a time (e.g., App.res)"
        "3. Change imports: open Tea.App → open Tea_App"
        "4. Update command/subscription usage"
        "5. Compile: npm run res:build"
        "6. Fix compilation errors"
        "7. Test module: npm run test"
        "8. Commit: git commit -m 'refactor: migrate App.res to rescript-tea'"
        "9. Update MIGRATION-TO-RESCRIPT-TEA.md checklist"
        "10. Repeat for next module"))

    (documentation-updates
      "Updating project documentation."

      (when-to-update
        "- New feature added → Update README.adoc, ROADMAP.adoc"
        "- Architecture decision made → Add ADR to META.scm"
        "- Build process changed → Update README.adoc, PLAYBOOK.scm"
        "- Milestone completed → Update STATE.scm, ROADMAP.adoc"
        "- Dependencies changed → Update ECOSYSTEM.scm")

      (workflow
        "1. Edit relevant .adoc, .md, or .scm file"
        "2. Preview rendering (VS Code AsciiDoc extension for .adoc)"
        "3. Commit: git commit -m 'docs: description'")))

  (testing-procedures
    (unit-testing
      "Running unit tests for ReScript modules."

      (commands
        "npm run test          - Run all tests once"
        "npm run test:watch    - Watch mode (re-run on file change)"
        "npm run test:ui       - Interactive test UI in browser"
        "npm run test:coverage - Generate coverage report")

      (coverage-targets
        "- v0.1.0: 87-91% (current)"
        "- v0.2.0: 90%+ target"
        "- v0.3.0: 95%+ target"))

    (integration-testing
      "Testing Tauri backend integration."

      (approach "Manual testing in dev mode currently")
      (commands "deno task dev")
      (test-scenarios
        "1. Launch app, verify three panes render"
        "2. Toggle panes (Ctrl+Shift+L/N/W), verify visibility changes"
        "3. Add constraint in Pane-L, verify stored in model"
        "4. Trigger neural token, verify Anti-Crash validation called"
        "5. Check Vexometer updates"
        "Future: Automated integration tests with Tauri test harness"))

    (end-to-end-testing
      "Testing complete user workflows."

      (scenarios
        "1. New user onboarding: Launch app, see Dark Start mode, first interaction"
        "2. Constraint creation: Add constraint, toggle active/inactive, pin constraint"
        "3. Neural validation: Generate token, pass/fail validation, operator intervention"
        "4. Vexometer tracking: Perform actions, check vexation index updates"
        "5. Feedback submission: Open Feedback-O-Tron, submit feedback"
        "Future: Automated E2E tests with Playwright or similar")))

  (deployment-procedures
    (development-builds
      "Creating development builds for testing."

      (commands "deno task dev")
      (features
        "- Hot reload for ReScript/Tailwind changes"
        "- DevTools open by default (Tauri debug mode)"
        "- Unoptimised bundle (faster builds)"))

    (production-builds
      "Creating production releases."

      (workflow
        "1. Ensure all tests passing: npm run test"
        "2. Update version in package.json, Cargo.toml, STATE.scm"
        "3. Update CHANGELOG.md (if exists) or ROADMAP.adoc"
        "4. Build: deno task build"
        "5. Test production app: ./src-tauri/target/release/panll (Linux)"
        "6. Create git tag: git tag v0.x.y"
        "7. Push: git push origin main --tags"
        "8. GitHub Actions (future): Auto-build, create release")

      (artifacts
        "- Linux: .deb, .AppImage in src-tauri/target/release/bundle/"
        "- macOS: .dmg in src-tauri/target/release/bundle/"
        "- Windows: .msi in src-tauri/target/release/bundle/"))

    (release-checklist
      "Before releasing a version:"
      "☐ All tests passing (npm run test)"
      "☐ Coverage meets target (npm run test:coverage)"
      "☐ Manual E2E testing completed"
      "☐ README.adoc updated with new features"
      "☐ ROADMAP.adoc updated (milestone completed)"
      "☐ STATE.scm updated (version, completion-percentage)"
      "☐ Version bumped in package.json, Cargo.toml"
      "☐ Git tag created"
      "☐ Release notes written (GitHub release)"))

  (operational-procedures
    (monitoring
      "No production monitoring yet (alpha software). "
      "Future: Telemetry for vexation index, validation latency, orbital stability.")

    (backup-and-recovery
      "Development only (no production data). "
      "Git repository is source of truth. "
      "User data (constraints, tokens) not persisted yet (planned v0.2.0).")

    (incident-response
      "For critical bugs discovered in released versions:"
      "1. Create hotfix branch: git checkout -b hotfix/description"
      "2. Fix bug, add regression test"
      "3. Bump patch version (e.g., 0.1.0 → 0.1.1)"
      "4. Build: deno task build"
      "5. Test thoroughly"
      "6. Tag: git tag v0.1.1"
      "7. Push: git push origin main --tags"
      "8. Create GitHub release with patch notes"))

  (maintenance-tasks
    (dependency-updates
      "Frequency: Monthly (or when security vulnerabilities reported)")

    (test-coverage-review
      "Frequency: Each milestone (v0.2.0, v0.3.0, etc.)")

    (documentation-audit
      "Frequency: Each major release (v1.0.0, v2.0.0)")

    (performance-profiling
      "Frequency: Before production release (v1.0.0)")

    (security-audit
      "Frequency: Before production release (v1.0.0), then annually"))

  (common-commands
    (build-and-run
      "npm run res:build     - Compile ReScript"
      "npm run res:watch     - Watch ReScript files"
      "deno task css:build   - Compile Tailwind CSS"
      "deno task css:watch   - Watch Tailwind CSS"
      "deno task dev         - Run Tauri dev (CSS watch + Tauri)"
      "deno task build       - Production build")

    (testing
      "npm run test          - Run tests"
      "npm run test:watch    - Watch mode"
      "npm run test:ui       - Interactive UI"
      "npm run test:coverage - Coverage report")

    (cleanup
      "npm run res:clean     - Clean ReScript build artifacts"
      "rm -rf node_modules   - Remove npm dependencies"
      "rm -rf src-tauri/target - Remove Rust build artifacts")

    (git
      "git status            - Check working tree"
      "git diff              - Show unstaged changes"
      "git log --oneline -10 - Recent commits"
      "git checkout -b <branch> - Create new branch"
      "git push origin <branch> - Push branch"))

  (troubleshooting-guide
    ((symptom "App won't launch (deno task dev fails)")
     (possible-causes
       "- Tauri not installed"
       "- Rust toolchain missing"
       "- Port conflict (Tauri dev server)")
     (solutions
       "- Install Rust: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
       "- Install Tauri CLI: npm install"
       "- Kill conflicting process: lsof -i :1420 (Tauri default port)"))

    ((symptom "ReScript compilation fails")
     (possible-causes
       "- Syntax error in .res file"
       "- Missing dependency"
       "- Corrupted node_modules")
     (solutions
       "- Check error message, fix syntax"
       "- npm install (ensure deps installed)"
       "- npm run res:clean && npm install && npm run res:build"))

    ((symptom "Tests failing unexpectedly")
     (possible-causes
       "- Stale .res.js files (out of sync with .res)"
       "- Missing test dependencies"
       "- Test environment issue (happy-dom)")
     (solutions
       "- npm run res:build (regenerate .res.js)"
       "- npm install"
       "- Check tests/*.test.js for import errors"))

    ((symptom "Hot reload not working")
     (possible-causes
       "- ReScript watch not running"
       "- Tailwind watch not running"
       "- Tauri dev not in watch mode")
     (solutions
       "- Run npm run res:watch in separate terminal"
       "- Run deno task css:watch in separate terminal"
       "- Ensure deno task dev running (includes CSS watch)"))

    ((symptom "Three panes not rendering correctly")
     (possible-causes
       "- Tailwind CSS not compiled"
       "- Missing public/styles.css"
       "- Browser cache issue")
     (solutions
       "- deno task css:build (ensure styles.css generated)"
       "- Check public/styles.css exists"
       "- Hard refresh browser (Ctrl+Shift+R in Tauri DevTools)"))))
