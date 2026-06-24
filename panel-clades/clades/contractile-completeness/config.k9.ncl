# K9 Kennel: Contractile Completeness Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: MPL-2.0
{
  pedigree = {
    name = "contractile-completeness-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "ContractileCompleteness",
    short_name = "CC",
    description = "Contractile completeness — Mustfile/Trustfile/Dustfile/K9 coverage",
    has_backend = false,
    clade_id = "contractile-completeness",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "contractileCompleteness",
    msg_namespace = "contractileCompletenessMsg",
    view_route = "PanelContractileCompleteness",
    module_name = "ContractileCompleteness",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = false,
    requires_clade_manifest = true,
  },
}
