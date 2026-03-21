# K9 Kennel: Feedback Routing Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "feedback-routing-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "FeedbackRouting",
    short_name = "FBR",
    description = "Feedback-o-Tron routing — upstream bug report status and integration map",
    has_backend = true,
    clade_id = "feedback-routing",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "feedbackRouting",
    msg_namespace = "feedbackRoutingMsg",
    view_route = "PanelFeedbackRouting",
    module_name = "FeedbackRouting",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
