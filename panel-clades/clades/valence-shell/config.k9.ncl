# K9 Kennel: Valence Shell Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "valence-shell-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Valence Shell",
    short_name = "VS",
    description = "Embedded terminal with Claude Code, session recording, reversible ops, and collaborative approval gate",
    has_backend = true,
    clade_id = "valence-shell",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "valenceShell",
    msg_namespace = "valenceShellMsg",
    view_route = "PanelValence Shell",
    module_name = "Valence Shell",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
