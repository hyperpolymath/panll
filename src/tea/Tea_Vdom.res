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
let keyed = (tag: string, attrs: list<attribute<'msg>>, children: list<(string, t<'msg>)>): t<
  'msg,
> => {
  KeyedElement(tag, List.toArray(attrs), List.toArray(children))
}

/// Create a keyed element from arrays (faster, avoids list→array conversion)
let keyedA = (tag: string, attrs: array<attribute<'msg>>, children: array<(string, t<'msg>)>): t<
  'msg,
> => {
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

/// Sets the CSS class attribute.
let class_ = (name: string): attribute<'msg> => Property("class", name)

/// Sets the element id attribute.
let id = (name: string): attribute<'msg> => Property("id", name)

/// Sets an inline CSS style property and value.
let style = (prop: string, value: string): attribute<'msg> => Style(prop, value)

/// Sets the placeholder text for input/textarea elements.
let placeholder = (text: string): attribute<'msg> => Property("placeholder", text)

/// Sets the value attribute.
let value = (v: string): attribute<'msg> => Property("value", v)

/// Sets the title (tooltip) attribute.
let title = (t: string): attribute<'msg> => Property("title", t)

/// Sets the href attribute.
let href = (url: string): attribute<'msg> => Property("href", url)

/// Sets the src attribute.
let src = (url: string): attribute<'msg> => Property("src", url)

/// Sets the alt text attribute.
let alt = (text: string): attribute<'msg> => Property("alt", text)

/// Sets the disabled boolean attribute.
let disabled = (b: bool): attribute<'msg> => Property("disabled", b ? "true" : "false")

/// Sets the checked boolean attribute.
let checked = (b: bool): attribute<'msg> => Property("checked", b ? "true" : "false")

/// Sets the type attribute.
let type_ = (t: string): attribute<'msg> => Property("type", t)

/// Sets the name attribute.
let name = (n: string): attribute<'msg> => Property("name", n)

/// Sets the tabindex attribute.
let tabIndex = (i: int): attribute<'msg> => Property("tabindex", Int.toString(i))

// Form attributes

/// Sets the `for` attribute (label association).
let for_ = (id: string): attribute<'msg> => Property("for", id)

/// Sets the required boolean attribute.
let required = (b: bool): attribute<'msg> => Property("required", b ? "true" : "false")

/// Sets the readonly boolean attribute.
let readonly = (b: bool): attribute<'msg> => Property("readonly", b ? "true" : "false")

/// Sets the autofocus boolean attribute.
let autofocus = (b: bool): attribute<'msg> => Property("autofocus", b ? "true" : "false")

/// Sets the autocomplete attribute.
let autocomplete = (v: string): attribute<'msg> => Property("autocomplete", v)

/// Sets the pattern attribute (regex validation).
let pattern = (p: string): attribute<'msg> => Property("pattern", p)

/// Sets the multiple boolean attribute.
let multiple = (b: bool): attribute<'msg> => Property("multiple", b ? "true" : "false")

/// Sets the accept attribute (MIME types).
let accept = (v: string): attribute<'msg> => Property("accept", v)

/// Sets the min attribute.
let min = (v: string): attribute<'msg> => Property("min", v)

/// Sets the max attribute.
let max = (v: string): attribute<'msg> => Property("max", v)

/// Sets the step attribute.
let step = (v: string): attribute<'msg> => Property("step", v)

/// Sets the maxlength attribute.
let maxLength = (n: int): attribute<'msg> => Property("maxlength", Int.toString(n))

/// Sets the minlength attribute.
let minLength = (n: int): attribute<'msg> => Property("minlength", Int.toString(n))

/// Sets the action URL for form submission.
let action = (url: string): attribute<'msg> => Property("action", url)

/// Sets the form method attribute.
let method = (m: string): attribute<'msg> => Property("method", m)

/// Sets the cols attribute for textarea.
let cols = (n: int): attribute<'msg> => Property("cols", Int.toString(n))

/// Sets the rows attribute for textarea.
let rows = (n: int): attribute<'msg> => Property("rows", Int.toString(n))

/// Sets the novalidate boolean attribute on forms.
let noValidate = (b: bool): attribute<'msg> => Property("novalidate", b ? "true" : "false")

// Media/embed attributes

/// Sets the width attribute.
let width = (v: string): attribute<'msg> => Property("width", v)

/// Sets the height attribute.
let height = (v: string): attribute<'msg> => Property("height", v)

/// Sets the target attribute.
let target = (t: string): attribute<'msg> => Property("target", t)

/// Sets the download attribute.
let download = (v: string): attribute<'msg> => Property("download", v)

/// Sets the rel attribute.
let rel = (r: string): attribute<'msg> => Property("rel", r)

/// Sets the hidden boolean attribute.
let hidden = (b: bool): attribute<'msg> => Property("hidden", b ? "true" : "false")

// Interaction attributes

/// Sets the draggable boolean attribute.
let draggable = (b: bool): attribute<'msg> => Property("draggable", b ? "true" : "false")

/// Sets the contenteditable boolean attribute.
let contentEditable = (b: bool): attribute<'msg> => Property(
  "contenteditable",
  b ? "true" : "false",
)

