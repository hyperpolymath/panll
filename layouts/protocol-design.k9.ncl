K9!
# SPDX-License-Identifier: MPL-2.0
# protocol-design.k9.ncl — PanLL discipline layout for protocol work.
#
# Target audience: Network protocol designers, distributed systems engineers,
# people working on Axel Protocol, TPCF, or similar specifications.
#
# Key insight: These users need to verify protocol properties (liveness,
# safety, deadlock freedom), model state machines, check message format
# correctness, and reason about concurrency. Many may not come from a
# formal methods background and need protocol-specific vocabulary.
#
# Security level: Yard (pure configuration, no I/O)

let { LayoutPreset, PaneSizesSum100, .. } =
  import "./pedigree-layout.ncl" in

let preset | LayoutPreset | PaneSizesSum100 = {
  name = "Protocol Design",
  description = "Optimised for protocol specification, state machine modelling, liveness/safety verification, and message flow analysis. Model checking and protocol fuzzing are front-and-centre.",
  version = "1.0.0",
  base = 'ProtocolDesign,

  # Pane-L 35%: State machine editor, protocol invariants, message format specs
  # Pane-N 25%: Neural stream, protocol analysis suggestions, deadlock warnings
  # Pane-W 40%: Message flow diagram, simulation runner, test harness
  pane_l_size = 35,
  pane_n_size = 25,
  pane_w_size = 40,

  # ECHIDNA for model checking / liveness proofs — always expanded
  echidna_panel = 'Expanded,
  # VeriSimDB for protocol trace storage — available but secondary
  verisimdb_panel = 'Collapsed,
  # Security for protocol fuzzing — expanded (important for protocol work)
  security_panel = 'Expanded,

  # Protocol verification: model checkers first, then tactic engines
  default_provers = ['Z3, 'TLAPlus, 'Spin, 'Isabelle],

  # Temporal logic notation (box, diamond, until)
  default_notation = "temporal-logic",

  # Protocol-centric toolbar
  promoted_actions = [
    "define-state",
    "add-transition",
    "check-liveness",
    "simulate",
    "fuzz",
  ],
} in

{
  pedigree = {
    schema_version = "1.0.0",
    component_type = "panll-layout-preset",
    security = {
      leash = 'Yard,
      trust_level = "contract-eval-only",
      allow_network = false,
      allow_filesystem_write = false,
      allow_subprocess = false,
      capabilities = [],
    },
    metadata = {
      name = "panll-layout-protocol-design",
      version = preset.version,
      description = preset.description,
      breed = "application/vnd.k9+nickel",
    },
    side_effects = [],
  },
  layout = preset,
}
