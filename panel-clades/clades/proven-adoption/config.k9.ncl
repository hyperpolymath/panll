K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Proven Adoption Panel Configuration
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
      name = "proven-adoption-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "ProvenAdoption",
    short_name = "PrA",
    description = "Proven library adoption — which repos use formally verified safety primitives",
    has_backend = false,
    clade_id = "proven-adoption",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "provenAdoption",
    msg_namespace = "provenAdoptionMsg",
    view_route = "PanelProvenAdoption",
    module_name = "ProvenAdoption",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = false,
    requires_clade_manifest = true,
  },
}
