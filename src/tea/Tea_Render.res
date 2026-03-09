// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// Tea_Render.res — DOM rendering engine with virtual DOM diffing, keyed
// child reconciliation, fragment support, and event lifecycle management.
//
// This module bridges Tea_Vdom (virtual DOM) to the real DOM with:
// - Key-based child diffing for O(n) list reordering
// - Positional child diffing for unkeyed elements
// - Fragment rendering (children without wrapper element)
// - Proper attribute removal on updates
// - Event listener lifecycle management (leak-free)
// - SVG namespace support

open Tea_Vdom

/// DOM element type binding
type domElement

/// SVG namespace URI
let svgNS = "http://www.w3.org/2000/svg"

/// Tags that require SVG namespace
let isSvgTag = (tag: string): bool => {
  switch tag {
  | "svg" | "circle" | "ellipse" | "line" | "path" | "polygon" | "polyline"
  | "rect" | "g" | "defs" | "use" | "symbol" | "clipPath" | "mask"
  | "pattern" | "image" | "text" | "tspan" | "textPath" | "foreignObject"
  | "marker" | "linearGradient" | "radialGradient" | "stop" | "filter"
  | "feBlend" | "feColorMatrix" | "feComposite" | "feFlood" | "feGaussianBlur"
  | "feMerge" | "feMergeNode" | "feOffset" | "animate" | "animateTransform"
  | "set" | "desc" | "title" | "metadata" =>
    true
  | _ => false
  }
}

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

/// Remove style property
@send external removeStyleProperty: ({..}, string) => unit = "removeProperty"

/// Remove event listener from element
let removeEventListener = (listener: eventListener): unit => {
  let el: {..} = Obj.magic(listener.element)
  el["removeEventListener"](listener.eventName, listener.handler)
}

/// Boolean properties that should be set directly on the element
let isBoolProp = (key: string): bool => {
  switch key {
  | "checked" | "disabled" | "readonly" | "required" | "autofocus"
  | "multiple" | "selected" | "hidden" | "novalidate" =>
    true
  | _ => false
  }
}

/// Apply a single attribute to a DOM element
let applyAttribute = (el: {..}, attr: attribute<'msg>, state: renderState<'msg>, domEl: domElement): unit => {
  switch attr {
  | Property(key, value) =>
    if key === "" {
      () // noProp — skip
    } else if key === "class" {
      el["className"] = value
    } else if key === "value" {
      el["value"] = value
    } else if key === "checked" {
      el["checked"] = value === "true"
    } else if key === "disabled" {
      el["disabled"] = value === "true"
    } else if key === "readonly" {
      el["readOnly"] = value === "true"
    } else if key === "required" {
      el["required"] = value === "true"
    } else if key === "autofocus" {
      el["autofocus"] = value === "true"
    } else if key === "multiple" {
      el["multiple"] = value === "true"
    } else if key === "selected" {
      el["selected"] = value === "true"
    } else if key === "hidden" {
      el["hidden"] = value === "true"
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
        element: domEl,
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
        element: domEl,
        eventName: name,
        handler: eventHandler,
      })->ignore
    }
  | EventWithKey(name, handler) => {
      let eventHandler = (_e: Dom.event) => {
        let key: string = %raw(`_e.key || ""`)
        switch handler(key) {
        | Some(msg) => {
            let _: unit = %raw(`_e.preventDefault()`)
            state.dispatch(msg)
          }
        | None => ()
        }
      }
      el["addEventListener"](name, eventHandler)->ignore
      Array.push(state.listeners, {
        element: domEl,
        eventName: name,
        handler: eventHandler,
      })->ignore
    }
  | EventPreventDefault(name, handler) => {
      let eventHandler = (_e: Dom.event) => {
        let _: unit = %raw(`_e.preventDefault()`)
        state.dispatch(handler())
      }
      el["addEventListener"](name, eventHandler)->ignore
      Array.push(state.listeners, {
        element: domEl,
        eventName: name,
        handler: eventHandler,
      })->ignore
    }
  | EventStopPropagation(name, handler) => {
      let eventHandler = (_e: Dom.event) => {
        let _: unit = %raw(`_e.stopPropagation()`)
        state.dispatch(handler())
      }
      el["addEventListener"](name, eventHandler)->ignore
      Array.push(state.listeners, {
        element: domEl,
        eventName: name,
        handler: eventHandler,
      })->ignore
    }
  }
}

