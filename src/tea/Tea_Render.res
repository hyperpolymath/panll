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

/// Render state tracking event listeners and previous vdom for diffing
type renderState<'msg> = {
  mutable listeners: array<eventListener>,
  dispatch: 'msg => unit,
  mutable previousVdom: option<t<'msg>>,
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
          el["addEventListener"](name, eventHandler)->ignore
          Array.push(state.listeners, {
            element: el,
            eventName: name,
            handler: eventHandler,
          })->ignore
        }
      | EventWithValue(name, handler) => {
          let eventHandler = (_e: Dom.event) => {
            let value: string = %raw(`_e.target.value || ""`)
            state.dispatch(handler(value))
          }
          el["addEventListener"](name, eventHandler)->ignore
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

/// Patch type representing DOM changes
type rec patch<'msg> =
  | Replace(t<'msg>)
  | UpdateProps(array<attribute<'msg>>)
  | UpdateChildren(array<childPatch<'msg>>)
  | RemoveNode
  | NoChange

and childPatch<'msg> = {
  index: int,
  patch: patch<'msg>,
}

/// Compare two attribute arrays
let attributesEqual = (a1: array<attribute<'msg>>, a2: array<attribute<'msg>>): bool => {
  if Array.length(a1) !== Array.length(a2) {
    false
  } else {
    Array.everyWithIndex(a1, (attr, i) => {
      switch (attr, Array.get(a2, i)) {
      | (Property(k1, v1), Some(Property(k2, v2))) => k1 === k2 && v1 === v2
      | (Style(k1, v1), Some(Style(k2, v2))) => k1 === k2 && v1 === v2
      | (Event(n1, _), Some(Event(n2, _))) => n1 === n2 // Compare event names only
      | (EventWithValue(n1, _), Some(EventWithValue(n2, _))) => n1 === n2
      | _ => false
      }
    })
  }
}

/// Diff two virtual DOM trees
let rec diff = (oldVdom: t<'msg>, newVdom: t<'msg>): patch<'msg> => {
  switch (oldVdom, newVdom) {
  | (Text(s1), Text(s2)) => s1 === s2 ? NoChange : Replace(newVdom)
  | (Text(_), Element(_, _, _)) => Replace(newVdom)
  | (Element(_, _, _), Text(_)) => Replace(newVdom)
  | (Element(tag1, attrs1, children1), Element(tag2, attrs2, children2)) =>
    if tag1 !== tag2 {
      Replace(newVdom)
    } else {
      let attrsChanged = !attributesEqual(attrs1, attrs2)
      let childPatches = diffChildren(children1, children2)
      let hasChildChanges = Array.some(childPatches, cp => cp.patch !== NoChange)

      if attrsChanged && hasChildChanges {
        // Both props and children changed - for simplicity, replace
        Replace(newVdom)
      } else if attrsChanged {
        UpdateProps(attrs2)
      } else if hasChildChanges {
        UpdateChildren(childPatches)
      } else {
        NoChange
      }
    }
  }
}

and diffChildren = (oldChildren: array<t<'msg>>, newChildren: array<t<'msg>>): array<childPatch<'msg>> => {
  let maxLen = max(Array.length(oldChildren), Array.length(newChildren))
  Array.fromInitializer(~length=maxLen, i => {
    switch (Array.get(oldChildren, i), Array.get(newChildren, i)) {
    | (None, Some(newChild)) => {index: i, patch: Replace(newChild)}
    | (Some(_), None) => {index: i, patch: RemoveNode}
    | (Some(oldChild), Some(newChild)) => {index: i, patch: diff(oldChild, newChild)}
    | (None, None) => {index: i, patch: NoChange} // Should not happen
    }
  })
}

/// Apply a patch to a DOM node
let rec applyPatch = (domNode: domElement, patch: patch<'msg>, state: renderState<'msg>): unit => {
  switch patch {
  | NoChange => ()
  | Replace(newVdom) => {
      let parent: {..} = %raw(`domNode.parentNode`)
      if !Nullable.isNullable(Nullable.make(parent)) {
        let newEl = createElement(newVdom, state)
        parent["replaceChild"](newEl, domNode)
      }
    }
  | UpdateProps(newAttrs) => {
      let el: {..} = Obj.magic(domNode)
      // Clear existing attributes (simplified - proper impl would track which attrs to remove)
      Array.forEach(newAttrs, attr => {
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
            el["addEventListener"](name, eventHandler)->ignore
            Array.push(state.listeners, {
              element: domNode,
              eventName: name,
              handler: eventHandler,
            })->ignore
          }
        | EventWithValue(name, handler) => {
            let eventHandler = (_e: Dom.event) => {
              let value: string = %raw(`_e.target.value || ""`)
              state.dispatch(handler(value))
            }
            el["addEventListener"](name, eventHandler)->ignore
            Array.push(state.listeners, {
              element: domNode,
              eventName: name,
              handler: eventHandler,
            })->ignore
          }
        }
      })
    }
  | UpdateChildren(childPatches) => {
      let el: {..} = Obj.magic(domNode)
      let childNodes: array<domElement> = el["childNodes"]
      Array.forEach(childPatches, cp => {
        switch Array.get(childNodes, cp.index) {
        | Some(childNode) => applyPatch(childNode, cp.patch, state)
        | None =>
          switch cp.patch {
          | Replace(newChild) => {
              let newEl = createElement(newChild, state)
              el["appendChild"](newEl)
            }
          | _ => ()
          }
        }
      })
    }
  | RemoveNode => {
      let parent: {..} = %raw(`domNode.parentNode`)
      if !Nullable.isNullable(Nullable.make(parent)) {
        parent["removeChild"](domNode)
      }
    }
  }
}

/// Create initial render state
let createState = (dispatch: 'msg => unit): renderState<'msg> => {
  listeners: [],
  dispatch,
  previousVdom: None,
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

/// Update render - use diffing when possible, fallback to full render
let update = (
  container: domElement,
  vdom: t<'msg>,
  state: renderState<'msg>,
): unit => {
  switch state.previousVdom {
  | None => {
      render(container, vdom, state)
      state.previousVdom = Some(vdom)
    }
  | Some(oldVdom) => {
      let patch = diff(oldVdom, vdom)
      switch patch {
      | NoChange => ()
      | Replace(_) => {
          // For full replacement, just do a full re-render
          render(container, vdom, state)
        }
      | _ => {
          let containerObj: {..} = Obj.magic(container)
          let firstChild: option<domElement> = switch containerObj["firstChild"] {
          | child if !Nullable.isNullable(Nullable.make(child)) => Some(child)
          | _ => None
          }
          switch firstChild {
          | Some(child) => applyPatch(child, patch, state)
          | None => render(container, vdom, state)
          }
        }
      }
      state.previousVdom = Some(vdom)
    }
  }
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
