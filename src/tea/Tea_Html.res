// SPDX-License-Identifier: MPL-2.0
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

/// HTML `<div>` element constructor.
let div = (attrs, children) => node("div", attrs, children)

/// HTML `<span>` element constructor.
let span = (attrs, children) => node("span", attrs, children)

/// HTML `<p>` (paragraph) element constructor.
let p = (attrs, children) => node("p", attrs, children)

/// HTML `<br>` (line break) void element.
let br = (): t<'msg> => Element("br", [], [])

// Headings

/// HTML `<h1>` heading element constructor.
let h1 = (attrs, children) => node("h1", attrs, children)

/// HTML `<h2>` heading element constructor.
let h2 = (attrs, children) => node("h2", attrs, children)

/// HTML `<h3>` heading element constructor.
let h3 = (attrs, children) => node("h3", attrs, children)

/// HTML `<h4>` heading element constructor.
let h4 = (attrs, children) => node("h4", attrs, children)

/// HTML `<h5>` heading element constructor.
let h5 = (attrs, children) => node("h5", attrs, children)

/// HTML `<h6>` heading element constructor.
let h6 = (attrs, children) => node("h6", attrs, children)

// Interactive elements

/// HTML `<button>` element constructor.
let button = (attrs, children) => node("button", attrs, children)

/// HTML `<input>` element constructor.
let input = (attrs, children) => node("input", attrs, children)

/// HTML `<textarea>` element constructor.
let textarea = (attrs, children) => node("textarea", attrs, children)

/// HTML `<label>` element constructor.
let label = (attrs, children) => node("label", attrs, children)

/// HTML `<a>` (anchor/link) element constructor.
let a = (attrs, children) => node("a", attrs, children)

/// HTML `<img>` (image) element constructor.
let img = (attrs, children) => node("img", attrs, children)

/// HTML `<details>` (disclosure widget) element constructor.
let details = (attrs, children) => node("details", attrs, children)

/// HTML `<summary>` element constructor (used inside `<details>`).
let summary = (attrs, children) => node("summary", attrs, children)

/// HTML `<dialog>` (modal/non-modal dialog) element constructor.
let dialog = (attrs, children) => node("dialog", attrs, children)

// Lists

/// HTML `<ul>` (unordered list) element constructor.
let ul = (attrs, children) => node("ul", attrs, children)

/// HTML `<ol>` (ordered list) element constructor.
let ol = (attrs, children) => node("ol", attrs, children)

/// HTML `<li>` (list item) element constructor.
let li = (attrs, children) => node("li", attrs, children)

/// HTML `<dl>` (description list) element constructor.
let dl = (attrs, children) => node("dl", attrs, children)

/// HTML `<dt>` (description term) element constructor.
let dt = (attrs, children) => node("dt", attrs, children)

/// HTML `<dd>` (description details) element constructor.
let dd = (attrs, children) => node("dd", attrs, children)

// Form elements

/// HTML `<form>` element constructor.
let form = (attrs, children) => node("form", attrs, children)

/// HTML `<select>` (dropdown) element constructor.
let select = (attrs, children) => node("select", attrs, children)

/// HTML `<option>` element constructor. Suffixed with `'` to avoid keyword conflict.
let option' = (attrs, children) => node("option", attrs, children)

/// HTML `<optgroup>` (option group) element constructor.
let optgroup = (attrs, children) => node("optgroup", attrs, children)

/// HTML `<fieldset>` element constructor.
let fieldset = (attrs, children) => node("fieldset", attrs, children)

/// HTML `<legend>` element constructor (used inside `<fieldset>`).
let legend = (attrs, children) => node("legend", attrs, children)

/// HTML `<datalist>` element constructor.
let datalist = (attrs, children) => node("datalist", attrs, children)

/// HTML `<output>` element constructor.
let output = (attrs, children) => node("output", attrs, children)

/// HTML `<progress>` element constructor.
let progress = (attrs, children) => node("progress", attrs, children)

/// HTML `<meter>` element constructor.
let meter = (attrs, children) => node("meter", attrs, children)

// Semantic elements

/// HTML `<header>` element constructor.
let header = (attrs, children) => node("header", attrs, children)

/// HTML `<footer>` element constructor.
let footer = (attrs, children) => node("footer", attrs, children)

/// HTML `<main>` element constructor.
let main = (attrs, children) => node("main", attrs, children)

