# K9 Kennel: Game Preview Panel Configuration
# Auto-generated from PanelRegistry — pure data, no execution
# SPDX-License-Identifier: PMPL-1.0-or-later
{
  pedigree = {
    name = "game-preview-config",
    version = "0.1.0",
    author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    leash = 'Kennel,
  },
  panel = {
    id = "Game Preview",
    short_name = "Game",
    description = "Live IDApTIK game preview with hot-reload, frame stepping, overlays, and gameplay recording",
    has_backend = true,
    clade_id = "game-preview",
    isolation_tier = "native",
  },
  wiring = {
    model_slice = "gamePreview",
    msg_namespace = "gamePreviewMsg",
    view_route = "PanelGame Preview",
    module_name = "Game Preview",
  },
  obligations = {
    requires_tests = true,
    requires_backend_health = true,
    requires_clade_manifest = true,
  },
}
