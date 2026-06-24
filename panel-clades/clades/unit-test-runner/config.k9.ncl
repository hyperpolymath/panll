# K9 Kennel: Unit Test Runner Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "unit-test-runner-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Unit Test Runner",
    short_name = "UTR",
    description = "ReScript test execution, coverage heatmap, diff-aware testing",
    has_backend = true,
    clade_id = "unit-test-runner",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "unitTestRunner",
    msg_namespace = "unitTestRunnerMsg",
    view_route = "PanelUnit Test Runner",
    module_name = "Unit Test Runner",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
