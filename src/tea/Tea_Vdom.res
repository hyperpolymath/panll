// SPDX-License-Identifier: AGPL-3.0-or-later

/// TEA Virtual DOM - Core VDOM implementation.
///
/// A minimal virtual DOM for the TEA architecture, supporting
/// elements, text nodes, attributes, and event handlers.

/// Attribute types
type rec attribute<'msg> =
  | Property(string, string)
  | Style(string, string)
  | Event(string, unit => 'msg)
  | EventWithValue(string, string => 'msg)

/// Virtual DOM node type
type rec t<'msg> =
  | Text(string)
  | Element(string, array<attribute<'msg>>, array<t<'msg>>)

/// Create a text node
let text = (s: string): t<'msg> => Text(s)

/// Create an element node
let node = (tag: string, attrs: list<attribute<'msg>>, children: list<t<'msg>>): t<'msg> => {
  Element(tag, List.toArray(attrs), List.toArray(children))
}

/// Attribute constructors
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

/// Event handlers
let onClick = (msg: 'msg): attribute<'msg> => Event("click", () => msg)
let onInput = (handler: string => 'msg): attribute<'msg> => EventWithValue("input", handler)
let onSubmit = (msg: 'msg): attribute<'msg> => Event("submit", () => msg)
let onMouseEnter = (msg: 'msg): attribute<'msg> => Event("mouseenter", () => msg)
let onMouseLeave = (msg: 'msg): attribute<'msg> => Event("mouseleave", () => msg)
let onFocus = (msg: 'msg): attribute<'msg> => Event("focus", () => msg)
let onBlur = (msg: 'msg): attribute<'msg> => Event("blur", () => msg)

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
  }
}
and mapAttr = (attr: attribute<'a>, f: 'a => 'b): attribute<'b> => {
  switch attr {
  | Property(k, v) => Property(k, v)
  | Style(k, v) => Style(k, v)
  | Event(name, handler) => Event(name, () => f(handler()))
  | EventWithValue(name, handler) => EventWithValue(name, v => f(handler(v)))
  }
}
