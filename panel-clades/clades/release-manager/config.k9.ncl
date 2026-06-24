# K9 Kennel: Release Manager Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "release-manager-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Release Manager",
    short_name = "Rel",
    description = "Versioning, changelog, artifact building, signing, and distribution of IDApTIK builds",
    has_backend = true,
    clade_id = "release-manager",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "releaseManager",
    msg_namespace = "releaseManagerMsg",
    view_route = "PanelRelease Manager",
    module_name = "Release Manager",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