/// HTML `<nav>` (navigation) element constructor.
let nav = (attrs, children) => node("nav", attrs, children)

/// HTML `<section>` element constructor.
let section = (attrs, children) => node("section", attrs, children)

/// HTML `<article>` element constructor.
let article = (attrs, children) => node("article", attrs, children)

/// HTML `<aside>` element constructor.
let aside = (attrs, children) => node("aside", attrs, children)

/// HTML `<figure>` element constructor.
let figure = (attrs, children) => node("figure", attrs, children)

/// HTML `<figcaption>` element constructor.
let figcaption = (attrs, children) => node("figcaption", attrs, children)

/// HTML `<address>` element constructor.
let address = (attrs, children) => node("address", attrs, children)

/// HTML `<time>` element constructor.
let time = (attrs, children) => node("time", attrs, children)

/// HTML `<mark>` (highlighted text) element constructor.
let mark = (attrs, children) => node("mark", attrs, children)

// Table elements

/// HTML `<table>` element constructor.
let table = (attrs, children) => node("table", attrs, children)

/// HTML `<thead>` (table head) element constructor.
let thead = (attrs, children) => node("thead", attrs, children)

/// HTML `<tbody>` (table body) element constructor.
let tbody = (attrs, children) => node("tbody", attrs, children)

/// HTML `<tfoot>` (table foot) element constructor.
let tfoot = (attrs, children) => node("tfoot", attrs, children)

/// HTML `<tr>` (table row) element constructor.
let tr = (attrs, children) => node("tr", attrs, children)

/// HTML `<th>` (table header cell) element constructor.
let th = (attrs, children) => node("th", attrs, children)

/// HTML `<td>` (table data cell) element constructor.
let td = (attrs, children) => node("td", attrs, children)

/// HTML `<caption>` (table caption) element constructor.
let caption = (attrs, children) => node("caption", attrs, children)

/// HTML `<colgroup>` element constructor.
let colgroup = (attrs, children) => node("colgroup", attrs, children)

/// HTML `<col>` element constructor.
let col = (attrs, children) => node("col", attrs, children)

// Text formatting

/// HTML `<pre>` (preformatted text) element constructor.
let pre = (attrs, children) => node("pre", attrs, children)

/// HTML `<code>` (inline code) element constructor.
let code = (attrs, children) => node("code", attrs, children)

/// HTML `<strong>` (bold/important text) element constructor.
let strong = (attrs, children) => node("strong", attrs, children)

/// HTML `<em>` (emphasised text) element constructor.
let em = (attrs, children) => node("em", attrs, children)

/// HTML `<small>` element constructor.
let small = (attrs, children) => node("small", attrs, children)

/// HTML `<sub>` (subscript) element constructor.
let sub = (attrs, children) => node("sub", attrs, children)

/// HTML `<sup>` (superscript) element constructor.
let sup = (attrs, children) => node("sup", attrs, children)

/// HTML `<abbr>` (abbreviation) element constructor.
let abbr = (attrs, children) => node("abbr", attrs, children)

/// HTML `<blockquote>` element constructor.
let blockquote = (attrs, children) => node("blockquote", attrs, children)

/// HTML `<cite>` element constructor.
let cite = (attrs, children) => node("cite", attrs, children)

/// HTML `<del>` (deleted text) element constructor.
let del = (attrs, children) => node("del", attrs, children)

/// HTML `<ins>` (inserted text) element constructor.
let ins = (attrs, children) => node("ins", attrs, children)

/// HTML `<kbd>` (keyboard input) element constructor.
let kbd = (attrs, children) => node("kbd", attrs, children)

/// HTML `<samp>` (sample output) element constructor.
let samp = (attrs, children) => node("samp", attrs, children)

/// HTML `<var>` (variable) element constructor.
let var = (attrs, children) => node("var", attrs, children)

/// HTML `<hr>` (horizontal rule) void element.
let hr = (): t<'msg> => Element("hr", [], [])

// Embedded content

/// HTML `<audio>` element constructor.
let audio = (attrs, children) => node("audio", attrs, children)

/// HTML `<video>` element constructor.
let video = (attrs, children) => node("video", attrs, children)

/// HTML `<source>` element constructor (used inside `<audio>`/`<video>`).
let source = (attrs, children) => node("source", attrs, children)

/// HTML `<canvas>` element constructor.
let canvas = (attrs, children) => node("canvas", attrs, children)

