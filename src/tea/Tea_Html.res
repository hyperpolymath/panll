// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// Tea_Html.res — HTML element constructors and attribute/event modules.

open Tea_Vdom

/// Re-export Vdom types
type t<'msg> = Tea_Vdom.t<'msg>

/// Create a text node
let text = Tea_Vdom.text

/// Create an element node from lists
let node = Tea_Vdom.node

/// Create an element node from arrays (faster)
let nodeA = Tea_Vdom.nodeA

/// Create a keyed element from lists (efficient list diffing)
let keyed = Tea_Vdom.keyed

/// Create a keyed element from arrays
let keyedA = Tea_Vdom.keyedA

/// Create a fragment (renders children without wrapper element)
let fragment = Tea_Vdom.fragment

/// Create a fragment from an array
let fragmentA = Tea_Vdom.fragmentA

/// No node (renders nothing)
let noNode: t<'msg> = Text("")

// ── HTML elements ──────────────────────────────────────────────────

// Containers and structure
let div = (attrs, children) => node("div", attrs, children)
let span = (attrs, children) => node("span", attrs, children)
let p = (attrs, children) => node("p", attrs, children)
let br = (): t<'msg> => Element("br", [], [])

// Headings
let h1 = (attrs, children) => node("h1", attrs, children)
let h2 = (attrs, children) => node("h2", attrs, children)
let h3 = (attrs, children) => node("h3", attrs, children)
let h4 = (attrs, children) => node("h4", attrs, children)
let h5 = (attrs, children) => node("h5", attrs, children)
let h6 = (attrs, children) => node("h6", attrs, children)

// Interactive elements
let button = (attrs, children) => node("button", attrs, children)
let input = (attrs, children) => node("input", attrs, children)
let textarea = (attrs, children) => node("textarea", attrs, children)
let label = (attrs, children) => node("label", attrs, children)
let a = (attrs, children) => node("a", attrs, children)
let img = (attrs, children) => node("img", attrs, children)
let details = (attrs, children) => node("details", attrs, children)
let summary = (attrs, children) => node("summary", attrs, children)
let dialog = (attrs, children) => node("dialog", attrs, children)

// Lists
let ul = (attrs, children) => node("ul", attrs, children)
let ol = (attrs, children) => node("ol", attrs, children)
let li = (attrs, children) => node("li", attrs, children)
let dl = (attrs, children) => node("dl", attrs, children)
let dt = (attrs, children) => node("dt", attrs, children)
let dd = (attrs, children) => node("dd", attrs, children)

// Form elements
let form = (attrs, children) => node("form", attrs, children)
let select = (attrs, children) => node("select", attrs, children)
let option' = (attrs, children) => node("option", attrs, children)
let optgroup = (attrs, children) => node("optgroup", attrs, children)
let fieldset = (attrs, children) => node("fieldset", attrs, children)
let legend = (attrs, children) => node("legend", attrs, children)
let datalist = (attrs, children) => node("datalist", attrs, children)
let output = (attrs, children) => node("output", attrs, children)
let progress = (attrs, children) => node("progress", attrs, children)
let meter = (attrs, children) => node("meter", attrs, children)

// Semantic elements
let header = (attrs, children) => node("header", attrs, children)
let footer = (attrs, children) => node("footer", attrs, children)
let main = (attrs, children) => node("main", attrs, children)
let nav = (attrs, children) => node("nav", attrs, children)
let section = (attrs, children) => node("section", attrs, children)
let article = (attrs, children) => node("article", attrs, children)
let aside = (attrs, children) => node("aside", attrs, children)
let figure = (attrs, children) => node("figure", attrs, children)
let figcaption = (attrs, children) => node("figcaption", attrs, children)
let address = (attrs, children) => node("address", attrs, children)
let time = (attrs, children) => node("time", attrs, children)
let mark = (attrs, children) => node("mark", attrs, children)

