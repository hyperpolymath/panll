K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Code Review Panel Configuration
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
      name = "code-review-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Code Review",
    short_name = "CR",
    description = "Pull request review, inline comments, file changes, and approval gates",
    has_backend = true,
    clade_id = "code-review",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "codeReview",
    msg_namespace = "codeReviewMsg",
    view_route = "PanelCode Review",
    module_name = "Code Review",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