/// HTML `<picture>` element constructor.
let picture = (attrs, children) => node("picture", attrs, children)

/// HTML `<iframe>` element constructor.
let iframe = (attrs, children) => node("iframe", attrs, children)

/// HTML attribute constructors.
///
/// All standard HTML attributes, form attributes, ARIA attributes,
/// and data attributes are available as type-safe functions.
module Attrs = {
  // Basic

  /// Sets the CSS class attribute.
  let class_ = Tea_Vdom.class_

  /// Sets the element id attribute.
  let id = Tea_Vdom.id

  /// Sets an inline CSS style property and value.
  let style = Tea_Vdom.style

  /// Sets the placeholder text for input/textarea elements.
  let placeholder = Tea_Vdom.placeholder

  /// Sets the value attribute (for inputs, selects, textareas).
  let value = Tea_Vdom.value

  /// Sets the title (tooltip) attribute.
  let title = Tea_Vdom.title

  /// Sets the href attribute (for links).
  let href = Tea_Vdom.href

  /// Sets the src attribute (for images, scripts, etc.).
  let src = Tea_Vdom.src

  /// Sets the alt text attribute (for images).
  let alt = Tea_Vdom.alt

  /// Sets the disabled boolean attribute.
  let disabled = Tea_Vdom.disabled

  /// Sets the checked boolean attribute (for checkboxes/radios).
  let checked = Tea_Vdom.checked

  /// Sets the type attribute (e.g. "text", "password", "submit").
  let type_ = Tea_Vdom.type_

  /// Sets the name attribute (for form elements).
  let name = Tea_Vdom.name

  /// Sets the tabindex attribute for keyboard navigation order.
  let tabIndex = Tea_Vdom.tabIndex

  /// A no-op attribute that renders nothing. Use in conditional expressions.
  let noProp = Tea_Vdom.noProp

  /// Generic property setter for attributes not covered by named helpers.
  let prop = Tea_Vdom.prop

  // Form

  /// Sets the `for` attribute (associates label with input). Suffixed with `_` to avoid keyword conflict.
  let for_ = Tea_Vdom.for_

  /// Sets the required boolean attribute.
  let required = Tea_Vdom.required

  /// Sets the readonly boolean attribute.
  let readonly = Tea_Vdom.readonly

  /// Sets the autofocus boolean attribute.
  let autofocus = Tea_Vdom.autofocus

  /// Sets the autocomplete attribute (e.g. "on", "off", "email").
  let autocomplete = Tea_Vdom.autocomplete

  /// Sets the pattern attribute (regex for input validation).
  let pattern = Tea_Vdom.pattern

  /// Sets the multiple boolean attribute (for select/file inputs).
  let multiple = Tea_Vdom.multiple

  /// Sets the accept attribute (MIME types for file inputs).
  let accept = Tea_Vdom.accept

  /// Sets the min attribute (minimum value for number/date inputs).
  let min = Tea_Vdom.min

  /// Sets the max attribute (maximum value for number/date inputs).
  let max = Tea_Vdom.max

  /// Sets the step attribute (increment for number inputs).
  let step = Tea_Vdom.step

  /// Sets the maxlength attribute (max character count).
  let maxLength = Tea_Vdom.maxLength

  /// Sets the minlength attribute (min character count).
  let minLength = Tea_Vdom.minLength

  /// Sets the action URL for form submission.
  let action = Tea_Vdom.action

  /// Sets the form method (e.g. "GET", "POST").
  let method = Tea_Vdom.method

  /// Sets the number of visible columns for a textarea.
  let cols = Tea_Vdom.cols

  /// Sets the number of visible rows for a textarea.
  let rows = Tea_Vdom.rows

  /// Sets the novalidate boolean attribute on forms.
  let noValidate = Tea_Vdom.noValidate

  // Media/embed

  /// Sets the width attribute.
  let width = Tea_Vdom.width

  /// Sets the height attribute.
  let height = Tea_Vdom.height

  /// Sets the target attribute (e.g. "_blank" for links).
  let target = Tea_Vdom.target

  /// Sets the download attribute (triggers file download on click).
  let download = Tea_Vdom.download

  /// Sets the rel attribute (link relationship, e.g. "noopener").
  let rel = Tea_Vdom.rel

  /// Sets the hidden boolean attribute.
  let hidden = Tea_Vdom.hidden

  // Interaction

  /// Sets the draggable boolean attribute.
  let draggable = Tea_Vdom.draggable

