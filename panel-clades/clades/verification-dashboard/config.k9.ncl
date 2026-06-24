# K9 Kennel: Verification Dashboard Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "verification-dashboard-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
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
