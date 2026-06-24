# K9 Kennel: Regression Guard Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "regression-guard-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
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
