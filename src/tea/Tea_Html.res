// SPDX-License-Identifier: AGPL-3.0-or-later

/// TEA HTML - Virtual DOM for the TEA architecture.
///
/// This module provides a simple virtual DOM implementation for
/// building HTML views in a declarative, functional style.

open Tea_Vdom

/// Re-export Vdom types
type t<'msg> = Tea_Vdom.t<'msg>

/// Create a text node
let text = Tea_Vdom.text

/// Create an element node
let node = Tea_Vdom.node

/// No node (renders nothing)
let noNode: t<'msg> = Text("")

/// Common HTML elements
let div = (attrs, children) => node("div", attrs, children)
let span = (attrs, children) => node("span", attrs, children)
let p = (attrs, children) => node("p", attrs, children)
let h1 = (attrs, children) => node("h1", attrs, children)
let h2 = (attrs, children) => node("h2", attrs, children)
let h3 = (attrs, children) => node("h3", attrs, children)
let h4 = (attrs, children) => node("h4", attrs, children)
let button = (attrs, children) => node("button", attrs, children)
let input = (attrs, children) => node("input", attrs, children)
let textarea = (attrs, children) => node("textarea", attrs, children)
let label = (attrs, children) => node("label", attrs, children)
let a = (attrs, children) => node("a", attrs, children)
let img = (attrs, children) => node("img", attrs, children)
let ul = (attrs, children) => node("ul", attrs, children)
let ol = (attrs, children) => node("ol", attrs, children)
let li = (attrs, children) => node("li", attrs, children)
let form = (attrs, children) => node("form", attrs, children)
let header = (attrs, children) => node("header", attrs, children)
let footer = (attrs, children) => node("footer", attrs, children)
let main = (attrs, children) => node("main", attrs, children)
let nav = (attrs, children) => node("nav", attrs, children)
let section = (attrs, children) => node("section", attrs, children)
let article = (attrs, children) => node("article", attrs, children)
let aside = (attrs, children) => node("aside", attrs, children)

/// Attribute helpers module
module Attrs = {
  let class_ = Tea_Vdom.class_
  let id = Tea_Vdom.id
  let style = Tea_Vdom.style
  let placeholder = Tea_Vdom.placeholder
  let value = Tea_Vdom.value
  let title = Tea_Vdom.title
  let href = Tea_Vdom.href
  let src = Tea_Vdom.src
  let alt = Tea_Vdom.alt
  let disabled = Tea_Vdom.disabled
  let checked = Tea_Vdom.checked
  let type_ = Tea_Vdom.type_
  let name = Tea_Vdom.name
}

/// Event helpers module
module Events = {
  let onClick = Tea_Vdom.onClick
  let onInput = Tea_Vdom.onInput
  let onSubmit = Tea_Vdom.onSubmit
  let onMouseEnter = Tea_Vdom.onMouseEnter
  let onMouseLeave = Tea_Vdom.onMouseLeave
  let onFocus = Tea_Vdom.onFocus
  let onBlur = Tea_Vdom.onBlur
}

/// Map the message type of a virtual DOM tree
let map = Tea_Vdom.map