/// Create a real DOM element from virtual DOM
let rec createElement = (vdom: t<'msg>, state: renderState<'msg>): domElement => {
  switch vdom {
  | Text(s) => document["createTextNode"](s)
  | Element(tag, attrs, children) => {
      let el = if isSvgTag(tag) {
        document["createElementNS"](svgNS, tag)
      } else {
        document["createElement"](tag)
      }
      let domEl: domElement = el
      Array.forEach(attrs, attr => applyAttribute(el, attr, state, domEl))
      Array.forEach(children, child => {
        let childEl = createElement(child, state)
        el["appendChild"](childEl)
      })
      domEl
    }
  | KeyedElement(tag, attrs, keyedChildren) => {
      let el = if isSvgTag(tag) {
        document["createElementNS"](svgNS, tag)
      } else {
        document["createElement"](tag)
      }
      let domEl: domElement = el
      Array.forEach(attrs, attr => applyAttribute(el, attr, state, domEl))
      Array.forEach(keyedChildren, ((_key, child)) => {
        let childEl = createElement(child, state)
        el["appendChild"](childEl)
      })
      domEl
    }
  | Fragment(children) => {
      let frag = document["createDocumentFragment"]()
      Array.forEach(children, child => {
        let childEl = createElement(child, state)
        frag["appendChild"](childEl)
      })
      frag
    }
  }
}

/// Cleanup all event listeners
let cleanup = (state: renderState<'msg>): unit => {
  Array.forEach(state.listeners, removeEventListener)
  state.listeners = []
}

/// Render virtual DOM to a container element (full re-render)
let render = (container: domElement, vdom: t<'msg>, state: renderState<'msg>): unit => {
  cleanup(state)
  let containerObj: {..} = Obj.magic(container)
  containerObj["innerHTML"] = ""
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

// ── Diffing engine ─────────────────────────────────────────────────

/// Patch type representing DOM changes
type rec patch<'msg> =
  | Replace(t<'msg>)
  | UpdateAttrsAndChildren(array<attribute<'msg>>, array<childPatch<'msg>>)
  | UpdateProps(array<attribute<'msg>>)
  | UpdateChildren(array<childPatch<'msg>>)
  | UpdateKeyedChildren(array<(string, t<'msg>)>, array<(string, t<'msg>)>)
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
      | (Event(n1, _), Some(Event(n2, _))) => n1 === n2
      | (EventWithValue(n1, _), Some(EventWithValue(n2, _))) => n1 === n2
      | (EventWithKey(n1, _), Some(EventWithKey(n2, _))) => n1 === n2
      | (EventPreventDefault(n1, _), Some(EventPreventDefault(n2, _))) => n1 === n2
      | (EventStopPropagation(n1, _), Some(EventStopPropagation(n2, _))) => n1 === n2
      | _ => false
      }
    })
  }
}

