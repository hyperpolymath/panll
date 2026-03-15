# SPDX-License-Identifier: PMPL-1.0-or-later
# K9 Yard Validator: Panel Structure (DD-004)
#
# Validates that a panel follows the canonical 8-file pattern defined in
# DD-004 (Panel Decision Document). Every PanLL panel MUST have at minimum:
#   1. Model file      — src/model/{Name}Model.res
#   2. Engine file     — src/core/{Name}Engine.res
#   3. Component file  — src/components/{Name}.res
#   4. Test file       — tests/{snake}_engine_test.js
# Plus, if the panel has a Rust backend (has_backend = true):
#   5. Cmd file        — src/commands/{Name}Cmd.res
#   6. Rust mod        — src-tauri/src/{snake}/mod.rs
#   7. Rust types      — src-tauri/src/{snake}/types.rs
#   8. Rust commands   — src-tauri/src/{snake}/commands.rs
#
# Pedigree:
#   Name:    panel-structure
#   Version: 0.1.0
#   Author:  Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#   Leash:   Yard (read-only validation, no side effects)

let PanelStructure = {
  # --- Required files (all panels) ---

  # ReScript model file: src/model/{Name}Model.res
  # Contains the panel's state type, init function, and subscriptions.
  model_file
    | String
    | doc "Path to the ReScript model file (src/model/{Name}Model.res)",

  # ReScript engine file: src/core/{Name}Engine.res
  # Contains the pure update logic. Must have NO side effects (see tea-purity).
  engine_file
    | String
    | doc "Path to the ReScript engine file (src/core/{Name}Engine.res)",

  # ReScript component file: src/components/{Name}.res
  # Contains the view function rendering Tea_Html nodes.
  component_file
    | String
    | doc "Path to the ReScript component file (src/components/{Name}.res)",

  # Test file: tests/{snake}_engine_test.js
  # Deno-compatible test file exercising the engine's update logic.
  test_file
    | String
    | doc "Path to the Deno test file (tests/{snake}_engine_test.js)",

  # --- Backend flag ---

  # Whether this panel has a Rust/Tauri backend.
  # When true, the cmd_file, rust_mod, rust_types, and rust_commands
  # fields become mandatory.
  has_backend
    | Bool
    | doc "Whether this panel requires a Rust/Tauri backend",

  # --- Conditional files (only when has_backend = true) ---

  # ReScript command file: src/commands/{Name}Cmd.res
  # Contains Tauri invoke wrappers. Only present for backend panels.
  cmd_file
    | String
    | optional
    | doc "Path to the ReScript command file (src/commands/{Name}Cmd.res)",

  # Rust module entry: src-tauri/src/{snake}/mod.rs
  rust_mod
    | String
    | optional
    | doc "Path to the Rust module file (src-tauri/src/{snake}/mod.rs)",

  # Rust types: src-tauri/src/{snake}/types.rs
  rust_types
    | String
    | optional
    | doc "Path to the Rust types file (src-tauri/src/{snake}/types.rs)",

  # Rust commands: src-tauri/src/{snake}/commands.rs
  rust_commands
    | String
    | optional
    | doc "Path to the Rust commands file (src-tauri/src/{snake}/commands.rs)",

  # --- Computed validation ---

  # Backend completeness: if has_backend, all four backend files must be present.
  # A panel with has_backend = true but missing any backend file is invalid.
  backend_complete
    | Bool
    | default = if has_backend then
        (cmd_file != null) && (rust_mod != null) && (rust_types != null) && (rust_commands != null)
      else
        true
    | doc "True when backend files are complete (or panel has no backend)",

  # Frontend completeness: the four core files must always be present.
  # This is structurally enforced by the non-optional fields above, but
  # kept as an explicit flag for reporting.
  frontend_complete
    | Bool
    | default = true
    | doc "True when all four core ReScript files are present",

  # Overall validity: both halves must pass.
  is_valid
    | Bool
    | default = frontend_complete && backend_complete
    | doc "True when the full 8-file pattern is satisfied",
}
in

PanelStructure
