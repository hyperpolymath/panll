# K9 Kennel: Aerie Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "aerie-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Aerie",
    short_name = "Net",
    description = "Network diagnostics and BGP forensics",
    has_backend = true,
    clade_id = "aerie",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "aerie",
    msg_namespace = "aerieMsg",
    view_route = "PanelAerie",
    module_name = "Aerie",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
