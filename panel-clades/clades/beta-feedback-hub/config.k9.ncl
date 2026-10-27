K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Beta Feedback Hub Panel Configuration
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
      name = "beta-feedback-hub-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Beta Feedback Hub",
    short_name = "Beta",
    description = "Feedback-o-tron integration, sentiment analysis, triage queue",
    has_backend = true,
    clade_id = "beta-feedback-hub",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "betaFeedbackHub",
    msg_namespace = "betaFeedbackHubMsg",
    view_route = "PanelBeta Feedback Hub",
    module_name = "Beta Feedback Hub",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
