# K9 Kennel: Universal Modding Studio Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "ums-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Universal Modding Studio",
    short_name = "UMS",
    description = "Unified hub for IDApTIK game content creation — project management, ABI validation, asset pipeline, mod distribution",
    has_backend = true,
    clade_id = "ums",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "ums",
    msg_namespace = "umsMsg",
    view_route = "PanelUniversal Modding Studio",
    module_name = "Universal Modding Studio",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
