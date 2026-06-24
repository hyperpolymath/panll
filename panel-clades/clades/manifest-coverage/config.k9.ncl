# K9 Kennel: Manifest Coverage Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "manifest-coverage-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "ManifestCoverage",
    short_name = "MC",
    description = "AI manifest coverage — 0-AI-MANIFEST.a2ml presence across all repos",
    has_backend = false,
    clade_id = "manifest-coverage",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "manifestCoverage",
    msg_namespace = "manifestCoverageMsg",
    view_route = "PanelManifestCoverage",
    module_name = "ManifestCoverage",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = false,
    requires_clade_manifest = true,
  },
}
