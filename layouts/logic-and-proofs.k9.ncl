# SPDX-License-Identifier: MPL-2.0
# logic-and-proofs.k9.ncl — PanLL discipline layout for formal methods work.
#
# Target audience: Mathematicians, logicians, formal methods researchers,
# students entering the border of maths and logic.
#
# Key insight: These users may be sophisticated in mathematics but unfamiliar
# with tactic-based proof systems, types-as-propositions, or specific prover
# syntax. The visual proof builder is front-and-centre.
#
# Security level: Yard (pure configuration, no I/O)

let { LayoutPreset, LayoutPedigree, PaneSizesSum100, .. } =
  import "./pedigree-layout.ncl" in

let layout | LayoutPreset | PaneSizesSum100 = {
  name = "Logic & Proofs",
  description = "Optimised for theorem proving, formal verification, and mathematical logic. Proof pipeline and tactic suggestions are front-and-centre.",
  version = "1.0.0",
  base = 'LogicAndProofs,

  # Pane-L 35%: Visual proof builder, logical notation palette, goal/hypothesis
  # Pane-N 25%: Tactic suggestions, ECHIDNA advisor monologue, SLM explainer
  # Pane-W 40%: Switchable syntax proof script editor, theorem search, library browser
  pane_l_size = 35,
  pane_n_size = 25,
  pane_w_size = 40,

  # ECHIDNA is the primary tool — always expanded
  echidna_panel = 'Expanded,
  # VeriSimDB available but not the focus
  verisimdb_panel = 'Collapsed,
  # Security tools not relevant for pure proof work
  security_panel = 'Hidden,

  # Prover priority: interactive tactic engines first, then SMT
  default_provers = ['Coq, 'Lean4, 'Isabelle, 'Agda, 'Z3],

  # PanLL-Universal notation with switch to Coq/Lean syntax
  default_notation = "panll-universal",

  # Proof-centric toolbar
  promoted_actions = [
    "new-proof",
    "apply-tactic",
    "suggest",
    "undo-step",
    "qed-check",
  ],
} in

{
  pedigree = LayoutPedigree & {
    metadata = {
      name = "panll-layout-logic-and-proofs",
      description = layout.description,
    },
  },
  layout,
}
