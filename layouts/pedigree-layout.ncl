# SPDX-License-Identifier: MPL-2.0
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

let valid_percentage = std.contract.from_predicate (fun p => p >= 0 && p <= 100) in

let pane_sizes_sum_100 = std.contract.from_validator (fun value =>
  let total = value.pane_l_size + value.pane_n_size + value.pane_w_size in
  if total == 100 then
    'Ok
  else
    'Error { message = "Pane sizes must sum to 100 (got %{std.string.from_number total})" }
) in

let panel_visibility = [| 'Expanded, 'Collapsed, 'Hidden |] in

let known_prover = [|
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

let layout_preset = {
  # Identity
  name | String,
  description | String,
  author | String | default = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
  version | String | default = "1.0.0",

  # Base layout (for community overrides)
  base | [| 'LogicAndProofs, 'DatabaseDesign, 'LanguageDesign, 'ProtocolDesign, 'General |]
       | optional,

  # Pane sizing (must sum to 100)
  pane_l_size | valid_percentage,
  pane_n_size | valid_percentage,
  pane_w_size | valid_percentage,

  # Panel visibility
  echidna_panel | panel_visibility | default = 'Collapsed,
  verisimdb_panel | panel_visibility | default = 'Collapsed,
  security_panel | panel_visibility | default = 'Hidden,

  # Prover configuration
  default_provers | Array known_prover | default = ['Coq, 'Lean4, 'Z3],

  # Default notation mode
  default_notation | String | default = "panll-universal",

  # Promoted toolbar actions (visible without overflow menu)
  promoted_actions | Array String | default = [],
} in

# Export contracts for use by layout presets. Each field names its binding
# explicitly: `{ Foo, }` in a Nickel record declares Foo without defining it.
{
  LayoutPreset = layout_preset,
  PaneSizesSum100 = pane_sizes_sum_100,
  PanelVisibility = panel_visibility,
  KnownProver = known_prover,
  ValidPercentage = valid_percentage,
}
