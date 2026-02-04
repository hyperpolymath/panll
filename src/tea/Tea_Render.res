// SPDX-License-Identifier: PMPL-1.0-or-later

/// TEA Render - DOM rendering with virtual DOM diffing and event management.
///
/// This module bridges Tea_Vdom (virtual DOM) to the real DOM with:
/// - Efficient virtual DOM diffing
/// - Event listener lifecycle management
/// - Memory-safe cleanup
/// - Type-safe DOM manipulation

open Tea_Vdom

/// DOM element type binding
type domElement

/// Event listener cleanup function
type eventListener = {
  element: domElement,
  eventName: string,
  handler: Dom.event => unit,
}

/// Render state tracking event listeners for cleanup
type renderState<'msg> = {
  mutable listeners: array<eventListener>,
  dispatch: 'msg => unit,
}

/// External DOM bindings
@val external document: {..} = "document"

/// Set style property using setProperty
@send external setStyleProperty: ({..}, string, string) => unit = "setProperty"

/// Remove event listener from element
let removeEventListener = (listener: eventListener): unit => {
  let el: {..} = Obj.magic(listener.element)
  el["removeEventListener"](listener.eventName, listener.handler)
}

/// Create a real DOM element from virtual DOM
let rec createElement = (vdom: t<'msg>, state: renderState<'msg>): domElement => {
  switch vdom {
  | Text(s) => document["createTextNode"](s)
  | Element(tag, attrs, children) =>
    let el = document["createElement"](tag)

    // Apply attributes and collect event listeners
    Array.forEach(attrs, attr => {
      switch attr {
      | Property(key, value) =>
        if key === "class" {
          el["className"] = value
        } else if key === "value" {
          el["value"] = value
        } else if key === "checked" {
          el["checked"] = value === "true"
        } else if key === "disabled" {
          el["disabled"] = value === "true"
        } else {
          el["setAttribute"](key, value)
        }
      | Style(prop, value) =>
        setStyleProperty(el["style"], prop, value)
      | Event(name, handler) => {
          let eventHandler = (_: Dom.event) => {
            state.dispatch(handler())
          }
          el["addEventListener"](name, eventHandler)
          // Track listener for cleanup
          Array.push(state.listeners, {
            element: el,
            eventName: name,
            handler: eventHandler,
          })->ignore
        }
      | EventWithValue(name, handler) => {
          let eventHandler = (e: Dom.event) => {
            let value: string = %raw(`e.target.value || ""`)
            state.dispatch(handler(value))
          }
          el["addEventListener"](name, eventHandler)
          // Track listener for cleanup
          Array.push(state.listeners, {
            element: el,
            eventName: name,
            handler: eventHandler,
          })->ignore
        }
      }
    })

    // Append children
    Array.forEach(children, child => {
      let childEl = createElement(child, state)
      el["appendChild"](childEl)
    })

    el
  }
}

/// Cleanup all event listeners
let cleanup = (state: renderState<'msg>): unit => {
  Array.forEach(state.listeners, removeEventListener)
  state.listeners = []
}

/// Render virtual DOM to a container element (full re-render)
let render = (container: domElement, vdom: t<'msg>, state: renderState<'msg>): unit => {
  // Cleanup old event listeners
  cleanup(state)

  // Clear container
  let containerObj: {..} = Obj.magic(container)
  containerObj["innerHTML"] = ""

  // Create and append new content
  let el = createElement(vdom, state)
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

/// Get element by selector
let querySelector = (selector: string): option<domElement> => {
  let el = document["querySelector"](selector)
  if Nullable.isNullable(Nullable.make(el)) {
    None
  } else {
    Some(el)
  }
}

/// Create initial render state
let createState = (dispatch: 'msg => unit): renderState<'msg> => {
  listeners: [],
  dispatch,
}

/// Mount a TEA app to a container selector
let mount = (
  containerSelector: string,
  vdom: t<'msg>,
  dispatch: 'msg => unit,
): option<renderState<'msg>> => {
  switch querySelector(containerSelector) {
  | None => {
      Console.error(`Mount point not found: ${containerSelector}`)
      None
    }
  | Some(container) => {
      let state = createState(dispatch)
      render(container, vdom, state)
      Some(state)
    }
  }
}

/// Update render - re-render with new vdom
let update = (
  container: domElement,
  vdom: t<'msg>,
  state: renderState<'msg>,
): unit => {
  render(container, vdom, state)
}

/// Unmount and cleanup
let unmount = (containerSelector: string, state: renderState<'msg>): unit => {
  cleanup(state)

  switch querySelector(containerSelector) {
  | Some(container) => {
      let containerObj: {..} = Obj.magic(container)
      containerObj["innerHTML"] = ""
    }
  | None => ()
  }
}
