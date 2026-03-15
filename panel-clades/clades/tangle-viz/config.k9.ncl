# K9 Kennel: Tangle Viz Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "tangle-viz-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Tangle Viz",
    short_name = "Tangle",
    description = "Topological programming visualizer — braid diagrams, knot invariants, Tangle source parsing",
    has_backend = false,
    clade_id = "tangle-viz",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "tangleViz",
    msg_namespace = "tangleVizMsg",
    view_route = "PanelTangle Viz",
    module_name = "Tangle Viz",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = false,
    requires_clade_manifest = true,
  },
}
