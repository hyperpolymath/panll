// SPDX-License-Identifier: MPL-2.0

/// PanLL KeyboardNav — composable keyboard navigation handlers for panels.
///
/// Provides standard keyboard interaction patterns that components can compose
/// into their event attributes. Follows WAI-ARIA Authoring Practices:
///   - Enter/Space activates buttons
///   - Arrow keys navigate lists and tab bars
///   - Escape closes overlays/modals
///   - Home/End jump to first/last item
///
/// Usage in components:
///   button(list{
///     Events.onClick(MyAction),
///     KeyboardNav.onActivate(MyAction),   // Enter + Space
///     Attrs.tabIndex(0),
///   }, list{text("Click me")})
///
/// All functions are pure — they return event attributes, not side effects.

open Tea_Vdom
open Tea_Html

/// Key string constants for readability.
module Key = {
  let enter = "Enter"
  let space = " "
  let escape = "Escape"
  let arrowUp = "ArrowUp"
  let arrowDown = "ArrowDown"
  let arrowLeft = "ArrowLeft"
  let arrowRight = "ArrowRight"
  let home = "Home"
  let end_ = "End"
  let tab = "Tab"
}

/// Dispatch a message when Enter or Space is pressed (button activation pattern).
let onActivate = (msg: 'msg): attribute<'msg> =>
  Events.onKeyDown(key =>
    if key === Key.enter || key === Key.space {
      Some(msg)
    } else {
      None
    }
  )

/// Dispatch a message when Escape is pressed (close/dismiss pattern).
let onEscape = (msg: 'msg): attribute<'msg> =>
  Events.onKeyDown(key =>
    if key === Key.escape {
      Some(msg)
    } else {
      None
    }
  )

/// Dispatch messages for vertical arrow navigation (list/menu pattern).
let onVerticalNav = (~onUp: 'msg, ~onDown: 'msg): attribute<'msg> =>
  Events.onKeyDown(key =>
    if key === Key.arrowUp {
      Some(onUp)
    } else if key === Key.arrowDown {
      Some(onDown)
    } else {
      None
    }
  )

/// Dispatch messages for horizontal arrow navigation (tab bar pattern).
let onHorizontalNav = (~onLeft: 'msg, ~onRight: 'msg): attribute<'msg> =>
  Events.onKeyDown(key =>
    if key === Key.arrowLeft {
      Some(onLeft)
    } else if key === Key.arrowRight {
      Some(onRight)
    } else {
      None
    }
  )

/// Dispatch messages for Home/End navigation (jump to first/last).
let onHomeEnd = (~onHome: 'msg, ~onEnd: 'msg): attribute<'msg> =>
  Events.onKeyDown(key =>
    if key === Key.home {
      Some(onHome)
    } else if key === Key.end_ {
      Some(onEnd)
    } else {
      None
    }
  )

/// Combined list navigation: ArrowUp/Down + Home/End + Enter to select + Escape to dismiss.
/// Useful for dropdown menus, comboboxes, listboxes.
let onListNav = (
  ~onUp: 'msg,
  ~onDown: 'msg,
  ~onHome: 'msg,
  ~onEnd: 'msg,
  ~onSelect: 'msg,
  ~onDismiss: 'msg,
): attribute<'msg> =>
  Events.onKeyDown(key =>
    if key === Key.arrowUp {
      Some(onUp)
    } else if key === Key.arrowDown {
      Some(onDown)
    } else if key === Key.home {
      Some(onHome)
    } else if key === Key.end_ {
      Some(onEnd)
    } else if key === Key.enter || key === Key.space {
      Some(onSelect)
    } else if key === Key.escape {
      Some(onDismiss)
    } else {
      None
    }
  )

/// Helper: make a focusable div container (tabIndex 0).
let focusable: attribute<'msg> = Attrs.tabIndex(0)

/// Helper: programmatically focusable but not in tab order (tabIndex -1).
let focusableHidden: attribute<'msg> = Attrs.tabIndex(-1)

/// Helper: screen reader only text (visually hidden but announced).
let srOnly = (label: string): Tea_Vdom.t<'msg> =>
  span(
    list{Attrs.class_("sr-only")},
    list{text(label)},
  )

/// Helper: aria-live polite region wrapper (for status updates).
let livePolite = (children: list<Tea_Vdom.t<'msg>>): Tea_Vdom.t<'msg> =>
  div(list{Attrs.ariaLive("polite")}, children)

/// Helper: aria-live assertive region wrapper (for errors/alerts).
let liveAssertive = (children: list<Tea_Vdom.t<'msg>>): Tea_Vdom.t<'msg> =>
  div(list{Attrs.ariaLive("assertive")}, children)

/// Bundle: onClick + keyboard activation + tabIndex in one call.
/// Use instead of bare Events.onClick for all interactive elements.
/// This is the primary entry point for keyboard accessibility.
let clickable = (msg: 'msg): list<attribute<'msg>> =>
  list{Events.onClick(msg), onActivate(msg), Attrs.tabIndex(0)}
