# K9 Kennel: Migration Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "migration-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Migration",
    short_name = "Mig",
    description = "ReScript Migration Observatory — health tracking, sessions, submissions, merge resolver",
    has_backend = true,
    clade_id = "migration",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "migration",
    msg_namespace = "migrationMsg",
    view_route = "PanelMigration",
    module_name = "Migration",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