/// Sets the spellcheck boolean attribute.
let spellCheck = (b: bool): attribute<'msg> => Property("spellcheck", b ? "true" : "false")

// Table attributes

/// Sets the colspan attribute.
let colspan = (n: int): attribute<'msg> => Property("colspan", Int.toString(n))

/// Sets the rowspan attribute.
let rowspan = (n: int): attribute<'msg> => Property("rowspan", Int.toString(n))

/// Sets a data-* attribute. `data_("key", "val")` renders as `data-key="val"`.
let data_ = (key: string, value: string): attribute<'msg> => Property("data-" ++ key, value)

// ARIA accessibility attributes

/// Sets the aria-label attribute.
let ariaLabel = (label: string): attribute<'msg> => Property("aria-label", label)

/// Sets the aria-live attribute.
let ariaLive = (mode: string): attribute<'msg> => Property("aria-live", mode)

/// Sets the aria-expanded boolean attribute.
let ariaExpanded = (b: bool): attribute<'msg> => Property("aria-expanded", b ? "true" : "false")

/// Sets the aria-hidden boolean attribute.
let ariaHidden = (b: bool): attribute<'msg> => Property("aria-hidden", b ? "true" : "false")

/// Sets the aria-pressed boolean attribute.
let ariaPressed = (b: bool): attribute<'msg> => Property("aria-pressed", b ? "true" : "false")

/// Sets the aria-current attribute.
let ariaCurrent = (v: string): attribute<'msg> => Property("aria-current", v)

/// Sets the aria-valuenow attribute.
let ariaValueNow = (v: float): attribute<'msg> => Property("aria-valuenow", Float.toString(v))

/// Sets the aria-valuemin attribute.
let ariaValueMin = (v: float): attribute<'msg> => Property("aria-valuemin", Float.toString(v))

/// Sets the aria-valuemax attribute.
let ariaValueMax = (v: float): attribute<'msg> => Property("aria-valuemax", Float.toString(v))

/// Sets the aria-describedby attribute.
let ariaDescribedBy = (id: string): attribute<'msg> => Property("aria-describedby", id)

/// Sets the aria-checked boolean attribute.
let ariaChecked = (b: bool): attribute<'msg> => Property("aria-checked", b ? "true" : "false")

/// Sets the aria-selected boolean attribute.
let ariaSelected = (b: bool): attribute<'msg> => Property("aria-selected", b ? "true" : "false")

/// Sets the aria-controls attribute.
let ariaControls = (id: string): attribute<'msg> => Property("aria-controls", id)

/// Sets the aria-labelledby attribute.
let ariaLabelledBy = (id: string): attribute<'msg> => Property("aria-labelledby", id)

/// Sets the aria-required boolean attribute.
let ariaRequired = (b: bool): attribute<'msg> => Property("aria-required", b ? "true" : "false")

/// Sets the aria-invalid boolean attribute.
let ariaInvalid = (b: bool): attribute<'msg> => Property("aria-invalid", b ? "true" : "false")