  /// Sets the contenteditable boolean attribute.
  let contentEditable = Tea_Vdom.contentEditable

  /// Sets the spellcheck boolean attribute.
  let spellCheck = Tea_Vdom.spellCheck

  // Table

  /// Sets the colspan attribute (number of columns a cell spans).
  let colspan = Tea_Vdom.colspan

  /// Sets the rowspan attribute (number of rows a cell spans).
  let rowspan = Tea_Vdom.rowspan

  // Data attributes

  /// Sets a data-* attribute. `data_("key", "val")` renders as `data-key="val"`.
  let data_ = Tea_Vdom.data_

  // ARIA accessibility

  /// Sets the aria-label attribute (accessible name).
  let ariaLabel = Tea_Vdom.ariaLabel

  /// Sets the aria-live attribute ("polite", "assertive", "off").
  let ariaLive = Tea_Vdom.ariaLive

  /// Sets the aria-expanded boolean attribute.
  let ariaExpanded = Tea_Vdom.ariaExpanded

  /// Sets the aria-hidden boolean attribute.
  let ariaHidden = Tea_Vdom.ariaHidden

  /// Sets the aria-pressed boolean attribute.
  let ariaPressed = Tea_Vdom.ariaPressed

  /// Sets the aria-current attribute (e.g. "page", "step", "true").
  let ariaCurrent = Tea_Vdom.ariaCurrent

  /// Sets the aria-valuenow attribute (current value of a range widget).
  let ariaValueNow = Tea_Vdom.ariaValueNow

  /// Sets the aria-valuemin attribute (minimum value of a range widget).
  let ariaValueMin = Tea_Vdom.ariaValueMin

  /// Sets the aria-valuemax attribute (maximum value of a range widget).
  let ariaValueMax = Tea_Vdom.ariaValueMax

  /// Sets the aria-describedby attribute (references describing element id).
  let ariaDescribedBy = Tea_Vdom.ariaDescribedBy

  /// Sets the aria-checked boolean attribute.
  let ariaChecked = Tea_Vdom.ariaChecked

  /// Sets the aria-selected boolean attribute.
  let ariaSelected = Tea_Vdom.ariaSelected

  /// Sets the aria-controls attribute (references controlled element id).
  let ariaControls = Tea_Vdom.ariaControls

  /// Sets the aria-labelledby attribute (references labelling element id).
  let ariaLabelledBy = Tea_Vdom.ariaLabelledBy

  /// Sets the aria-required boolean attribute.
  let ariaRequired = Tea_Vdom.ariaRequired

  /// Sets the aria-invalid boolean attribute.
  let ariaInvalid = Tea_Vdom.ariaInvalid

  /// Sets the aria-disabled boolean attribute.
  let ariaDisabled = Tea_Vdom.ariaDisabled

  /// Sets the aria-sort attribute ("ascending", "descending", "none").
  let ariaSort = Tea_Vdom.ariaSort

  /// Sets the aria-orientation attribute ("horizontal", "vertical").
  let ariaOrientation = Tea_Vdom.ariaOrientation

  /// Sets the aria-modal boolean attribute.
  let ariaModal = Tea_Vdom.ariaModal

  /// Sets the role attribute (ARIA landmark role, e.g. "button", "dialog").
  let role = Tea_Vdom.role

  /// Sets the selected boolean attribute (for option elements).
  let selected = Tea_Vdom.selected
}

/// DOM event handler constructors.
///
/// Mouse, pointer, touch, keyboard, form, drag-and-drop, clipboard,
/// scroll, animation, and wheel events.
module Events = {
  // Mouse

  /// Fires when the element is clicked. Dispatches the given message.
  let onClick = Tea_Vdom.onClick

  /// Fires on double-click.
  let onDoubleClick = Tea_Vdom.onDoubleClick

  /// Fires on right-click (context menu). Prevents the default browser menu.
  let onContextMenu = Tea_Vdom.onContextMenu

  /// Fires when a mouse button is pressed down.
  let onMouseDown = Tea_Vdom.onMouseDown

  /// Fires when a mouse button is released.
  let onMouseUp = Tea_Vdom.onMouseUp

  /// Fires when the cursor enters the element (does not bubble).
  let onMouseEnter = Tea_Vdom.onMouseEnter

  /// Fires when the cursor leaves the element (does not bubble).
  let onMouseLeave = Tea_Vdom.onMouseLeave