// Table elements
let table = (attrs, children) => node("table", attrs, children)
let thead = (attrs, children) => node("thead", attrs, children)
let tbody = (attrs, children) => node("tbody", attrs, children)
let tfoot = (attrs, children) => node("tfoot", attrs, children)
let tr = (attrs, children) => node("tr", attrs, children)
let th = (attrs, children) => node("th", attrs, children)
let td = (attrs, children) => node("td", attrs, children)
let caption = (attrs, children) => node("caption", attrs, children)
let colgroup = (attrs, children) => node("colgroup", attrs, children)
let col = (attrs, children) => node("col", attrs, children)

// Text formatting
let pre = (attrs, children) => node("pre", attrs, children)
let code = (attrs, children) => node("code", attrs, children)
let strong = (attrs, children) => node("strong", attrs, children)
let em = (attrs, children) => node("em", attrs, children)
let small = (attrs, children) => node("small", attrs, children)
let sub = (attrs, children) => node("sub", attrs, children)
let sup = (attrs, children) => node("sup", attrs, children)
let abbr = (attrs, children) => node("abbr", attrs, children)
let blockquote = (attrs, children) => node("blockquote", attrs, children)
let cite = (attrs, children) => node("cite", attrs, children)
let del = (attrs, children) => node("del", attrs, children)
let ins = (attrs, children) => node("ins", attrs, children)
let kbd = (attrs, children) => node("kbd", attrs, children)
let samp = (attrs, children) => node("samp", attrs, children)
let var = (attrs, children) => node("var", attrs, children)
let hr = (): t<'msg> => Element("hr", [], [])

// Embedded content
let audio = (attrs, children) => node("audio", attrs, children)
let video = (attrs, children) => node("video", attrs, children)
let source = (attrs, children) => node("source", attrs, children)
let canvas = (attrs, children) => node("canvas", attrs, children)
let picture = (attrs, children) => node("picture", attrs, children)
let iframe = (attrs, children) => node("iframe", attrs, children)

/// Attribute helpers module
module Attrs = {
  // Basic
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
  let tabIndex = Tea_Vdom.tabIndex
  let noProp = Tea_Vdom.noProp
  let prop = Tea_Vdom.prop

  // Form
  let for_ = Tea_Vdom.for_
  let required = Tea_Vdom.required
  let readonly = Tea_Vdom.readonly
  let autofocus = Tea_Vdom.autofocus
  let autocomplete = Tea_Vdom.autocomplete
  let pattern = Tea_Vdom.pattern
  let multiple = Tea_Vdom.multiple
  let accept = Tea_Vdom.accept
  let min = Tea_Vdom.min
  let max = Tea_Vdom.max
  let step = Tea_Vdom.step
  let maxLength = Tea_Vdom.maxLength
  let minLength = Tea_Vdom.minLength
  let action = Tea_Vdom.action
  let method = Tea_Vdom.method
  let cols = Tea_Vdom.cols
  let rows = Tea_Vdom.rows
  let noValidate = Tea_Vdom.noValidate

  // Media/embed
  let width = Tea_Vdom.width
  let height = Tea_Vdom.height
  let target = Tea_Vdom.target
  let download = Tea_Vdom.download
  let rel = Tea_Vdom.rel
  let hidden = Tea_Vdom.hidden

  // Interaction
  let draggable = Tea_Vdom.draggable
  let contentEditable = Tea_Vdom.contentEditable
  let spellCheck = Tea_Vdom.spellCheck

  // Table
  let colspan = Tea_Vdom.colspan
  let rowspan = Tea_Vdom.rowspan

  // Data attributes
  let data_ = Tea_Vdom.data_

