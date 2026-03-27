// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL MenuBar — Standard application menu bar.
///
/// Provides File / Edit / View / Panel / Tools / Help menus following
/// conventional desktop patterns (Notepad++, Visual Paradigm, VS Code).
///
/// Menu items dispatch to the unified msg type via `MenuBar(MenuAction(id))`.
/// The Update module routes these action IDs to the appropriate sub-updaters.
///
/// Interoperability: Menu structure mirrors standard IDE conventions so that
/// users of Visual Paradigm, VS Code, Notepad++, etc. find familiar
/// entry points. Items map to PanLL's unique features behind standard names.

open Model
open Msg
open Tea.Html

// ===========================================================================
// Menu item definitions
// ===========================================================================

/// A single menu item: label, action ID, keyboard shortcut hint (optional).
type rec menuItem =
  | Action(string, string, option<string>) // (label, actionId, shortcut)
  | Separator
  | SubMenu(string, array<menuItem>) // (label, children)

/// File menu items — workspace, import/export, sessions.
let fileMenuItems: array<menuItem> = [
  Action("New Workspace", "file:new-workspace", Some("Ctrl+N")),
  Action("Open Repository...", "file:open-repo", Some("Ctrl+O")),
  Separator,
  Action("Save State", "file:save-state", Some("Ctrl+S")),
  Action("Export ENSAID Config...", "file:export-ensaid", None),
  Action("Export Event Chain...", "file:export-chain", None),
  Separator,
  Action("Import Event Chain...", "file:import-chain", None),
  Action("Import Panic Report...", "file:import-panic", None),
  Separator,
  Action("Print...", "file:print", Some("Ctrl+P")),
  Separator,
  Action("Preferences...", "file:preferences", None),
]

/// Edit menu items — undo/redo, search, clipboard.
let editMenuItems: array<menuItem> = [
  Action("Undo", "edit:undo", Some("Ctrl+Z")),
  Action("Redo", "edit:redo", Some("Ctrl+Shift+Z")),
  Separator,
  Action("Find in Panel...", "edit:find", Some("Ctrl+F")),
  Action("Replace...", "edit:replace", Some("Ctrl+H")),
  Separator,
  Action("Clear Event Chain", "edit:clear-chain", None),
  Action("Reset Panel State", "edit:reset-panel", Some("Ctrl+Shift+R")),
]

/// View menu items — panel visibility, layout, themes.
let viewMenuItems: array<menuItem> = [
  Action("Toggle Panel-L (Symbolic)", "view:toggle-pane-l", Some("Ctrl+Shift+L")),
  Action("Toggle Panel-N (Neural)", "view:toggle-pane-n", Some("Ctrl+Shift+N")),
  Action("Toggle Panel-W (Barycentre)", "view:toggle-pane-w", Some("Ctrl+Shift+B")),
  Separator,
  Action("Toggle Panel Bar", "view:toggle-panel-bar", Some("Ctrl+`")),
  Action("Toggle Topology View", "view:toggle-topology", None),
  Separator,
  Action("Fullscreen", "view:fullscreen", Some("F11")),
  Action("Light Mode", "view:light-mode", None),
  Action("Zen Mode", "view:zen", None),
  Action("Dark Start", "view:dark-start", None),
  Separator,
  Action("Accessibility Settings...", "view:accessibility", None),
]

/// Panel menu items — quick access to key overlay panels.
let panelMenuItems: array<menuItem> = [
  Action("AI Neural Interface", "panel:ai", None),
  Action("VeriSimDB (VAB)", "panel:vab", None),
  Action("CloudGuard", "panel:cloudguard", None),
  Action("Hypatia Scanner", "panel:hypatia", None),
  Action("Repository System", "panel:reposystem", None),
  Separator,
  Action("Editor Bridge (LSP + Modeling)", "panel:editor-bridge", None),
  Action("Build Dashboard", "panel:build-dashboard", None),
  Action("Release Manager", "panel:release-manager", None),
  Separator,
  Action("ECHIDNA (Prover + MOF/OCL)", "panel:echidna", None),
  Action("TypeLL Verifier", "panel:typell", None),
  Action("Interfaces (ABI/FFI)", "panel:interfaces", None),
  Action("Protocol Squisher (XMI/Formats)", "panel:protocol-squisher", None),
  Separator,
  Action("Workspace Settings", "panel:workspace", Some("Ctrl+Shift+K")),
  Action("Capture Tools", "panel:capture", Some("Ctrl+Shift+C")),
  Action("Security", "panel:security", None),
  Action("Bundle of Joy (BoJ)", "panel:boj", None),
  Action("Provenance Map", "panel:provenance", None),
]

