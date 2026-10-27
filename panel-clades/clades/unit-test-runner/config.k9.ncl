K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Unit Test Runner Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
{
  pedigree = {
    schema_version = "1.0.0",
    component_type = "panel-clade-config",
    security = {
      leash = 'Kennel,
      trust_level = "data-only",
      allow_network = false,
      allow_filesystem_write = false,
      allow_subprocess = false,
      capabilities = [],
    },
    metadata = {
      name = "unit-test-runner-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
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