  // ARIA accessibility
  let ariaLabel = Tea_Vdom.ariaLabel
  let ariaLive = Tea_Vdom.ariaLive
  let ariaExpanded = Tea_Vdom.ariaExpanded
  let ariaHidden = Tea_Vdom.ariaHidden
  let ariaPressed = Tea_Vdom.ariaPressed
  let ariaCurrent = Tea_Vdom.ariaCurrent
  let ariaValueNow = Tea_Vdom.ariaValueNow
  let ariaValueMin = Tea_Vdom.ariaValueMin
  let ariaValueMax = Tea_Vdom.ariaValueMax
  let ariaDescribedBy = Tea_Vdom.ariaDescribedBy
  let ariaChecked = Tea_Vdom.ariaChecked
  let ariaSelected = Tea_Vdom.ariaSelected
  let ariaControls = Tea_Vdom.ariaControls
  let ariaLabelledBy = Tea_Vdom.ariaLabelledBy
  let ariaRequired = Tea_Vdom.ariaRequired
  let ariaInvalid = Tea_Vdom.ariaInvalid
  let ariaDisabled = Tea_Vdom.ariaDisabled
  let ariaSort = Tea_Vdom.ariaSort
  let ariaOrientation = Tea_Vdom.ariaOrientation
  let ariaModal = Tea_Vdom.ariaModal
  let role = Tea_Vdom.role
  let selected = Tea_Vdom.selected
}

/// Event helpers module
module Events = {
  // Mouse
  let onClick = Tea_Vdom.onClick
  let onDoubleClick = Tea_Vdom.onDoubleClick
  let onContextMenu = Tea_Vdom.onContextMenu
  let onMouseDown = Tea_Vdom.onMouseDown
  let onMouseUp = Tea_Vdom.onMouseUp
  let onMouseEnter = Tea_Vdom.onMouseEnter
  let onMouseLeave = Tea_Vdom.onMouseLeave
  let onMouseOver = Tea_Vdom.onMouseOver
  let onMouseOut = Tea_Vdom.onMouseOut

  // Pointer (unified mouse/touch/pen)
  let onPointerDown = Tea_Vdom.onPointerDown
  let onPointerUp = Tea_Vdom.onPointerUp
  let onPointerMove = Tea_Vdom.onPointerMove
  let onPointerEnter = Tea_Vdom.onPointerEnter
  let onPointerLeave = Tea_Vdom.onPointerLeave
  let onPointerCancel = Tea_Vdom.onPointerCancel

  // Touch
  let onTouchStart = Tea_Vdom.onTouchStart
  let onTouchEnd = Tea_Vdom.onTouchEnd
  let onTouchMove = Tea_Vdom.onTouchMove
  let onTouchCancel = Tea_Vdom.onTouchCancel

  // Form
  let onInput = Tea_Vdom.onInput
  let onChange = Tea_Vdom.onChange
  let onSubmit = Tea_Vdom.onSubmit
  let onReset = Tea_Vdom.onReset

  // Focus
  let onFocus = Tea_Vdom.onFocus
  let onBlur = Tea_Vdom.onBlur

  // Keyboard
  let onKeyDown = Tea_Vdom.onKeyDown
  let onKeyUp = Tea_Vdom.onKeyUp
  let onKeyPress = Tea_Vdom.onKeyPress

  // Drag and drop
  let onDragStart = Tea_Vdom.onDragStart
  let onDrag = Tea_Vdom.onDrag
  let onDragEnd = Tea_Vdom.onDragEnd
  let onDragEnter = Tea_Vdom.onDragEnter
  let onDragLeave = Tea_Vdom.onDragLeave
  let onDragOver = Tea_Vdom.onDragOver
  let onDrop = Tea_Vdom.onDrop

  // Scroll
  let onScroll = Tea_Vdom.onScroll

  // Animation/transition
  let onAnimationEnd = Tea_Vdom.onAnimationEnd
  let onAnimationStart = Tea_Vdom.onAnimationStart
  let onTransitionEnd = Tea_Vdom.onTransitionEnd

  // Clipboard
  let onCopy = Tea_Vdom.onCopy
  let onCut = Tea_Vdom.onCut
  let onPaste = Tea_Vdom.onPaste

  // Wheel
  let onWheel = Tea_Vdom.onWheel
}

/// Map the message type of a virtual DOM tree
let map = Tea_Vdom.map
