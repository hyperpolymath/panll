# K9 Kennel: TypeLL Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "typell-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "TypeLL",
    short_name = "TypeLL",
    description = "Verification kernel — dependent, linear, affine, session, and refinement types with progressive disclosure and cross-panel type intelligence",
    has_backend = true,
    clade_id = "typell",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "typeLL",
    msg_namespace = "typeLLMsg",
    view_route = "PanelTypeLL",
    module_name = "TypeLL",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
