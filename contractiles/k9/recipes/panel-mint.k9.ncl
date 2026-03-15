# SPDX-License-Identifier: PMPL-1.0-or-later
# K9 Hunt Recipe: Panel Mint
#
# Mints a new panel through the bot-assisted pipeline. This is the
# canonical way to create a new panel in PanLL — it scaffolds all 8
# files (DD-004), wires all 7 points (PCC), assigns a clade, and
# runs verification.
#
# The minting process:
#   1. Scaffold ReScript files (model, engine, component, cmd)
#   2. Scaffold Rust backend files (if has_backend)
#   3. Scaffold test file
#   4. Wire into registry, Model.res, Msg.res, View.res, Update.res
#   5. Register Tauri commands (if has_backend)
#   6. Run PCC verify to confirm wiring
#   7. Run ReScript build to confirm compilation
#
# This recipe modifies the filesystem extensively and MUST have a
# valid cryptographic signature before execution.
#
# Pedigree:
#   Name:    panel-mint
#   Version: 0.1.0
#   Author:  Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#   Leash:   Hunt (creates files, modifies wiring, requires signature)

{
  pedigree = {
    name = "panel-mint",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Hunt,
    signature_required = true,
    description = "Scaffold and wire a new PanLL panel following the DD-004 8-file pattern",
  },

  side_effects = {
    reads_filesystem = true,
    writes_filesystem = true,
    network_access = false,
    executes_commands = true,
  },

  # Parameters the recipe expects (passed via `k9 run panel-mint --param ...`).
  parameters = {
    panel_name = {
      type = "string",
      required = true,
      description = "PascalCase panel name (e.g. 'FileExplorer')",
    },
    clade_kind = {
      type = "string",
      required = true,
      description = "Clade kind: overlay, infrastructure, scanner, viewer, builder, terminal, directive",
    },
    has_backend = {
      type = "bool",
      required = true,
      description = "Whether the panel needs a Rust/Tauri backend",
    },
    parent_clade = {
      type = "string",
      required = false,
      default = "root",
      description = "Parent clade identifier (default: root)",
    },
  },

  config = {
    fail_fast = true,
    working_directory = ".",
    env = {},
  },

  recipes = {
    scaffold_rescript = {
      command = "tools/pcc/target/release/panll panel scaffold --name ${panel_name} --clade ${clade_kind} --backend ${has_backend}",
      description = "Scaffold all ReScript files from templates (model, engine, component, cmd)",
      timeout_seconds = 30,
      expected_exit = 0,
      on_failure = "Failed to scaffold ReScript files. Check that tools/pcc is built.",
    },

    scaffold_rust = {
      command = "tools/pcc/target/release/panll panel scaffold-rust --name ${panel_name}",
      description = "Scaffold Rust backend module (mod.rs, types.rs, commands.rs)",
      timeout_seconds = 30,
      expected_exit = 0,
      skip_if = "!has_backend",
      on_failure = "Failed to scaffold Rust backend. Check src-tauri/src/ permissions.",
    },

    scaffold_test = {
      command = "tools/pcc/target/release/panll panel scaffold-test --name ${panel_name}",
      description = "Scaffold Deno test file for the engine",
      timeout_seconds = 15,
      expected_exit = 0,
      on_failure = "Failed to scaffold test file.",
    },

    wire_panel = {
      command = "tools/pcc/target/release/panll panel wire --name ${panel_name} --clade ${clade_kind}",
      description = "Wire panel into all 7 integration points (registry, model, msg, view, update, rust, init)",
      timeout_seconds = 30,
      expected_exit = 0,
      on_failure = "Failed to wire panel. Run 'panll panel verify --verbose' to diagnose.",
    },

    verify_wiring = {
      command = "tools/pcc/target/release/panll panel verify --panel ${panel_name} --repo-root .",
      description = "PCC verification — confirm all wiring points are connected",
      timeout_seconds = 60,
      expected_exit = 0,
      on_failure = "Wiring verification failed. The panel was scaffolded but not fully wired.",
    },

    build_check = {
      command = "deno task res:build",
      description = "ReScript build — confirm the new panel compiles without errors",
      timeout_seconds = 120,
      expected_exit = 0,
      on_failure = "ReScript build failed after minting. The scaffolded code has type errors.",
    },
  },
}
