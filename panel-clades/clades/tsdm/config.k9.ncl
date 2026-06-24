# K9 Kennel: TSDM Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "tsdm-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "TSDM",
    short_name = "TSD",
    description = "Triaxial Software Development Methodology — directive panel for priority ordering across all panels",
    has_backend = false,
    clade_id = "tsdm",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "tsdm",
    msg_namespace = "tsdmMsg",
    view_route = "PanelTSDM",
    module_name = "TSDM",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = false,
    requires_clade_manifest = true,
  },
}
