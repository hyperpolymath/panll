# SPDX-License-Identifier: PMPL-1.0-or-later
# K9 Yard Validator: Wiring Completeness
#
# Validates all 7 wiring points from the Panel Contract Compiler (PCC).
# A panel is not fully integrated until every wiring point is connected.
# The PCC checks these automatically, but this validator provides a
# declarative contract for the K9 system.
#
# The 7 wiring points:
#   1. Registry entry     — src/registry/PanelRegistry.res
#   2. Model include      — src/model/Model.res (variant in state union)
#   3. Msg namespace      — src/model/Msg.res (variant in message union)
#   4. View route         — src/View.res (pattern match branch)
#   5. Update handler     — src/Update.res (sub-updater dispatch)
#   6. Rust registration  — src-tauri/src/main.rs (command handler, if backend)
#   7. Init subscription  — src/model/Model.res init (if panel has subscriptions)
#
# Pedigree:
#   Name:    wiring-completeness
#   Version: 0.1.0
#   Author:  Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#   Leash:   Yard (read-only validation, no side effects)

let WiringCheck = {
  # The panel identifier (PascalCase, e.g. "FileExplorer").
  panel_id
    | String
    | doc "Panel identifier in PascalCase",

  # --- Wiring point booleans ---

  # 1. PanelRegistry.res contains an entry for this panel.
  registry_entry
    | Bool
    | doc "Panel is registered in PanelRegistry.res",

  # 2. Model.res state union includes this panel's model type.
  model_include
    | Bool
    | doc "Panel model is included in the root Model.res state union",

  # 3. Msg.res message union includes this panel's message namespace.
  msg_namespace
    | Bool
    | doc "Panel messages are wired into the root Msg.res union",

  # 4. View.res has a pattern match branch rendering this panel.
  view_route
    | Bool
    | doc "Panel view is routed in the root View.res",

  # 5. Update.res dispatches messages to this panel's engine.
  update_handler
    | Bool
    | doc "Panel update handler is dispatched in the root Update.res",

  # 6. Rust command registration (only applicable if panel has a backend).
  rust_registration
    | Bool
    | optional
    | doc "Tauri commands are registered in main.rs (backend panels only)",

  # 7. Init subscription wiring (only applicable if panel has subscriptions).
  init_subscription
    | Bool
    | optional
    | doc "Panel subscriptions are wired in Model.res init",

  # --- Computed validation ---

  # Core wiring: the 5 mandatory wiring points.
  core_wired
    | Bool
    | default = registry_entry && model_include && msg_namespace && view_route && update_handler
    | doc "True when all 5 mandatory wiring points are connected",

  # Full wiring: core + optional points (if applicable).
  all_wired
    | Bool
    | default = core_wired
        && (rust_registration == null || rust_registration == true)
        && (init_subscription == null || init_subscription == true)
    | doc "True when all applicable wiring points are connected",

  # Count of connected wiring points (for progress reporting).
  wired_count
    | Number
    | default =
        (if registry_entry then 1 else 0)
        + (if model_include then 1 else 0)
        + (if msg_namespace then 1 else 0)
        + (if view_route then 1 else 0)
        + (if update_handler then 1 else 0)
        + (if rust_registration == true then 1 else 0)
        + (if init_subscription == true then 1 else 0)
    | doc "Number of wiring points currently connected",
}
in

WiringCheck
