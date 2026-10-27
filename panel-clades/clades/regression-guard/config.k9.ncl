K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Regression Guard Panel Configuration
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
      name = "regression-guard-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Regression Guard",
    short_name = "RG",
    description = "Snapshot comparison and golden-file testing for regressions",
    has_backend = true,
    clade_id = "regression-guard",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "regressionGuard",
    msg_namespace = "regressionGuardMsg",
    view_route = "PanelRegression Guard",
    module_name = "Regression Guard",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
