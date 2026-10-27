K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Verification Dashboard Panel Configuration
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
      name = "verification-dashboard-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Verification Dashboard",
    short_name = "Verify",
    description = "Proof/test/benchmark/fuzzing status across all nextgen-languages repos",
    has_backend = false,
    clade_id = "verification-dashboard",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "verificationDashboard",
    msg_namespace = "verificationDashboardMsg",
    view_route = "PanelVerification Dashboard",
    module_name = "Verification Dashboard",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = false,
    requires_clade_manifest = true,
  },
}
