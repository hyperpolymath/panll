// SPDX-License-Identifier: PMPL-1.0-or-later

/// Menu bar messages -- standard application menu interactions.

open Model

type menuBarMsg =
  /// Open a specific top-level menu dropdown.
  | OpenMenu(openMenu)
  /// Close all menu dropdowns.
  | CloseMenus
  /// Menu item actions (dispatched from menu items, routed to appropriate sub-updaters).
  | MenuAction(string)
