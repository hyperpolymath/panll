# K9 Kennel: Code Review Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "code-review-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
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
