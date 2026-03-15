# SPDX-License-Identifier: PMPL-1.0-or-later
# K9 Hunt Recipe: Build Validation
#
# Executes the full PanLL build pipeline and reports pass/fail for each
# gate. This recipe runs actual commands (side effects!) and therefore
# requires cryptographic signature verification before execution.
#
# Gates (in order):
#   1. ReScript build    — deno task res:build
#   2. Rust type check   — cargo check
#   3. PCC verification  — panll panel verify
#   4. Deno test suite   — deno test
#
# All gates must pass for the build to be considered valid.
# Failure at any gate halts the pipeline (fail-fast).
#
# Pedigree:
#   Name:    build-validation
#   Version: 0.1.0
#   Author:  Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#   Leash:   Hunt (executes commands, requires signature)

{
  pedigree = {
    name = "build-validation",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Hunt,
    signature_required = true,
    description = "Full PanLL build pipeline validation with fail-fast semantics",
  },

  # Side effects declaration — the K9 runner uses this to determine
  # what permissions are needed before executing the recipe.
  side_effects = {
    reads_filesystem = true,
    writes_filesystem = false,
    network_access = false,
    executes_commands = true,
  },

  # Execution configuration.
  config = {
    # Fail-fast: stop at the first failing gate.
    fail_fast = true,
    # Working directory (relative to repo root).
    working_directory = ".",
    # Environment variables to set.
    env = {},
  },

  # Build gates, executed in declaration order.
  recipes = {
    rescript_build = {
      command = "deno task res:build",
      description = "ReScript compilation gate — compiles all .res files to JS",
      timeout_seconds = 120,
      expected_exit = 0,
      on_failure = "ReScript compilation failed. Check for type errors in src/**/*.res files.",
    },

    rust_check = {
      command = "cargo check --manifest-path src-tauri/Cargo.toml",
      description = "Rust type checking gate — validates all Tauri backend code",
      timeout_seconds = 180,
      expected_exit = 0,
      on_failure = "Rust type check failed. Check for errors in src-tauri/src/**/*.rs files.",
    },

    pcc_verify = {
      command = "tools/pcc/target/release/panll panel verify --repo-root .",
      description = "Panel Contract Compiler verification gate — validates wiring and structure",
      timeout_seconds = 60,
      expected_exit = 0,
      on_failure = "PCC verification failed. Run 'panll panel verify --verbose' for details.",
    },

    deno_test = {
      command = "deno test --no-check --allow-read --allow-env tests/",
      description = "Deno test suite gate — runs all engine and integration tests",
      timeout_seconds = 300,
      expected_exit = 0,
      on_failure = "Test suite failed. Check tests/ for failing assertions.",
    },
  },
}
