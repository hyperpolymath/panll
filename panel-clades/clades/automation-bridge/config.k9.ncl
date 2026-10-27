K9!
# SPDX-License-Identifier: MPL-2.0
# K9 Kennel: Automation Bridge Panel Configuration
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
      name = "automation-bridge-config",
      version = "0.1.0",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
    side_effects = [],
  },
  panel = {
    id = "Automation Bridge",
    short_name = "AuB",
    description = "CI/CD pipeline orchestration for game builds and deployment",
    has_backend = true,
    clade_id = "automation-bridge",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "automationBridge",
    msg_namespace = "automationBridgeMsg",
    view_route = "PanelAutomation Bridge",
    module_name = "Automation Bridge",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
