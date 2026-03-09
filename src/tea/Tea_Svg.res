// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// Tea_Svg.res — SVG element constructors with proper namespace handling.

open Tea_Vdom

let node = (tag: string, attrs: list<attribute<'msg>>, children: list<t<'msg>>): t<'msg> => {
  Element(tag, List.toArray(attrs), List.toArray(children))
}

// Container elements
let svg = (attrs, children) => node("svg", attrs, children)
let g = (attrs, children) => node("g", attrs, children)
let defs = (attrs, children) => node("defs", attrs, children)
let symbol = (attrs, children) => node("symbol", attrs, children)
let use = (attrs, children) => node("use", attrs, children)
let foreignObject = (attrs, children) => node("foreignObject", attrs, children)

// Shape elements
let circle = (attrs, children) => node("circle", attrs, children)
let ellipse = (attrs, children) => node("ellipse", attrs, children)
let line = (attrs, children) => node("line", attrs, children)
let path = (attrs, children) => node("path", attrs, children)
let polygon = (attrs, children) => node("polygon", attrs, children)
let polyline = (attrs, children) => node("polyline", attrs, children)
let rect = (attrs, children) => node("rect", attrs, children)

// Text elements
let text' = (attrs, children) => node("text", attrs, children)
let tspan = (attrs, children) => node("tspan", attrs, children)
let textPath = (attrs, children) => node("textPath", attrs, children)

// Gradient elements
let linearGradient = (attrs, children) => node("linearGradient", attrs, children)
let radialGradient = (attrs, children) => node("radialGradient", attrs, children)
let stop = (attrs, children) => node("stop", attrs, children)

// Clipping and masking
let clipPath = (attrs, children) => node("clipPath", attrs, children)
let mask = (attrs, children) => node("mask", attrs, children)
let pattern = (attrs, children) => node("pattern", attrs, children)
let marker = (attrs, children) => node("marker", attrs, children)

// Filter elements
let filter = (attrs, children) => node("filter", attrs, children)
let feGaussianBlur = (attrs, children) => node("feGaussianBlur", attrs, children)
let feOffset = (attrs, children) => node("feOffset", attrs, children)
let feBlend = (attrs, children) => node("feBlend", attrs, children)
let feColorMatrix = (attrs, children) => node("feColorMatrix", attrs, children)
let feComposite = (attrs, children) => node("feComposite", attrs, children)
let feFlood = (attrs, children) => node("feFlood", attrs, children)
let feMerge = (attrs, children) => node("feMerge", attrs, children)
let feMergeNode = (attrs, children) => node("feMergeNode", attrs, children)

// Animation elements
let animate = (attrs, children) => node("animate", attrs, children)
let animateTransform = (attrs, children) => node("animateTransform", attrs, children)
let set = (attrs, children) => node("set", attrs, children)

// Descriptive elements
let desc = (attrs, children) => node("desc", attrs, children)
let title = (attrs, children) => node("title", attrs, children)
let metadata = (attrs, children) => node("metadata", attrs, children)
let image = (attrs, children) => node("image", attrs, children)

// SVG-specific attributes
module Attrs = {
  let viewBox = (v: string): attribute<'msg> => Property("viewBox", v)
  let fill = (v: string): attribute<'msg> => Property("fill", v)
  let stroke = (v: string): attribute<'msg> => Property("stroke", v)
  let strokeWidth = (v: string): attribute<'msg> => Property("stroke-width", v)
  let strokeLinecap = (v: string): attribute<'msg> => Property("stroke-linecap", v)
  let strokeLinejoin = (v: string): attribute<'msg> => Property("stroke-linejoin", v)
  let strokeDasharray = (v: string): attribute<'msg> => Property("stroke-dasharray", v)
  let strokeDashoffset = (v: string): attribute<'msg> => Property("stroke-dashoffset", v)
  let strokeOpacity = (v: string): attribute<'msg> => Property("stroke-opacity", v)
  let fillOpacity = (v: string): attribute<'msg> => Property("fill-opacity", v)
  let fillRule = (v: string): attribute<'msg> => Property("fill-rule", v)
  let opacity = (v: string): attribute<'msg> => Property("opacity", v)
  let transform = (v: string): attribute<'msg> => Property("transform", v)
  let d = (v: string): attribute<'msg> => Property("d", v)
  let x = (v: string): attribute<'msg> => Property("x", v)
  let y = (v: string): attribute<'msg> => Property("y", v)
  let x1 = (v: string): attribute<'msg> => Property("x1", v)
  let y1 = (v: string): attribute<'msg> => Property("y1", v)
  let x2 = (v: string): attribute<'msg> => Property("x2", v)
  let y2 = (v: string): attribute<'msg> => Property("y2", v)
  let cx = (v: string): attribute<'msg> => Property("cx", v)
  let cy = (v: string): attribute<'msg> => Property("cy", v)
  let r = (v: string): attribute<'msg> => Property("r", v)
  let rx = (v: string): attribute<'msg> => Property("rx", v)
  let ry = (v: string): attribute<'msg> => Property("ry", v)
  let width = (v: string): attribute<'msg> => Property("width", v)
  let height = (v: string): attribute<'msg> => Property("height", v)
  let points = (v: string): attribute<'msg> => Property("points", v)
  let offset = (v: string): attribute<'msg> => Property("offset", v)
  let stopColor = (v: string): attribute<'msg> => Property("stop-color", v)
  let stopOpacity = (v: string): attribute<'msg> => Property("stop-opacity", v)
  let gradientUnits = (v: string): attribute<'msg> => Property("gradientUnits", v)
  let textAnchor = (v: string): attribute<'msg> => Property("text-anchor", v)
  let dominantBaseline = (v: string): attribute<'msg> => Property("dominant-baseline", v)
  let fontSize = (v: string): attribute<'msg> => Property("font-size", v)
  let fontFamily = (v: string): attribute<'msg> => Property("font-family", v)
  let fontWeight = (v: string): attribute<'msg> => Property("font-weight", v)
  let in_ = (v: string): attribute<'msg> => Property("in", v)
  let in2 = (v: string): attribute<'msg> => Property("in2", v)
  let result = (v: string): attribute<'msg> => Property("result", v)
  let stdDeviation = (v: string): attribute<'msg> => Property("stdDeviation", v)
  let dx = (v: string): attribute<'msg> => Property("dx", v)
  let dy = (v: string): attribute<'msg> => Property("dy", v)
  let xlinkHref = (v: string): attribute<'msg> => Property("href", v)
  let clipPathRef = (v: string): attribute<'msg> => Property("clip-path", v)
  let maskRef = (v: string): attribute<'msg> => Property("mask", v)
  let filterRef = (v: string): attribute<'msg> => Property("filter", v)
  let class_ = Tea_Vdom.class_
  let id = Tea_Vdom.id
  let style = Tea_Vdom.style
}