/// Sets the aria-disabled boolean attribute.
let ariaDisabled = (b: bool): attribute<'msg> => Property("aria-disabled", b ? "true" : "false")

/// Sets the aria-sort attribute.
let ariaSort = (v: string): attribute<'msg> => Property("aria-sort", v)

/// Sets the aria-orientation attribute.
let ariaOrientation = (v: string): attribute<'msg> => Property("aria-orientation", v)

/// Sets the aria-modal boolean attribute.
let ariaModal = (b: bool): attribute<'msg> => Property("aria-modal", b ? "true" : "false")

/// Sets the role attribute.
let role = (r: string): attribute<'msg> => Property("role", r)

/// Sets the selected boolean attribute.
let selected = (b: bool): attribute<'msg> => Property("selected", b ? "true" : "false")

// ── Event handlers ─────────────────────────────────────────────────

// Mouse events

/// Click event handler. Dispatches the given message on click.
let onClick = (msg: 'msg): attribute<'msg> => Event("click", () => msg)

/// Double-click event handler.
let onDoubleClick = (msg: 'msg): attribute<'msg> => Event("dblclick", () => msg)

/// Context menu (right-click) event handler. Prevents the default browser menu.
let onContextMenu = (msg: 'msg): attribute<'msg> => EventPreventDefault("contextmenu", () => msg)

/// Mouse button down event handler.
let onMouseDown = (msg: 'msg): attribute<'msg> => Event("mousedown", () => msg)

/// Mouse button up event handler.
let onMouseUp = (msg: 'msg): attribute<'msg> => Event("mouseup", () => msg)

/// Mouse enter event handler (does not bubble).
let onMouseEnter = (msg: 'msg): attribute<'msg> => Event("mouseenter", () => msg)

/// Mouse leave event handler (does not bubble).
let onMouseLeave = (msg: 'msg): attribute<'msg> => Event("mouseleave", () => msg)

/// Mouse over event handler (bubbles).
let onMouseOver = (msg: 'msg): attribute<'msg> => Event("mouseover", () => msg)

/// Mouse out event handler (bubbles).
let onMouseOut = (msg: 'msg): attribute<'msg> => Event("mouseout", () => msg)

// Pointer events (unified mouse/touch/pen)

/// Pointer down event handler.
let onPointerDown = (msg: 'msg): attribute<'msg> => Event("pointerdown", () => msg)

/// Pointer up event handler.
let onPointerUp = (msg: 'msg): attribute<'msg> => Event("pointerup", () => msg)

/// Pointer move event handler.
let onPointerMove = (msg: 'msg): attribute<'msg> => Event("pointermove", () => msg)

/// Pointer enter event handler.
let onPointerEnter = (msg: 'msg): attribute<'msg> => Event("pointerenter", () => msg)

/// Pointer leave event handler.
let onPointerLeave = (msg: 'msg): attribute<'msg> => Event("pointerleave", () => msg)

/// Pointer cancel event handler.
let onPointerCancel = (msg: 'msg): attribute<'msg> => Event("pointercancel", () => msg)

// Touch events

/// Touch start event handler.
let onTouchStart = (msg: 'msg): attribute<'msg> => Event("touchstart", () => msg)

/// Touch end event handler.
let onTouchEnd = (msg: 'msg): attribute<'msg> => Event("touchend", () => msg)

/// Touch move event handler.
let onTouchMove = (msg: 'msg): attribute<'msg> => Event("touchmove", () => msg)

/// Touch cancel event handler.
let onTouchCancel = (msg: 'msg): attribute<'msg> => Event("touchcancel", () => msg)

// Form events

/// Input event handler. Fires on each keystroke. Handler receives the current value string.
let onInput = (handler: string => 'msg): attribute<'msg> => EventWithValue("input", handler)

/// Change event handler. Fires when the value is committed. Handler receives the value string.
let onChange = (handler: string => 'msg): attribute<'msg> => EventWithValue("change", handler)

/// Form submit event handler. Prevents the default form submission.
let onSubmit = (msg: 'msg): attribute<'msg> => EventPreventDefault("submit", () => msg)

/// Form reset event handler.
let onReset = (msg: 'msg): attribute<'msg> => Event("reset", () => msg)

// Focus events

/// Focus event handler. Fires when the element gains focus.
let onFocus = (msg: 'msg): attribute<'msg> => Event("focus", () => msg)

/// Blur event handler. Fires when the element loses focus.
let onBlur = (msg: 'msg): attribute<'msg> => Event("blur", () => msg)

// Keyboard events

/// Key down event handler. Handler receives the key string and returns `Some(msg)` to handle or `None` to ignore.
let onKeyDown = (handler: string => option<'msg>): attribute<'msg> => EventWithKey(
  "keydown",
  handler,
)

/// Key up event handler. Handler receives the key string and returns `Some(msg)` to handle or `None` to ignore.
let onKeyUp = (handler: string => option<'msg>): attribute<'msg> => EventWithKey("keyup", handler)

/// Key press event handler (deprecated in browsers; prefer onKeyDown).
let onKeyPress = (handler: string => option<'msg>): attribute<'msg> => EventWithKey(
  "keypress",
  handler,
)

// Drag and drop events

/// Drag start event handler.
let onDragStart = (msg: 'msg): attribute<'msg> => Event("dragstart", () => msg)

/// Drag event handler (fires continuously while dragging).
let onDrag = (msg: 'msg): attribute<'msg> => Event("drag", () => msg)

/// Drag end event handler.
let onDragEnd = (msg: 'msg): attribute<'msg> => Event("dragend", () => msg)

/// Drag enter event handler.
let onDragEnter = (msg: 'msg): attribute<'msg> => Event("dragenter", () => msg)

/// Drag leave event handler.
let onDragLeave = (msg: 'msg): attribute<'msg> => Event("dragleave", () => msg)

/// Drag over event handler. Prevents default to allow dropping.
let onDragOver = (msg: 'msg): attribute<'msg> => EventPreventDefault("dragover", () => msg)

/// Drop event handler. Prevents default browser handling.
let onDrop = (msg: 'msg): attribute<'msg> => EventPreventDefault("drop", () => msg)

// Scroll events

/// Scroll event handler.
let onScroll = (msg: 'msg): attribute<'msg> => Event("scroll", () => msg)

// Animation/transition events

/// CSS animation end event handler.
let onAnimationEnd = (msg: 'msg): attribute<'msg> => Event("animationend", () => msg)

/// CSS animation start event handler.
let onAnimationStart = (msg: 'msg): attribute<'msg> => Event("animationstart", () => msg)

/// CSS transition end event handler.
let onTransitionEnd = (msg: 'msg): attribute<'msg> => Event("transitionend", () => msg)

// Clipboard events

/// Copy event handler.
let onCopy = (msg: 'msg): attribute<'msg> => Event("copy", () => msg)

/// Cut event handler.
let onCut = (msg: 'msg): attribute<'msg> => Event("cut", () => msg)

/// Paste event handler.
let onPaste = (msg: 'msg): attribute<'msg> => Event("paste", () => msg)

// Wheel event

/// Mouse wheel event handler.
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
  | Fragment(children) => Fragment(Array.map(children, child => map(child, f)))
  }
}
/// Map the message type of a single attribute
and mapAttr = (attr: attribute<'a>, f: 'a => 'b): attribute<'b> => {
  switch attr {
  | Property(k, v) => Property(k, v)
  | Style(k, v) => Style(k, v)
  | Event(name, handler) => Event(name, () => f(handler()))
  | EventWithValue(name, handler) => EventWithValue(name, v => f(handler(v)))
  | EventWithKey(name, handler) =>
    EventWithKey(
      name,
      key =>
        switch handler(key) {
        | Some(msg) => Some(f(msg))
        | None => None
        },
    )
  | EventPreventDefault(name, handler) => EventPreventDefault(name, () => f(handler()))
  | EventStopPropagation(name, handler) => EventStopPropagation(name, () => f(handler()))
  }
}
