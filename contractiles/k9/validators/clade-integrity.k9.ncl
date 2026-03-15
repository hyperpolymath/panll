# SPDX-License-Identifier: PMPL-1.0-or-later
# K9 Yard Validator: Clade Integrity
#
# Validates clade manifest structure. Clades are the taxonomic grouping
# system for PanLL panels — every panel belongs to a clade that defines
# its behavioural lineage, inherited traits, and rendering constraints.
#
# Clade kinds:
#   - overlay:        Floating panels (modals, tooltips, command palette)
#   - infrastructure: System-level panels (settings, workspace, security)
#   - scanner:        Panels that scan/analyse (ECHIDNA, linters, audit)
#   - viewer:         Read-only display panels (logs, previews, diffs)
#   - builder:        Panels that create/modify artifacts (editors, designers)
#   - terminal:       Terminal/REPL panels
#   - directive:      Panels that issue commands to other panels (orchestration)
#
# Pedigree:
#   Name:    clade-integrity
#   Version: 0.1.0
#   Author:  Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#   Leash:   Yard (read-only validation, no side effects)

let CladeKind = [|
  'overlay,
  'infrastructure,
  'scanner,
  'viewer,
  'builder,
  'terminal,
  'directive,
|]
in

let CladeManifest = {
  # Unique clade identifier (kebab-case, e.g. "file-explorer").
  id
    | String
    | doc "Unique clade identifier in kebab-case",

  # Human-readable clade name (e.g. "File Explorer").
  name
    | String
    | doc "Human-readable clade name",

  # The clade kind determines the panel's behavioural category.
  kind
    | CladeKind
    | doc "Behavioural category of the clade",

  # Parent clade identifier. Use "root" for top-level clades.
  parent
    | String
    | doc "Parent clade identifier (use 'root' for top-level)",

  # Human-readable description of the clade's purpose.
  description
    | String
    | doc "Description of the clade's purpose and behaviour",

  # --- Trait flags ---
  # These define the inherited capabilities of all panels in this clade.
  traits
    | {
        # Whether panels in this clade have a Rust/Tauri backend.
        has_backend
          | Bool
          | doc "Clade panels have a Rust/Tauri backend",

        # Whether panels in this clade persist state across sessions.
        has_persistence
          | Bool
          | doc "Clade panels persist state across sessions",

        # Whether panels in this clade support user customisation.
        has_customisation
          | Bool
          | doc "Clade panels support user customisation",

        # Whether panels in this clade are strictly read-only.
        is_readonly
          | Bool
          | doc "Clade panels are read-only (no write operations)",
      }
    | doc "Inherited trait flags for all panels in this clade",

  # --- Computed validation ---

  # Read-only panels must NOT have persistence (conflicting semantics).
  readonly_consistency
    | Bool
    | default = if traits.is_readonly then !traits.has_persistence else true
    | doc "Validates that read-only panels do not claim persistence",

  # Overlay panels should not have backends (they are lightweight by design).
  overlay_consistency
    | Bool
    | default = if kind == 'overlay then !traits.has_backend else true
    | doc "Validates that overlay panels do not have backends",

  # Overall manifest validity.
  is_valid
    | Bool
    | default = readonly_consistency && overlay_consistency
    | doc "True when the clade manifest passes all consistency checks",
}
in

CladeManifest