/// Tools menu items — analysis, diagnostics, automation, enterprise architecture.
let toolsMenuItems: array<menuItem> = [
  Action("ECHIDNA Theorem Prover", "tools:echidna", None),
  Action("MOF/OCL Model Checker", "tools:mof-ocl", None),
  Action("TSDM Directive", "tools:tsdm", None),
  Separator,
  Action("Panic Attacker", "tools:panic-attack", None),
  Action("Mass Panic (Batch)", "tools:mass-panic", None),
  Separator,
  Action("Clade Browser", "tools:clade-browser", None),
  Action("Protocol Squisher", "tools:protocol-squisher", None),
  Action("7-Tentacles Compiler", "tools:tentacles", None),
  Separator,
  Action("Network Topology", "tools:network-topology", None),
  Action("VM Inspector", "tools:vm-inspector", None),
  Action("Coprocessor Monitor", "tools:coprocessors", None),
  Action("Automation Router", "tools:automation", None),
  Separator,
  Action("Keyboard Shortcuts...", "tools:keybindings", None),
]

/// Help menu items.
let helpMenuItems: array<menuItem> = [
  Action("Welcome Tour", "help:tour", None),
  Action("Glossary", "help:glossary", None),
  Action("Barycentre Tour", "help:barycentre-tour", None),
  Separator,
  Action("About PanLL", "help:about", None),
]

// ===========================================================================
// Rendering
// ===========================================================================

/// Render a single menu item.
let renderMenuItem = (item: menuItem): Tea_Vdom.t<msg> => {
  switch item {
  | Action(label, actionId, shortcut) =>
    button(
      list{
        Attrs.class_(
          "w-full text-left px-3 py-1.5 text-xs text-gray-300 hover:bg-gray-700 hover:text-white flex items-center justify-between gap-4 whitespace-nowrap",
        ),
        Events.onClick(MenuBar(MenuAction(actionId))),
      },
      list{
        span(list{}, list{text(label)}),
        switch shortcut {
        | Some(sc) =>
          span(list{Attrs.class_("text-gray-600 text-[10px] font-mono")}, list{text(sc)})
        | None => noNode
        },
      },
    )
  | Separator => div(list{Attrs.class_("border-t border-gray-700 my-1")}, list{})
  | SubMenu(label, _children) =>
    // Sub-menus rendered as expandable items (simplified — flat for now)
    div(
      list{Attrs.class_("px-3 py-1.5 text-xs text-gray-500 cursor-default")},
      list{text(label ++ " >")},
    )
  }
}

/// Render a dropdown menu panel.
let renderDropdown = (items: array<menuItem>): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_(
        "absolute top-full left-0 mt-0.5 min-w-[220px] bg-gray-900 border border-gray-700 rounded-md shadow-xl shadow-black/40 py-1 z-[9990]",
      ),
    },
    items
    ->Array.map(renderMenuItem)
    ->List.fromArray,
  )
}

/// Render a top-level menu button.
let renderMenuButton = (
  label: string,
  menu: openMenu,
  items: array<menuItem>,
  activeMenu: option<openMenu>,
): Tea_Vdom.t<msg> => {
  let isOpen = activeMenu === Some(menu)
  div(
    list{Attrs.class_("relative")},
    list{
      button(
        list{
          Attrs.class_(
            `px-3 py-1 text-xs transition-colors ${isOpen
                ? "bg-gray-700 text-white"
                : "text-gray-400 hover:bg-gray-800 hover:text-gray-200"}`,
          ),
          Events.onClick(
            if isOpen {
              MenuBar(CloseMenus)
            } else {
              MenuBar(OpenMenu(menu))
            },
          ),
        },
        list{text(label)},
      ),
      if isOpen {
        renderDropdown(items)
      } else {
        noNode
      },
    },
  )
}

/// Main menu bar view — renders as a horizontal bar above the three-panel layout.
let view = (state: menuBarState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_(
        "flex items-center bg-gray-900/90 border-b border-gray-800 h-7 px-1 z-30 relative",
      ),
      Attrs.role("menubar"),
      Attrs.ariaLabel("Application menu"),
    },
    list{
      renderMenuButton("File", MenuFile, fileMenuItems, state.activeMenu),
      renderMenuButton("Edit", MenuEdit, editMenuItems, state.activeMenu),
      renderMenuButton("View", MenuView, viewMenuItems, state.activeMenu),
      renderMenuButton("Panel", MenuPanel, panelMenuItems, state.activeMenu),
      renderMenuButton("Tools", MenuTools, toolsMenuItems, state.activeMenu),
      renderMenuButton("Help", MenuHelp, helpMenuItems, state.activeMenu),
    },
  )
}
