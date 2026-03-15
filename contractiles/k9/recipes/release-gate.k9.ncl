# SPDX-License-Identifier: PMPL-1.0-or-later
# K9 Hunt Recipe: Release Gate
#
# Full release readiness check implementing the Phase 4 completion
# policy. A release is blocked until ALL gates pass. This is the
# final quality gate before a PanLL version can be tagged and shipped.
#
# Release gates (in order):
#   1. Build validation     — full build pipeline (ReScript + Rust + PCC)
#   2. Test suite           — all tests passing with 0 failures
#   3. Seam audit           — proximal + distal seam integrity
#   4. SPDX compliance      — all files have correct license headers
#   5. Dangerous patterns   — no banned patterns in production code
#   6. Accessibility audit  — WCAG baseline met for all components
#   7. Provenance check     — no unreviewed AI code
#   8. Panic-attack assail  — pre-commit security scan
#   9. Changelog            — CHANGELOG.adoc updated for this version
#  10. Version bump         — Cargo.toml + deno.json versions match
#
# Pedigree:
#   Name:    release-gate
#   Version: 0.1.0
#   Author:  Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#   Leash:   Hunt (executes commands, requires signature)

{
  pedigree = {
    name = "release-gate",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Hunt,
    signature_required = true,
    description = "Phase 4 release readiness gate — all checks must pass before tagging a release",
  },

  side_effects = {
    reads_filesystem = true,
    writes_filesystem = false,
    network_access = false,
    executes_commands = true,
  },

  config = {
    # Do NOT fail-fast — collect all failures for a complete release report.
    fail_fast = false,
    working_directory = ".",
    env = {},
  },

  # Parameters for release versioning.
  parameters = {
    version = {
      type = "string",
      required = true,
      description = "Semver version being released (e.g. '0.5.0')",
    },
  },

  recipes = {
    # Gate 1: Full build pipeline.
    build_pipeline = {
      command = "k9 run build-validation",
      description = "Run the full build-validation recipe (ReScript + Rust + PCC + tests)",
      timeout_seconds = 600,
      expected_exit = 0,
      on_failure = "Build pipeline failed. Fix build errors before releasing.",
    },

    # Gate 2: Test suite with coverage.
    test_coverage = {
      command = "deno test --no-check --allow-read --allow-env --coverage=coverage/ tests/",
      description = "Run test suite with coverage collection",
      timeout_seconds = 300,
      expected_exit = 0,
      on_failure = "Test suite has failures. All tests must pass for release.",
    },

    # Gate 3: Seam audit.
    seam_integrity = {
      command = "k9 run seam-audit",
      description = "Run the full seam-audit recipe (proximal + distal)",
      timeout_seconds = 300,
      expected_exit = 0,
      on_failure = "Seam audit found integration breakages. Fix seam issues before releasing.",
    },

    # Gate 4: SPDX compliance scan.
    spdx_scan = {
      command = "tools/pcc/target/release/panll audit spdx --repo-root .",
      description = "Scan all source files for SPDX license header compliance",
      timeout_seconds = 60,
      expected_exit = 0,
      on_failure = "SPDX compliance failures found. Add missing license headers.",
    },

    # Gate 5: Dangerous pattern scan.
    dangerous_pattern_scan = {
      command = "tools/pcc/target/release/panll audit dangerous-patterns --repo-root .",
      description = "Scan for banned patterns (Obj.magic, believe_me, unsafe, etc.)",
      timeout_seconds = 60,
      expected_exit = 0,
      on_failure = "Dangerous patterns found in production code. Remove or replace with safe alternatives from the proven repo.",
    },

    # Gate 6: Accessibility audit.
    accessibility_audit = {
      command = "tools/pcc/target/release/panll audit accessibility --repo-root .",
      description = "Verify WCAG baseline for all interactive components (DD-008)",
      timeout_seconds = 60,
      expected_exit = 0,
      on_failure = "Accessibility baseline not met. Add aria-labels, roles, and keyboard handlers.",
    },

    # Gate 7: Provenance check.
    provenance_audit = {
      command = "tools/pcc/target/release/panll audit provenance --repo-root .",
      description = "Check for unreviewed AI code (DD-006 hostile UX policy)",
      timeout_seconds = 60,
      expected_exit = 0,
      on_failure = "Unreviewed AI code found. All AI-assisted code must be human-reviewed before release.",
    },

    # Gate 8: Panic-attack pre-commit security scan.
    panic_attack = {
      command = "panic-attack assail",
      description = "Run panic-attack security scan (secrets, vulnerabilities, supply chain)",
      timeout_seconds = 120,
      expected_exit = 0,
      on_failure = "Panic-attack found security issues. Resolve all findings before releasing.",
    },

    # Gate 9: Changelog check.
    changelog_check = {
      command = "tools/pcc/target/release/panll audit changelog --version ${version} --repo-root .",
      description = "Verify CHANGELOG.adoc has an entry for the target version",
      timeout_seconds = 15,
      expected_exit = 0,
      on_failure = "CHANGELOG.adoc does not have an entry for version ${version}. Update the changelog.",
    },

    # Gate 10: Version consistency.
    version_consistency = {
      command = "tools/pcc/target/release/panll audit version --expected ${version} --repo-root .",
      description = "Verify Cargo.toml and deno.json versions match the target release version",
      timeout_seconds = 15,
      expected_exit = 0,
      on_failure = "Version mismatch. Ensure Cargo.toml and deno.json both declare version ${version}.",
    },
  },
}
