# K9 Kennel: Guard AI Tuner Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "guard-ai-tuner-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Guard AI Tuner",
    short_name = "GAI",
    description = "Guard patrol paths, alert thresholds, spawn rate tuning",
    has_backend = true,
    clade_id = "guard-ai-tuner",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "guardAiTuner",
    msg_namespace = "guardAiTunerMsg",
    view_route = "PanelGuard AI Tuner",
    module_name = "Guard AI Tuner",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
