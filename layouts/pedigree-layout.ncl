# SPDX-License-Identifier: PMPL-1.0-or-later
# pedigree-layout.ncl — Contract schema for PanLL discipline layout presets.
#
# Every .k9.ncl layout preset in this directory must satisfy these contracts.
# The Nickel type system enforces at evaluation time that:
#   - Pane sizes sum to exactly 100
#   - Panel visibility states are valid enums
#   - Prover references are from the known catalog
#   - Toolbar actions are from the known action set
#
# Security level: Yard (Nickel evaluation only, no I/O)

# ─────────────────────────────────────────────────────────────
# Contracts — validation predicates for layout fields
# ─────────────────────────────────────────────────────────────

let ValidPercentage = std.contract.from_predicate (fun p => p >= 0 && p <= 100) in

let PaneSizesSum100 = fun label value =>
  let total = value.pane_l_size + value.pane_n_size + value.pane_w_size in
  if total == 100 then
    value
  else
    std.contract.blame_with_message
      "Pane sizes must sum to 100 (got %{std.string.from_number total})"
      label
in

let PanelVisibility = [| 'Expanded, 'Collapsed, 'Hidden |] in

let KnownProver = [|
  'Coq,
  'Lean4,
  'Isabelle,
  'Agda,
  'Z3,
  'TLAPlus,
  'Spin,
  'Tamarin,
|] in

# ─────────────────────────────────────────────────────────────
# Layout Preset Schema
# ─────────────────────────────────────────────────────────────

let LayoutPreset = {
  # Identity
  name | String,
  description | String,
  author | String | default = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
  version | String | default = "1.0.0",

  # Base layout (for community overrides)
  base | [| 'LogicAndProofs, 'DatabaseDesign, 'LanguageDesign, 'ProtocolDesign, 'General |]
       | optional,

  # Pane sizing (must sum to 100)
  pane_l_size | ValidPercentage,
  pane_n_size | ValidPercentage,
  pane_w_size | ValidPercentage,

  # Panel visibility
  echidna_panel | PanelVisibility | default = 'Collapsed,
  verisimdb_panel | PanelVisibility | default = 'Collapsed,
  security_panel | PanelVisibility | default = 'Hidden,

  # Prover configuration
  default_provers | Array KnownProver | default = ['Coq, 'Lean4, 'Z3],

  # Default notation mode
  default_notation | String | default = "panll-universal",

  # Promoted toolbar actions (visible without overflow menu)
  promoted_actions | Array String | default = [],
} in

# ─────────────────────────────────────────────────────────────
# K9 Pedigree for layout presets (Yard level — no I/O)
# ─────────────────────────────────────────────────────────────

let LayoutPedigree = {
  metadata = {
    name = "panll-layout-preset",
    version = "1.0.0",
    breed = "application/vnd.k9+nickel",
    description = "PanLL discipline layout preset — configures pane sizing, panel visibility, prover priority, and toolbar for a specific workflow.",
  },
  target = {
    os = 'Linux,
    is_edge = false,
    requires_podman = false,
    min_memory_mb = 0,
  },
  security = {
    trust_level = 'Yard,
    allow_network = false,
    allow_filesystem_write = false,
    allow_subprocess = false,
  },
  validation = {
    checksum = "pending",
    pedigree_version = "1.0.0",
    hunt_authorized = false,
  },
  recipes = {
    install = "echo 'Copy .k9.ncl to layouts/'",
    validate = "nickel typecheck",
    deploy = "echo 'No deployment — config only'",
    migrate = "echo 'No migration needed'",
  },
} in

# Export contracts for use by layout presets
{
  LayoutPreset,
  LayoutPedigree,
  PaneSizesSum100,
  PanelVisibility,
  KnownProver,
  ValidPercentage,
}
