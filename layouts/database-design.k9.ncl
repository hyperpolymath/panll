# SPDX-License-Identifier: PMPL-1.0-or-later
# database-design.k9.ncl — PanLL discipline layout for database work.
#
# Target audience: Database designers, data modellers, query developers,
# people working with VeriSimDB/QuandleDB/LithoGlyph or other multi-modal
# databases.
#
# Key insight: These users need entity browsers, drift detection, query
# editors, and the ability to verify data integrity constraints. ECHIDNA
# is available for proving query correctness or schema invariants but
# isn't the primary workflow.
#
# Security level: Yard (pure configuration, no I/O)

let { LayoutPreset, LayoutPedigree, PaneSizesSum100, .. } =
  import "./pedigree-layout.ncl" in

let layout | LayoutPreset | PaneSizesSum100 = {
  name = "Database Design",
  description = "Optimised for database design, entity browsing, drift detection, and query development. VeriSimDB controls are front-and-centre.",
  version = "1.0.0",
  base = 'DatabaseDesign,

  # Pane-L 30%: VQL-DT query builder, type definitions, constraint editing
  # Pane-N 20%: Neural stream, drift alerts, normalisation suggestions
  # Pane-W 50%: Entity browser, query results, drift heatmap, telemetry
  pane_l_size = 30,
  pane_n_size = 20,
  pane_w_size = 50,

  # VeriSimDB is the primary tool — always expanded
  verisimdb_panel = 'Expanded,
  # ECHIDNA for schema invariant proofs — available but secondary
  echidna_panel = 'Collapsed,
  # Security for database stress-testing — available but secondary
  security_panel = 'Collapsed,

  # Provers for data integrity: SMT first (constraint solving), then tactic
  default_provers = ['Z3, 'Coq, 'Lean4],

  # VQL-DT (VeriSimDB Query Language with Dependent Types)
  default_notation = "vql-dt",

  # Database-centric toolbar
  promoted_actions = [
    "query",
    "browse-entities",
    "check-drift",
    "normalise",
    "telemetry",
  ],
} in

{
  pedigree = LayoutPedigree & {
    metadata = {
      name = "panll-layout-database-design",
      description = layout.description,
    },
  },
  layout,
}
