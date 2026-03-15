# K9 Kennel: Palimpsest Plaza Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "plaza-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Palimpsest Plaza",
    short_name = "PMPL",
    description = "PMPL license adoption, compliance, and governance hub",
    has_backend = false,
    clade_id = "plaza",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "palimpsestPlaza",
    msg_namespace = "palimpsestPlazaMsg",
    view_route = "PanelPalimpsest Plaza",
    module_name = "Palimpsest Plaza",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = false,
    requires_clade_manifest = true,
  },
}
