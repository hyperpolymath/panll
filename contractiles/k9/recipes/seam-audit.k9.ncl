# SPDX-License-Identifier: PMPL-1.0-or-later
# K9 Hunt Recipe: Seam Audit
#
# Runs a full seam check across the PanLL codebase, covering both
# proximal seams (within the repo) and distal seams (cross-repo
# integration points).
#
# Proximal seams:
#   - ReScript <-> Rust boundary (Tauri invoke/command parity)
#   - Model <-> Engine <-> View wiring consistency
#   - TEA message routing completeness
#   - CSS/style module import validity
#
# Distal seams:
#   - TypeLL kernel dependency compatibility
#   - VeriSimDB query interface alignment
#   - ECHIDNA scanner integration points
#   - IDApTIK game panel protocol conformance
#
# Seam checks are read-only analyses but require command execution
# to run the various checkers, hence Hunt leash level.
#
# Pedigree:
#   Name:    seam-audit
#   Version: 0.1.0
#   Author:  Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#   Leash:   Hunt (executes analysis commands, requires signature)

{
  pedigree = {
    name = "seam-audit",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Hunt,
    signature_required = true,
    description = "Full proximal and distal seam audit across PanLL integration boundaries",
  },

  side_effects = {
    reads_filesystem = true,
    writes_filesystem = false,
    network_access = false,
    executes_commands = true,
  },

  config = {
    # Do NOT fail-fast — collect all seam failures for a complete report.
    fail_fast = false,
    working_directory = ".",
    env = {},
  },

  recipes = {
    # --- Proximal seams (within the PanLL repo) ---

    tauri_invoke_parity = {
      command = "tools/pcc/target/release/panll seam check-invoke-parity --repo-root .",
      description = "Verify every ReScript invoke() call has a matching Rust #[tauri::command]",
      timeout_seconds = 60,
      expected_exit = 0,
      on_failure = "Invoke parity broken — ReScript calls a Tauri command that does not exist in Rust (or vice versa).",
    },

    wiring_consistency = {
      command = "tools/pcc/target/release/panll panel verify --all --repo-root .",
      description = "PCC full panel verification — all panels, all 7 wiring points",
      timeout_seconds = 120,
      expected_exit = 0,
      on_failure = "Panel wiring inconsistency detected. Run 'panll panel verify --verbose' for details.",
    },

    tea_message_routing = {
      command = "tools/pcc/target/release/panll seam check-msg-routing --repo-root .",
      description = "Verify every Msg variant has a corresponding Update.res handler",
      timeout_seconds = 30,
      expected_exit = 0,
      on_failure = "Orphaned message variants found — some Msg cases are never handled in Update.res.",
    },

    style_import_validity = {
      command = "tools/pcc/target/release/panll seam check-styles --repo-root .",
      description = "Verify all CSS module imports resolve to existing .module.css files",
      timeout_seconds = 30,
      expected_exit = 0,
      on_failure = "Broken style imports — some components reference CSS modules that do not exist.",
    },

    # --- Distal seams (cross-repo integration) ---

    typell_compatibility = {
      command = "tools/pcc/target/release/panll seam check-typell --typell-root ../typell --repo-root .",
      description = "Verify TypeLL kernel API compatibility with PanLL bridge crates",
      timeout_seconds = 90,
      expected_exit = 0,
      on_failure = "TypeLL kernel API drift detected — bridge crates may need updating.",
    },

    verisimdb_interface = {
      command = "tools/pcc/target/release/panll seam check-verisimdb --repo-root .",
      description = "Verify VeriSimDB query interface alignment with PanLL data models",
      timeout_seconds = 60,
      expected_exit = 0,
      on_failure = "VeriSimDB interface mismatch — query types may have changed upstream.",
    },

    echidna_integration = {
      command = "tools/pcc/target/release/panll seam check-echidna --repo-root .",
      description = "Verify ECHIDNA scanner integration points are current",
      timeout_seconds = 60,
      expected_exit = 0,
      on_failure = "ECHIDNA integration drift — scanner protocol may have changed.",
    },

    # --- Summary ---

    generate_report = {
      command = "tools/pcc/target/release/panll seam report --format json --repo-root .",
      description = "Generate a JSON seam audit report summarising all check results",
      timeout_seconds = 30,
      expected_exit = 0,
      on_failure = "Could not generate seam report.",
    },
  },
}
