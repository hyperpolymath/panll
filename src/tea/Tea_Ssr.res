// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// Tea_Ssr.res — Server-side rendering: virtual DOM to HTML string.
//
// Renders Tea_Vdom nodes to HTML without requiring a DOM.
// Useful for: testing, snapshot assertions, SSR, static site generation.

open Tea_Vdom

/// Void elements that must not have closing tags
let isVoidElement = (tag: string): bool => {
  switch tag {
  | "area" | "base" | "br" | "col" | "embed" | "hr" | "img" | "input"
  | "link" | "meta" | "param" | "source" | "track" | "wbr" =>
    true
  | _ => false
  }
}

/// Escape HTML special characters
let escapeHtml = (s: string): string => {
  let r = ref(s)
  r := String.replaceAll(r.contents, "&", "&amp;")
  r := String.replaceAll(r.contents, "<", "&lt;")
  r := String.replaceAll(r.contents, ">", "&gt;")
  r := String.replaceAll(r.contents, "\"", "&quot;")
  r := String.replaceAll(r.contents, "'", "&#x27;")
  r.contents
}

/// Escape an attribute value
let escapeAttr = (s: string): string => {
  let r = ref(s)
  r := String.replaceAll(r.contents, "&", "&amp;")
  r := String.replaceAll(r.contents, "\"", "&quot;")
  r.contents
}

/// Render a single attribute to string
let renderAttr = (attr: attribute<'msg>): string => {
  switch attr {
  | Property(key, value) =>
    if key === "" {
      ""
    } else if key === "checked" || key === "disabled" || key === "readonly"
      || key === "required" || key === "autofocus" || key === "multiple"
      || key === "selected" || key === "hidden" || key === "novalidate" {
      if value === "true" { ` ${key}` } else { "" }
    } else {
      ` ${key}="${escapeAttr(value)}"`
    }
  | Style(_, _) => "" // Handled in renderAttrs
  | Event(_, _) | EventWithValue(_, _) | EventWithKey(_, _)
  | EventPreventDefault(_, _) | EventStopPropagation(_, _) => ""
  }
}

/// Render all attributes including collected styles
let renderAttrs = (attrs: array<attribute<'msg>>): string => {
  let propAttrs = ref("")
  let styles = ref("")

  Array.forEach(attrs, attr => {
    switch attr {
    | Style(prop, value) =>
      if String.length(styles.contents) > 0 {
        styles := styles.contents ++ "; "
      }
      styles := styles.contents ++ prop ++ ": " ++ value
    | _ =>
      propAttrs := propAttrs.contents ++ renderAttr(attr)
    }
  })

  if String.length(styles.contents) > 0 {
    propAttrs.contents ++ ` style="${escapeAttr(styles.contents)}"`
  } else {
    propAttrs.contents
  }
}

/// Render virtual DOM to compact HTML string
let rec toString = (vdom: t<'msg>): string => {
  switch vdom {
  | Text(s) => escapeHtml(s)
  | Element(tag, attrs, children) =>
    let attrStr = renderAttrs(attrs)
    if isVoidElement(tag) {
      `<${tag}${attrStr} />`
    } else {
      let childrenStr = Array.map(children, toString)->Array.join("")
      `<${tag}${attrStr}>${childrenStr}</${tag}>`
    }
  | KeyedElement(tag, attrs, keyedChildren) =>
    let attrStr = renderAttrs(attrs)
    if isVoidElement(tag) {
      `<${tag}${attrStr} />`
    } else {
      let childrenStr = Array.map(keyedChildren, ((_key, child)) => toString(child))->Array.join("")
      `<${tag}${attrStr}>${childrenStr}</${tag}>`
    }
  | Fragment(children) =>
    Array.map(children, toString)->Array.join("")
  }
}

/// Render with pretty-printing (indentation)
let toStringPretty = (vdom: t<'msg>, ~indent: int=2): string => {
  let indentStr = (level: int): string => String.repeat(" ", level * indent)

  let rec go = (v: t<'msg>, level: int): string => {
    switch v {
    | Text(s) => indentStr(level) ++ escapeHtml(s)
    | Element(tag, attrs, children) =>
      let attrStr = renderAttrs(attrs)
      let pad = indentStr(level)
      if isVoidElement(tag) {
        `${pad}<${tag}${attrStr} />`
      } else if Array.length(children) === 0 {
        `${pad}<${tag}${attrStr}></${tag}>`
      } else if Array.length(children) === 1 {
        switch Array.getUnsafe(children, 0) {
        | Text(s) => `${pad}<${tag}${attrStr}>${escapeHtml(s)}</${tag}>`
        | child =>
          let childStr = go(child, level + 1)
          `${pad}<${tag}${attrStr}>\n${childStr}\n${pad}</${tag}>`
        }
      } else {
        let childrenStr = Array.map(children, c => go(c, level + 1))->Array.join("\n")
        `${pad}<${tag}${attrStr}>\n${childrenStr}\n${pad}</${tag}>`
      }
    | KeyedElement(tag, attrs, keyedChildren) =>
      let attrStr = renderAttrs(attrs)
      let pad = indentStr(level)
      if Array.length(keyedChildren) === 0 {
        `${pad}<${tag}${attrStr}></${tag}>`
      } else {
        let childrenStr = Array.map(keyedChildren, ((_key, c)) => go(c, level + 1))->Array.join("\n")
        `${pad}<${tag}${attrStr}>\n${childrenStr}\n${pad}</${tag}>`
      }
    | Fragment(children) =>
      Array.map(children, c => go(c, level))->Array.join("\n")
    }
  }

  go(vdom, 0)
}

/// Render a full HTML document
let toDocument = (~title: string, ~head: string="", vdom: t<'msg>): string => {
  let body = toString(vdom)
  `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${escapeHtml(title)}</title>
  ${head}
</head>
<body>
  <div id="app">${body}</div>
</body>
</html>`
}
