// SPDX-License-Identifier: MPL-2.0

/// Menu bar messages -- standard application menu interactions.

open Model

type menuBarMsg =
  /// Open a specific top-level menu dropdown.
  | OpenMenu(openMenu)
  /// Close all menu dropdowns.
  | CloseMenus
  /// Menu item actions (dispatched from menu items, routed to appropriate sub-updaters).
  | MenuAction(string)
