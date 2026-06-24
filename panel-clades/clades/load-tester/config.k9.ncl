# K9 Kennel: Load Tester Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "load-tester-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Load Tester",
    short_name = "Load",
    description = "Phoenix channel stress testing, concurrent player simulation",
    has_backend = true,
    clade_id = "load-tester",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "loadTester",
    msg_namespace = "loadTesterMsg",
    view_route = "PanelLoad Tester",
    module_name = "Load Tester",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