/// Diff two virtual DOM trees
let rec diff = (oldVdom: t<'msg>, newVdom: t<'msg>): patch<'msg> => {
  switch (oldVdom, newVdom) {
  | (Text(s1), Text(s2)) => s1 === s2 ? NoChange : Replace(newVdom)
  | (Text(_), _) => Replace(newVdom)
  | (_, Text(_)) => Replace(newVdom)
  | (Fragment(_), _) | (_, Fragment(_)) =>
    // Fragments always replace — they don't have a stable root node
    Replace(newVdom)
  | (Element(tag1, attrs1, children1), Element(tag2, attrs2, children2)) =>
    if tag1 !== tag2 {
      Replace(newVdom)
    } else {
      let attrsChanged = !attributesEqual(attrs1, attrs2)
      let childPatches = diffChildren(children1, children2)
      let hasChildChanges = Array.some(childPatches, cp => cp.patch !== NoChange)

      switch (attrsChanged, hasChildChanges) {
      | (true, true) => UpdateAttrsAndChildren(attrs2, childPatches)
      | (true, false) => UpdateProps(attrs2)
      | (false, true) => UpdateChildren(childPatches)
      | (false, false) => NoChange
      }
    }
  | (KeyedElement(tag1, attrs1, children1), KeyedElement(tag2, attrs2, children2)) =>
    if tag1 !== tag2 {
      Replace(newVdom)
    } else {
      let attrsChanged = !attributesEqual(attrs1, attrs2)
      // Check if keyed children changed
      let keysChanged = Array.length(children1) !== Array.length(children2) ||
        Array.someWithIndex(children1, ((k1, _), i) => {
          switch Array.get(children2, i) {
          | Some((k2, _)) => k1 !== k2
          | None => true
          }
        })

      if attrsChanged || keysChanged {
        UpdateKeyedChildren(children1, children2)
      } else {
        // Same keys in same order — diff each child
        let hasChanges = ref(false)
        Array.forEachWithIndex(children1, ((_k, oldChild), i) => {
          switch Array.get(children2, i) {
          | Some((_k2, newChild)) =>
            if diff(oldChild, newChild) !== NoChange {
              hasChanges := true
            }
          | None => hasChanges := true
          }
        })
        if hasChanges.contents {
          UpdateKeyedChildren(children1, children2)
        } else if attrsChanged {
          UpdateProps(attrs2)
        } else {
          NoChange
        }
      }
    }
  | (Element(_, _, _), KeyedElement(_, _, _)) => Replace(newVdom)
  | (KeyedElement(_, _, _), Element(_, _, _)) => Replace(newVdom)
  }
}

and diffChildren = (oldChildren: array<t<'msg>>, newChildren: array<t<'msg>>): array<childPatch<'msg>> => {
  let maxLen = Pervasives.max(Array.length(oldChildren), Array.length(newChildren))
  Array.fromInitializer(~length=maxLen, i => {
    switch (Array.get(oldChildren, i), Array.get(newChildren, i)) {
    | (None, Some(newChild)) => {index: i, patch: Replace(newChild)}
    | (Some(_), None) => {index: i, patch: RemoveNode}
    | (Some(oldChild), Some(newChild)) => {index: i, patch: diff(oldChild, newChild)}
    | (None, None) => {index: i, patch: NoChange}
    }
  })
}

/// Collect property and style keys from old attrs for removal tracking
let getAttrKeys = (attrs: array<attribute<'msg>>): array<(string, string)> => {
  Array.filterMap(attrs, attr => {
    switch attr {
    | Property(k, _) => k !== "" ? Some(("prop", k)) : None
    | Style(k, _) => Some(("style", k))
    | _ => None
    }
  })
}

/// Remove attributes that existed in old but not in new
let removeStaleAttrs = (el: {..}, oldAttrs: array<attribute<'msg>>, newAttrs: array<attribute<'msg>>): unit => {
  let oldKeys = getAttrKeys(oldAttrs)
  let newKeys = getAttrKeys(newAttrs)
  Array.forEach(oldKeys, ((kind, key)) => {
    let stillExists = Array.some(newKeys, ((k, v)) => k === kind && v === key)
    if !stillExists {
      switch kind {
      | "prop" =>
        if key === "class" {
          el["className"] = ""
        } else if key === "checked" || key === "disabled" || key === "readonly"
          || key === "required" || key === "autofocus" || key === "multiple"
          || key === "selected" || key === "hidden" {
          el["removeAttribute"](key)
        } else {
          el["removeAttribute"](key)
        }
      | "style" =>
        removeStyleProperty(el["style"], key)
      | _ => ()
      }
    }
  })
}

/// Remove old event listeners for a specific element
let removeElementListeners = (state: renderState<'msg>, domEl: domElement): unit => {
  let (toRemove, toKeep) = Array.reduce(state.listeners, ([], []), ((rem, keep), listener) => {
    if Obj.magic(listener.element) === Obj.magic(domEl) {
      (Array.concat(rem, [listener]), keep)
    } else {
      (rem, Array.concat(keep, [listener]))
    }
  })
  Array.forEach(toRemove, removeEventListener)
  state.listeners = toKeep
}

