# K9 Kennel: CloudGuard Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "cloudguard-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "CloudGuard",
    short_name = "CG",
    description = "Cloudflare domain security management",
    has_backend = true,
    clade_id = "cloudguard",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "cloudGuard",
    msg_namespace = "cloudGuardMsg",
    view_route = "PanelCloudGuard",
    module_name = "CloudGuard",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
