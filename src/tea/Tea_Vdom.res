// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// Tea_Vdom.res — Core virtual DOM for The Elm Architecture in ReScript.
//
// Supports: elements, text nodes, keyed elements (efficient list diffing),
// fragments (avoid wrapper divs), and a comprehensive attribute/event system.

/// Attribute types for virtual DOM elements
type rec attribute<'msg> =
  | Property(string, string)
  | Style(string, string)
  | Event(string, unit => 'msg)
  | EventWithValue(string, string => 'msg)
  | EventWithKey(string, string => option<'msg>)
  | EventPreventDefault(string, unit => 'msg)
  | EventStopPropagation(string, unit => 'msg)

/// Virtual DOM node type
///
/// - Text: plain text node
/// - Element: standard HTML/SVG element with positional children
/// - KeyedElement: element with keyed children for O(n) list reordering
/// - Fragment: renders children without a wrapper element
type rec t<'msg> =
  | Text(string)
  | Element(string, array<attribute<'msg>>, array<t<'msg>>)
  | KeyedElement(string, array<attribute<'msg>>, array<(string, t<'msg>)>)
  | Fragment(array<t<'msg>>)

// ── Node constructors ──────────────────────────────────────────────

/// Create a text node
let text = (s: string): t<'msg> => Text(s)

/// Create an element node from lists (original API, backwards-compatible)
let node = (tag: string, attrs: list<attribute<'msg>>, children: list<t<'msg>>): t<'msg> => {
  Element(tag, List.toArray(attrs), List.toArray(children))
}

/// Create an element node from arrays (faster, avoids list→array conversion)
let nodeA = (tag: string, attrs: array<attribute<'msg>>, children: array<t<'msg>>): t<'msg> => {
  Element(tag, attrs, children)
}

/// Create a keyed element node for efficient list diffing.
/// Each child has a unique string key. When the list is reordered,
/// the renderer moves DOM nodes instead of recreating them.
let keyed = (
  tag: string,
  attrs: list<attribute<'msg>>,
  children: list<(string, t<'msg>)>,
): t<'msg> => {
  KeyedElement(tag, List.toArray(attrs), List.toArray(children))
}

/// Create a keyed element from arrays (faster, avoids list→array conversion)
let keyedA = (
  tag: string,
  attrs: array<attribute<'msg>>,
  children: array<(string, t<'msg>)>,
): t<'msg> => {
  KeyedElement(tag, attrs, children)
}

/// Create a fragment that renders its children without a wrapper element
let fragment = (children: list<t<'msg>>): t<'msg> => {
  Fragment(List.toArray(children))
}

/// Create a fragment from an array
let fragmentA = (children: array<t<'msg>>): t<'msg> => {
  Fragment(children)
}

// ── Attribute constructors ─────────────────────────────────────────

/// A no-op attribute that renders nothing — use where a conditional
/// attribute is needed but the else branch has no attribute to apply.
let noProp: attribute<'msg> = Property("", "")

/// Generic property setter for attributes not covered by named helpers.
let prop = (key: string, value: string): attribute<'msg> => Property(key, value)

// Basic attributes
let class_ = (name: string): attribute<'msg> => Property("class", name)
let id = (name: string): attribute<'msg> => Property("id", name)
let style = (prop: string, value: string): attribute<'msg> => Style(prop, value)
let placeholder = (text: string): attribute<'msg> => Property("placeholder", text)
let value = (v: string): attribute<'msg> => Property("value", v)
let title = (t: string): attribute<'msg> => Property("title", t)
let href = (url: string): attribute<'msg> => Property("href", url)
let src = (url: string): attribute<'msg> => Property("src", url)
let alt = (text: string): attribute<'msg> => Property("alt", text)
let disabled = (b: bool): attribute<'msg> => Property("disabled", b ? "true" : "false")
let checked = (b: bool): attribute<'msg> => Property("checked", b ? "true" : "false")
let type_ = (t: string): attribute<'msg> => Property("type", t)
let name = (n: string): attribute<'msg> => Property("name", n)
let tabIndex = (i: int): attribute<'msg> => Property("tabindex", Int.toString(i))

// Form attributes
let for_ = (id: string): attribute<'msg> => Property("for", id)
let required = (b: bool): attribute<'msg> => Property("required", b ? "true" : "false")
let readonly = (b: bool): attribute<'msg> => Property("readonly", b ? "true" : "false")
let autofocus = (b: bool): attribute<'msg> => Property("autofocus", b ? "true" : "false")
let autocomplete = (v: string): attribute<'msg> => Property("autocomplete", v)
let pattern = (p: string): attribute<'msg> => Property("pattern", p)
let multiple = (b: bool): attribute<'msg> => Property("multiple", b ? "true" : "false")
let accept = (v: string): attribute<'msg> => Property("accept", v)
let min = (v: string): attribute<'msg> => Property("min", v)
let max = (v: string): attribute<'msg> => Property("max", v)
let step = (v: string): attribute<'msg> => Property("step", v)
let maxLength = (n: int): attribute<'msg> => Property("maxlength", Int.toString(n))
let minLength = (n: int): attribute<'msg> => Property("minlength", Int.toString(n))
let action = (url: string): attribute<'msg> => Property("action", url)
let method = (m: string): attribute<'msg> => Property("method", m)
let cols = (n: int): attribute<'msg> => Property("cols", Int.toString(n))
let rows = (n: int): attribute<'msg> => Property("rows", Int.toString(n))
let noValidate = (b: bool): attribute<'msg> => Property("novalidate", b ? "true" : "false")

// Media/embed attributes
let width = (v: string): attribute<'msg> => Property("width", v)
let height = (v: string): attribute<'msg> => Property("height", v)
let target = (t: string): attribute<'msg> => Property("target", t)
let download = (v: string): attribute<'msg> => Property("download", v)
let rel = (r: string): attribute<'msg> => Property("rel", r)
let hidden = (b: bool): attribute<'msg> => Property("hidden", b ? "true" : "false")

// Interaction attributes
let draggable = (b: bool): attribute<'msg> => Property("draggable", b ? "true" : "false")
let contentEditable = (b: bool): attribute<'msg> => Property("contenteditable", b ? "true" : "false")
let spellCheck = (b: bool): attribute<'msg> => Property("spellcheck", b ? "true" : "false")

// Table attributes
let colspan = (n: int): attribute<'msg> => Property("colspan", Int.toString(n))
let rowspan = (n: int): attribute<'msg> => Property("rowspan", Int.toString(n))

// Data attributes — data_("key", "val") renders as data-key="val"
let data_ = (key: string, value: string): attribute<'msg> => Property("data-" ++ key, value)

// ARIA accessibility attributes
let ariaLabel = (label: string): attribute<'msg> => Property("aria-label", label)
let ariaLive = (mode: string): attribute<'msg> => Property("aria-live", mode)
let ariaExpanded = (b: bool): attribute<'msg> => Property("aria-expanded", b ? "true" : "false")
let ariaHidden = (b: bool): attribute<'msg> => Property("aria-hidden", b ? "true" : "false")
let ariaPressed = (b: bool): attribute<'msg> => Property("aria-pressed", b ? "true" : "false")
let ariaCurrent = (v: string): attribute<'msg> => Property("aria-current", v)
let ariaValueNow = (v: float): attribute<'msg> => Property("aria-valuenow", Float.toString(v))
let ariaValueMin = (v: float): attribute<'msg> => Property("aria-valuemin", Float.toString(v))
let ariaValueMax = (v: float): attribute<'msg> => Property("aria-valuemax", Float.toString(v))
let ariaDescribedBy = (id: string): attribute<'msg> => Property("aria-describedby", id)
let ariaChecked = (b: bool): attribute<'msg> => Property("aria-checked", b ? "true" : "false")
let ariaSelected = (b: bool): attribute<'msg> => Property("aria-selected", b ? "true" : "false")
let ariaControls = (id: string): attribute<'msg> => Property("aria-controls", id)
let ariaLabelledBy = (id: string): attribute<'msg> => Property("aria-labelledby", id)
let ariaRequired = (b: bool): attribute<'msg> => Property("aria-required", b ? "true" : "false")
let ariaInvalid = (b: bool): attribute<'msg> => Property("aria-invalid", b ? "true" : "false")
let ariaDisabled = (b: bool): attribute<'msg> => Property("aria-disabled", b ? "true" : "false")
let ariaSort = (v: string): attribute<'msg> => Property("aria-sort", v)
let ariaOrientation = (v: string): attribute<'msg> => Property("aria-orientation", v)
let ariaModal = (b: bool): attribute<'msg> => Property("aria-modal", b ? "true" : "false")
let role = (r: string): attribute<'msg> => Property("role", r)
let selected = (b: bool): attribute<'msg> => Property("selected", b ? "true" : "false")

// ── Event handlers ─────────────────────────────────────────────────

// Mouse events
let onClick = (msg: 'msg): attribute<'msg> => Event("click", () => msg)
let onDoubleClick = (msg: 'msg): attribute<'msg> => Event("dblclick", () => msg)
let onContextMenu = (msg: 'msg): attribute<'msg> => EventPreventDefault("contextmenu", () => msg)
let onMouseDown = (msg: 'msg): attribute<'msg> => Event("mousedown", () => msg)
let onMouseUp = (msg: 'msg): attribute<'msg> => Event("mouseup", () => msg)
let onMouseEnter = (msg: 'msg): attribute<'msg> => Event("mouseenter", () => msg)
let onMouseLeave = (msg: 'msg): attribute<'msg> => Event("mouseleave", () => msg)
let onMouseOver = (msg: 'msg): attribute<'msg> => Event("mouseover", () => msg)
let onMouseOut = (msg: 'msg): attribute<'msg> => Event("mouseout", () => msg)

// Pointer events (unified mouse/touch/pen)
let onPointerDown = (msg: 'msg): attribute<'msg> => Event("pointerdown", () => msg)
let onPointerUp = (msg: 'msg): attribute<'msg> => Event("pointerup", () => msg)
let onPointerMove = (msg: 'msg): attribute<'msg> => Event("pointermove", () => msg)
let onPointerEnter = (msg: 'msg): attribute<'msg> => Event("pointerenter", () => msg)
let onPointerLeave = (msg: 'msg): attribute<'msg> => Event("pointerleave", () => msg)
let onPointerCancel = (msg: 'msg): attribute<'msg> => Event("pointercancel", () => msg)

// Touch events
let onTouchStart = (msg: 'msg): attribute<'msg> => Event("touchstart", () => msg)
let onTouchEnd = (msg: 'msg): attribute<'msg> => Event("touchend", () => msg)
let onTouchMove = (msg: 'msg): attribute<'msg> => Event("touchmove", () => msg)
let onTouchCancel = (msg: 'msg): attribute<'msg> => Event("touchcancel", () => msg)

// Form events
let onInput = (handler: string => 'msg): attribute<'msg> => EventWithValue("input", handler)
let onChange = (handler: string => 'msg): attribute<'msg> => EventWithValue("change", handler)
let onSubmit = (msg: 'msg): attribute<'msg> => EventPreventDefault("submit", () => msg)
let onReset = (msg: 'msg): attribute<'msg> => Event("reset", () => msg)

// Focus events
let onFocus = (msg: 'msg): attribute<'msg> => Event("focus", () => msg)
let onBlur = (msg: 'msg): attribute<'msg> => Event("blur", () => msg)

// Keyboard events
let onKeyDown = (handler: string => option<'msg>): attribute<'msg> => EventWithKey("keydown", handler)
let onKeyUp = (handler: string => option<'msg>): attribute<'msg> => EventWithKey("keyup", handler)
let onKeyPress = (handler: string => option<'msg>): attribute<'msg> => EventWithKey("keypress", handler)

// Drag and drop events
let onDragStart = (msg: 'msg): attribute<'msg> => Event("dragstart", () => msg)
let onDrag = (msg: 'msg): attribute<'msg> => Event("drag", () => msg)
let onDragEnd = (msg: 'msg): attribute<'msg> => Event("dragend", () => msg)
let onDragEnter = (msg: 'msg): attribute<'msg> => Event("dragenter", () => msg)
let onDragLeave = (msg: 'msg): attribute<'msg> => Event("dragleave", () => msg)
let onDragOver = (msg: 'msg): attribute<'msg> => EventPreventDefault("dragover", () => msg)
let onDrop = (msg: 'msg): attribute<'msg> => EventPreventDefault("drop", () => msg)

// Scroll events
let onScroll = (msg: 'msg): attribute<'msg> => Event("scroll", () => msg)

// Animation/transition events
let onAnimationEnd = (msg: 'msg): attribute<'msg> => Event("animationend", () => msg)
let onAnimationStart = (msg: 'msg): attribute<'msg> => Event("animationstart", () => msg)
let onTransitionEnd = (msg: 'msg): attribute<'msg> => Event("transitionend", () => msg)

// Clipboard events
let onCopy = (msg: 'msg): attribute<'msg> => Event("copy", () => msg)
let onCut = (msg: 'msg): attribute<'msg> => Event("cut", () => msg)
let onPaste = (msg: 'msg): attribute<'msg> => Event("paste", () => msg)

// Wheel event
let onWheel = (msg: 'msg): attribute<'msg> => Event("wheel", () => msg)

// ── Map functions ──────────────────────────────────────────────────

/// Map the message type of a virtual DOM node
let rec map = (vdom: t<'a>, f: 'a => 'b): t<'b> => {
  switch vdom {
  | Text(s) => Text(s)
  | Element(tag, attrs, children) =>
    Element(
      tag,
      Array.map(attrs, attr => mapAttr(attr, f)),
      Array.map(children, child => map(child, f)),
    )
  | KeyedElement(tag, attrs, keyedChildren) =>
    KeyedElement(
      tag,
      Array.map(attrs, attr => mapAttr(attr, f)),
      Array.map(keyedChildren, ((key, child)) => (key, map(child, f))),
    )
  | Fragment(children) =>
    Fragment(Array.map(children, child => map(child, f)))
  }
}
and mapAttr = (attr: attribute<'a>, f: 'a => 'b): attribute<'b> => {
  switch attr {
  | Property(k, v) => Property(k, v)
  | Style(k, v) => Style(k, v)
  | Event(name, handler) => Event(name, () => f(handler()))
  | EventWithValue(name, handler) => EventWithValue(name, v => f(handler(v)))
  | EventWithKey(name, handler) =>
    EventWithKey(name, key =>
      switch handler(key) {
      | Some(msg) => Some(f(msg))
      | None => None
      }
    )
  | EventPreventDefault(name, handler) => EventPreventDefault(name, () => f(handler()))
  | EventStopPropagation(name, handler) => EventStopPropagation(name, () => f(handler()))
  }
}