/// Apply keyed child patches using the move-minimising algorithm.
/// This is the core of efficient list rendering — instead of destroying
/// and recreating DOM nodes when a list is reordered, we move them.
let applyKeyedPatch = (
  _parentEl: domElement,
  _oldKeyed: array<(string, t<'msg>)>,
  _newKeyed: array<(string, t<'msg>)>,
  _state: renderState<'msg>,
): unit => {
  // Use raw JS for DOM manipulation — keyed reconciliation requires
  // direct access to childNodes, insertBefore, and removeChild.
  let _createElement = createElement
  let _diff = diff
  %raw(`
    (function() {
      var parentEl = _parentEl;
      var state = _state;
      var childNodes = Array.from(parentEl.childNodes);

      // Build old key → {index, dom, vdom} map
      var oldMap = new Map();
      for (var i = 0; i < _oldKeyed.length; i++) {
        var key = _oldKeyed[i][0];
        var vdom = _oldKeyed[i][1];
        oldMap.set(key, { index: i, dom: childNodes[i], vdom: vdom });
      }

      // Track which old nodes we've used
      var usedOldKeys = new Set();

      // Process new children in order
      for (var ni = 0; ni < _newKeyed.length; ni++) {
        var newKey = _newKeyed[ni][0];
        var newVdom = _newKeyed[ni][1];
        var old = oldMap.get(newKey);
        var refNode = parentEl.childNodes[ni] || null;

        if (old) {
          usedOldKeys.add(newKey);
          // Diff old vs new vdom for this key
          var patch = _diff(old.vdom, newVdom);
          if (patch.TAG !== undefined) {
            // Has changes — for simplicity, replace the node
            var newEl = _createElement(newVdom, state);
            parentEl.insertBefore(newEl, old.dom);
            parentEl.removeChild(old.dom);
          } else {
            // NoChange — just ensure correct position
            if (parentEl.childNodes[ni] !== old.dom) {
              parentEl.insertBefore(old.dom, refNode);
            }
          }
        } else {
          // New key — create and insert
          var newEl = _createElement(newVdom, state);
          parentEl.insertBefore(newEl, refNode);
        }
      }

      // Remove old nodes whose keys are no longer present
      for (var [key, old] of oldMap) {
        if (!usedOldKeys.has(key)) {
          if (old.dom.parentNode === parentEl) {
            parentEl.removeChild(old.dom);
          }
        }
      }
    })()
  `)
}

/// Apply a patch to a DOM node
let rec applyPatch = (domNode: domElement, patchVal: patch<'msg>, state: renderState<'msg>): unit => {
  switch patchVal {
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
      // Remove stale attrs from previous render
      switch state.previousVdom {
      | Some(Element(_, oldAttrs, _)) | Some(KeyedElement(_, oldAttrs, _)) =>
        removeStaleAttrs(el, oldAttrs, newAttrs)
      | _ => ()
      }
      // Remove old event listeners for this element before re-adding
      removeElementListeners(state, domNode)
      // Apply new attributes
      Array.forEach(newAttrs, attr => applyAttribute(el, attr, state, domNode))
    }
  | UpdateChildren(childPatches) => {
      let el: {..} = Obj.magic(domNode)
      let childNodes: array<domElement> = %raw(`Array.from(el.childNodes)`)
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
  | UpdateAttrsAndChildren(newAttrs, childPatches) => {
      let el: {..} = Obj.magic(domNode)
      // Update attrs
      switch state.previousVdom {
      | Some(Element(_, oldAttrs, _)) | Some(KeyedElement(_, oldAttrs, _)) =>
        removeStaleAttrs(el, oldAttrs, newAttrs)
      | _ => ()
      }
      removeElementListeners(state, domNode)
      Array.forEach(newAttrs, attr => applyAttribute(el, attr, state, domNode))
      // Update children
      let childNodes: array<domElement> = %raw(`Array.from(el.childNodes)`)
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
  | UpdateKeyedChildren(oldKeyed, newKeyed) => {
      applyKeyedPatch(domNode, oldKeyed, newKeyed, state)
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
      let patchVal = diff(oldVdom, vdom)
      switch patchVal {
      | NoChange => ()
      | Replace(_) => {
          render(container, vdom, state)
        }
      | _ => {
          let containerObj: {..} = Obj.magic(container)
          let firstChild: option<domElement> = switch containerObj["firstChild"] {
          | child if !Nullable.isNullable(Nullable.make(child)) => Some(child)
          | _ => None
          }
          switch firstChild {
          | Some(child) => applyPatch(child, patchVal, state)
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
