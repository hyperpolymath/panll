# K9 Kennel: Security Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "security-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Security",
    short_name = "Sec",
    description = "Secrets redaction, vault, 2FA, Trustfile enforcement, shoulder-safe mode",
    has_backend = true,
    clade_id = "security",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "security",
    msg_namespace = "securityMsg",
    view_route = "PanelSecurity",
    module_name = "Security",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
