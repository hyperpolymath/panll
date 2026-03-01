# SPDX-License-Identifier: PMPL-1.0-or-later
# language-design.k9.ncl — PanLL discipline layout for programming language work.
#
# Target audience: Language designers, compiler writers, people building or
# extending Eclexia, AffineScript, BetLang, or similar languages.
#
# Key insight: These users need to verify type system properties, prove
# compiler transformations correct, test parser grammars, and browse ASTs.
# The proof engine is heavily used but through a language-design lens
# (metatheory, not end-user proofs).
#
# Security level: Yard (pure configuration, no I/O)

let { LayoutPreset, LayoutPedigree, PaneSizesSum100, .. } =
  import "./pedigree-layout.ncl" in

let layout | LayoutPreset | PaneSizesSum100 = {
  name = "Language Design",
  description = "Optimised for programming language design, type system verification, parser testing, and AST browsing. Metatheory proofs and grammar tools are front-and-centre.",
  version = "1.0.0",
  base = 'LanguageDesign,

  # Pane-L 40%: Type rule editor, grammar/BNF viewer, metatheory goals
  # Pane-N 25%: Neural stream, type inference trace, compilation suggestions
  # Pane-W 35%: AST browser, test case runner, example program editor
  pane_l_size = 40,
  pane_n_size = 25,
  pane_w_size = 35,

  # ECHIDNA for metatheory proofs — always expanded
  echidna_panel = 'Expanded,
  # VeriSimDB not typically needed for language design
  verisimdb_panel = 'Hidden,
  # Security for parser fuzzing — available but secondary
  security_panel = 'Collapsed,

  # Metatheory-focused provers: interactive tactic engines only
  default_provers = ['Coq, 'Lean4, 'Agda],

  # Higher-order logic / dependent types notation
  default_notation = "higher-order-logic",

  # Language-design-centric toolbar
  promoted_actions = [
    "define-rule",
    "check-metatheory",
    "parse-example",
    "run-evaluator",
  ],
} in

{
  pedigree = LayoutPedigree & {
    metadata = {
      name = "panll-layout-language-design",
      description = layout.description,
    },
  },
  layout,
}
