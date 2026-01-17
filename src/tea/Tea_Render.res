// SPDX-License-Identifier: AGPL-3.0-or-later

/// TEA Render - DOM rendering for the TEA architecture.
///
/// This module handles rendering virtual DOM to the actual DOM,
/// and patching updates efficiently.

open Tea_Vdom

/// DOM element type binding
type domElement

/// External DOM bindings
@val external document: {..} = "document"

/// Set style property using setProperty
@send external setStyleProperty: ({..}, string, string) => unit = "setProperty"

/// Create a real DOM element from virtual DOM
let rec createElement = (vdom: t<'msg>, dispatch: 'msg => unit): domElement => {
  switch vdom {
  | Text(s) => document["createTextNode"](s)
  | Element(tag, attrs, children) =>
    let el = document["createElement"](tag)

    // Apply attributes
    Array.forEach(attrs, attr => {
      switch attr {
      | Property(key, value) =>
        if key === "class" {
          el["className"] = value
        } else if key === "value" {
          el["value"] = value
        } else {
          el["setAttribute"](key, value)
        }
      | Style(prop, value) =>
        setStyleProperty(el["style"], prop, value)
      | Event(name, handler) =>
        el["addEventListener"](name, _ => dispatch(handler()))
      | EventWithValue(name, handler) =>
        el["addEventListener"](name, e => {
          let value = e["target"]["value"]
          dispatch(handler(value))
        })
      }
    })

    // Append children
    Array.forEach(children, child => {
      let childEl = createElement(child, dispatch)
      el["appendChild"](childEl)
    })

    el
  }
}

/// Render virtual DOM to a container element
let render = (container: domElement, vdom: t<'msg>, dispatch: 'msg => unit): unit => {
  // Clear container
  let containerObj: {..} = Obj.magic(container)
  containerObj["innerHTML"] = ""

  // Create and append new content
  let el = createElement(vdom, dispatch)
  containerObj["appendChild"](el)
}

/// Get element by ID
let getElementById = (id: string): option<domElement> => {
  let el = document["getElementById"](id)
  if Nullable.isNullable(Nullable.make(el)) {
    None
  } else {
    Some(el)
  }
}
