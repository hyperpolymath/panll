K9!
# K9 Kennel: Neurosymbolic Bridge Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "neurosym-bridge-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Neurosymbolic Bridge",
    short_name = "NsB",
    description = "Guard AI behaviour reasoning via ECHIDNA neurosymbolic integration",
    has_backend = true,
    clade_id = "neurosym-bridge",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "neurosymBridge",
    msg_namespace = "neurosymBridgeMsg",
    view_route = "PanelNeurosymbolic Bridge",
    module_name = "Neurosymbolic Bridge",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
  # Resource contract, graded in typed-wasm's grade kernel by
  # src/abi/PanelClades/ABI/Grades.idr.  DESIGNED: declared values for the
  # owner to confirm, not measurements; nothing in the panel runtime emits
  # or checks them yet.  scripts/gen-budgets.sh turns this block into
  # src/abi/PanelClades/ABI/Budgets.idr (one line per record, as below).
  #   state:    occupancy (HWM) — peak live state, state still held at the
  #             end of one inference, and the budget the peak must fit.
  #   crossing: loss on the Panel-N → Panel-W crossing, and its tolerance.
  resources = {
    status = "DESIGNED",
    state = { peak = 48, drift = 16, budget = 64 },
    crossing = { loss = 2, tolerance = 3 },
  },
}
