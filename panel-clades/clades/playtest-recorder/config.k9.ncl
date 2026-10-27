K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Playtest Recorder Panel Configuration
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
      name = "playtest-recorder-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Playtest Recorder",
    short_name = "Play",
    description = "Record and replay game sessions, annotate key moments",
    has_backend = true,
    clade_id = "playtest-recorder",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "playtestRecorder",
    msg_namespace = "playtestRecorderMsg",
    view_route = "PanelPlaytest Recorder",
    module_name = "Playtest Recorder",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
