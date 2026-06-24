// SPDX-License-Identifier: MPL-2.0

/// PanLL MenuBarModel — State for the standard application menu bar.
///
/// Provides File / Edit / View / Panel / Tools / Help menus following
/// conventional desktop application patterns (Notepad++, Visual Paradigm,
/// VS Code). Designed for interoperability with IDE-class applications.

/// Which top-level menu is currently open (None = all closed).
type openMenu =
  | MenuFile
  | MenuEdit
  | MenuView
  | MenuPanel
  | MenuTools
  | MenuHelp

/// Menu bar state
type menuBarState = {
  /// Currently open dropdown menu (None = all menus closed).
  activeMenu: option<openMenu>,
}