  /// Fires when the cursor moves over the element (bubbles).
  let onMouseOver = Tea_Vdom.onMouseOver

  /// Fires when the cursor moves out of the element (bubbles).
  let onMouseOut = Tea_Vdom.onMouseOut

  // Pointer (unified mouse/touch/pen)

  /// Fires when a pointer (mouse/touch/pen) is pressed down.
  let onPointerDown = Tea_Vdom.onPointerDown

  /// Fires when a pointer is released.
  let onPointerUp = Tea_Vdom.onPointerUp

  /// Fires when a pointer moves.
  let onPointerMove = Tea_Vdom.onPointerMove

  /// Fires when a pointer enters the element.
  let onPointerEnter = Tea_Vdom.onPointerEnter

  /// Fires when a pointer leaves the element.
  let onPointerLeave = Tea_Vdom.onPointerLeave

  /// Fires when a pointer interaction is cancelled.
  let onPointerCancel = Tea_Vdom.onPointerCancel

  // Touch

  /// Fires when a touch point is placed on the touch surface.
  let onTouchStart = Tea_Vdom.onTouchStart

  /// Fires when a touch point is removed from the touch surface.
  let onTouchEnd = Tea_Vdom.onTouchEnd

  /// Fires when a touch point moves along the touch surface.
  let onTouchMove = Tea_Vdom.onTouchMove

  /// Fires when a touch interaction is cancelled.
  let onTouchCancel = Tea_Vdom.onTouchCancel

  // Form

  /// Fires on input value change. Handler receives the current input value string.
  let onInput = Tea_Vdom.onInput

  /// Fires when the input value is committed (blur or Enter). Handler receives the value string.
  let onChange = Tea_Vdom.onChange

  /// Fires on form submission. Prevents the default submit action.
  let onSubmit = Tea_Vdom.onSubmit

  /// Fires on form reset.
  let onReset = Tea_Vdom.onReset

  // Focus

  /// Fires when the element gains focus.
  let onFocus = Tea_Vdom.onFocus

  /// Fires when the element loses focus.
  let onBlur = Tea_Vdom.onBlur

  // Keyboard

  /// Fires on key down. Handler receives the key string and returns `Some(msg)` to handle or `None` to ignore.
  let onKeyDown = Tea_Vdom.onKeyDown

  /// Fires on key up. Handler receives the key string and returns `Some(msg)` to handle or `None` to ignore.
  let onKeyUp = Tea_Vdom.onKeyUp

  /// Fires on key press (deprecated in browsers; prefer onKeyDown).
  let onKeyPress = Tea_Vdom.onKeyPress

  // Drag and drop

  /// Fires when a drag operation starts.
  let onDragStart = Tea_Vdom.onDragStart

  /// Fires continuously while dragging.
  let onDrag = Tea_Vdom.onDrag

  /// Fires when a drag operation ends.
  let onDragEnd = Tea_Vdom.onDragEnd

  /// Fires when a dragged item enters a valid drop target.
  let onDragEnter = Tea_Vdom.onDragEnter

  /// Fires when a dragged item leaves a valid drop target.
  let onDragLeave = Tea_Vdom.onDragLeave

  /// Fires when a dragged item is over a valid drop target. Prevents default to allow dropping.
  let onDragOver = Tea_Vdom.onDragOver

  /// Fires when a dragged item is dropped. Prevents default browser handling.
  let onDrop = Tea_Vdom.onDrop

  // Scroll

  /// Fires when the element is scrolled.
  let onScroll = Tea_Vdom.onScroll

  // Animation/transition

  /// Fires when a CSS animation completes.
  let onAnimationEnd = Tea_Vdom.onAnimationEnd

  /// Fires when a CSS animation starts.
  let onAnimationStart = Tea_Vdom.onAnimationStart

  /// Fires when a CSS transition completes.
  let onTransitionEnd = Tea_Vdom.onTransitionEnd

  // Clipboard

  /// Fires when content is copied.
  let onCopy = Tea_Vdom.onCopy

  /// Fires when content is cut.
  let onCut = Tea_Vdom.onCut

  /// Fires when content is pasted.
  let onPaste = Tea_Vdom.onPaste

  // Wheel

  /// Fires on mouse wheel scroll.
  let onWheel = Tea_Vdom.onWheel
}

/// Map the message type of a virtual DOM tree
let map = Tea_Vdom.map
