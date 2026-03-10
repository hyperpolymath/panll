// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
/// Tea_Svg.res — SVG element constructors with proper namespace handling.
///
/// All SVG elements are created through `node` which builds virtual DOM
/// elements. The renderer detects SVG tags and uses `createElementNS` with
/// the SVG namespace URI automatically.

open Tea_Vdom

/// Create an SVG element node from lists of attributes and children.
let node = (tag: string, attrs: list<attribute<'msg>>, children: list<t<'msg>>): t<'msg> => {
  Element(tag, List.toArray(attrs), List.toArray(children))
}

// Container elements

/// SVG `<svg>` root container element.
let svg = (attrs, children) => node("svg", attrs, children)

/// SVG `<g>` group element (container for grouping elements).
let g = (attrs, children) => node("g", attrs, children)

/// SVG `<defs>` element (container for reusable definitions).
let defs = (attrs, children) => node("defs", attrs, children)

/// SVG `<symbol>` element (reusable graphic template).
let symbol = (attrs, children) => node("symbol", attrs, children)

/// SVG `<use>` element (references a `<symbol>` or other element by id).
let use = (attrs, children) => node("use", attrs, children)

/// SVG `<foreignObject>` element (embeds HTML content inside SVG).
let foreignObject = (attrs, children) => node("foreignObject", attrs, children)

// Shape elements

/// SVG `<circle>` element.
let circle = (attrs, children) => node("circle", attrs, children)

/// SVG `<ellipse>` element.
let ellipse = (attrs, children) => node("ellipse", attrs, children)

/// SVG `<line>` element.
let line = (attrs, children) => node("line", attrs, children)

/// SVG `<path>` element (arbitrary shapes via the `d` attribute).
let path = (attrs, children) => node("path", attrs, children)

/// SVG `<polygon>` element (closed shape from points).
let polygon = (attrs, children) => node("polygon", attrs, children)

/// SVG `<polyline>` element (open shape from points).
let polyline = (attrs, children) => node("polyline", attrs, children)

/// SVG `<rect>` element.
let rect = (attrs, children) => node("rect", attrs, children)

// Text elements

/// SVG `<text>` element. Suffixed with `'` to avoid conflict with `Tea_Vdom.text`.
let text' = (attrs, children) => node("text", attrs, children)

/// SVG `<tspan>` element (styled sub-range of text).
let tspan = (attrs, children) => node("tspan", attrs, children)

/// SVG `<textPath>` element (text along a path).
let textPath = (attrs, children) => node("textPath", attrs, children)

// Gradient elements

/// SVG `<linearGradient>` element.
let linearGradient = (attrs, children) => node("linearGradient", attrs, children)

/// SVG `<radialGradient>` element.
let radialGradient = (attrs, children) => node("radialGradient", attrs, children)

/// SVG `<stop>` element (gradient colour stop).
let stop = (attrs, children) => node("stop", attrs, children)

// Clipping and masking

/// SVG `<clipPath>` element (defines a clipping region).
let clipPath = (attrs, children) => node("clipPath", attrs, children)

/// SVG `<mask>` element (alpha/luminance masking).
let mask = (attrs, children) => node("mask", attrs, children)

/// SVG `<pattern>` element (tiling fill pattern).
let pattern = (attrs, children) => node("pattern", attrs, children)

/// SVG `<marker>` element (arrowheads/endpoints for lines).
let marker = (attrs, children) => node("marker", attrs, children)

// Filter elements

/// SVG `<filter>` container element.
let filter = (attrs, children) => node("filter", attrs, children)

/// SVG `<feGaussianBlur>` filter primitive.
let feGaussianBlur = (attrs, children) => node("feGaussianBlur", attrs, children)

/// SVG `<feOffset>` filter primitive.
let feOffset = (attrs, children) => node("feOffset", attrs, children)

/// SVG `<feBlend>` filter primitive.
let feBlend = (attrs, children) => node("feBlend", attrs, children)

/// SVG `<feColorMatrix>` filter primitive.
let feColorMatrix = (attrs, children) => node("feColorMatrix", attrs, children)

/// SVG `<feComposite>` filter primitive.
let feComposite = (attrs, children) => node("feComposite", attrs, children)

/// SVG `<feFlood>` filter primitive.
let feFlood = (attrs, children) => node("feFlood", attrs, children)

/// SVG `<feMerge>` filter primitive.
let feMerge = (attrs, children) => node("feMerge", attrs, children)

/// SVG `<feMergeNode>` element (input to `<feMerge>`).
let feMergeNode = (attrs, children) => node("feMergeNode", attrs, children)

// Animation elements

/// SVG `<animate>` element (attribute animation).
let animate = (attrs, children) => node("animate", attrs, children)

/// SVG `<animateTransform>` element (transform animation).
let animateTransform = (attrs, children) => node("animateTransform", attrs, children)

/// SVG `<set>` element (discrete attribute animation).
let set = (attrs, children) => node("set", attrs, children)

// Descriptive elements

/// SVG `<desc>` element (accessible description).
let desc = (attrs, children) => node("desc", attrs, children)

/// SVG `<title>` element (accessible title/tooltip).
let title = (attrs, children) => node("title", attrs, children)

/// SVG `<metadata>` element.
let metadata = (attrs, children) => node("metadata", attrs, children)

/// SVG `<image>` element (embedded raster image).
let image = (attrs, children) => node("image", attrs, children)

/// SVG-specific attribute constructors.
module Attrs = {
  /// Sets the viewBox attribute (e.g. "0 0 100 100").
  let viewBox = (v: string): attribute<'msg> => Property("viewBox", v)

  /// Sets the fill colour.
  let fill = (v: string): attribute<'msg> => Property("fill", v)

  /// Sets the stroke colour.
  let stroke = (v: string): attribute<'msg> => Property("stroke", v)

  /// Sets the stroke width.
  let strokeWidth = (v: string): attribute<'msg> => Property("stroke-width", v)

  /// Sets the stroke linecap style ("butt", "round", "square").
  let strokeLinecap = (v: string): attribute<'msg> => Property("stroke-linecap", v)

  /// Sets the stroke linejoin style ("miter", "round", "bevel").
  let strokeLinejoin = (v: string): attribute<'msg> => Property("stroke-linejoin", v)

  /// Sets the stroke dash pattern (e.g. "5,10").
  let strokeDasharray = (v: string): attribute<'msg> => Property("stroke-dasharray", v)

  /// Sets the stroke dash offset.
  let strokeDashoffset = (v: string): attribute<'msg> => Property("stroke-dashoffset", v)

  /// Sets the stroke opacity (0.0 to 1.0).
  let strokeOpacity = (v: string): attribute<'msg> => Property("stroke-opacity", v)

  /// Sets the fill opacity (0.0 to 1.0).
  let fillOpacity = (v: string): attribute<'msg> => Property("fill-opacity", v)

  /// Sets the fill rule ("nonzero" or "evenodd").
  let fillRule = (v: string): attribute<'msg> => Property("fill-rule", v)

  /// Sets the opacity of the element.
  let opacity = (v: string): attribute<'msg> => Property("opacity", v)

  /// Sets the transform attribute (e.g. "translate(10,20) rotate(45)").
  let transform = (v: string): attribute<'msg> => Property("transform", v)

  /// Sets the `d` attribute (path data string for `<path>` elements).
  let d = (v: string): attribute<'msg> => Property("d", v)

  /// Sets the x position.
  let x = (v: string): attribute<'msg> => Property("x", v)

  /// Sets the y position.
  let y = (v: string): attribute<'msg> => Property("y", v)

  /// Sets the x1 coordinate (line/gradient start x).
  let x1 = (v: string): attribute<'msg> => Property("x1", v)

  /// Sets the y1 coordinate (line/gradient start y).
  let y1 = (v: string): attribute<'msg> => Property("y1", v)

  /// Sets the x2 coordinate (line/gradient end x).
  let x2 = (v: string): attribute<'msg> => Property("x2", v)

  /// Sets the y2 coordinate (line/gradient end y).
  let y2 = (v: string): attribute<'msg> => Property("y2", v)

  /// Sets the cx (centre x) for circles and ellipses.
  let cx = (v: string): attribute<'msg> => Property("cx", v)

  /// Sets the cy (centre y) for circles and ellipses.
  let cy = (v: string): attribute<'msg> => Property("cy", v)

  /// Sets the radius for circles.
  let r = (v: string): attribute<'msg> => Property("r", v)

  /// Sets the x-axis radius for ellipses and rounded rects.
  let rx = (v: string): attribute<'msg> => Property("rx", v)

  /// Sets the y-axis radius for ellipses and rounded rects.
  let ry = (v: string): attribute<'msg> => Property("ry", v)

  /// Sets the width attribute.
  let width = (v: string): attribute<'msg> => Property("width", v)

  /// Sets the height attribute.
  let height = (v: string): attribute<'msg> => Property("height", v)

  /// Sets the points attribute for polygons and polylines.
  let points = (v: string): attribute<'msg> => Property("points", v)

  /// Sets the offset for gradient stops (0 to 1 or percentage).
  let offset = (v: string): attribute<'msg> => Property("offset", v)

  /// Sets the stop-color for gradient stops.
  let stopColor = (v: string): attribute<'msg> => Property("stop-color", v)

  /// Sets the stop-opacity for gradient stops.
  let stopOpacity = (v: string): attribute<'msg> => Property("stop-opacity", v)

  /// Sets the gradientUnits attribute ("userSpaceOnUse" or "objectBoundingBox").
  let gradientUnits = (v: string): attribute<'msg> => Property("gradientUnits", v)

  /// Sets the text-anchor attribute ("start", "middle", "end").
  let textAnchor = (v: string): attribute<'msg> => Property("text-anchor", v)

  /// Sets the dominant-baseline attribute for text vertical alignment.
  let dominantBaseline = (v: string): attribute<'msg> => Property("dominant-baseline", v)

  /// Sets the font-size attribute.
  let fontSize = (v: string): attribute<'msg> => Property("font-size", v)

  /// Sets the font-family attribute.
  let fontFamily = (v: string): attribute<'msg> => Property("font-family", v)

  /// Sets the font-weight attribute.
  let fontWeight = (v: string): attribute<'msg> => Property("font-weight", v)

  /// Sets the `in` attribute for filter primitives.
  let in_ = (v: string): attribute<'msg> => Property("in", v)

  /// Sets the `in2` attribute for filter primitives (second input).
  let in2 = (v: string): attribute<'msg> => Property("in2", v)

  /// Sets the result attribute for filter primitives (named output).
  let result = (v: string): attribute<'msg> => Property("result", v)

  /// Sets the stdDeviation for Gaussian blur.
  let stdDeviation = (v: string): attribute<'msg> => Property("stdDeviation", v)

  /// Sets the dx (horizontal offset).
  let dx = (v: string): attribute<'msg> => Property("dx", v)

  /// Sets the dy (vertical offset).
  let dy = (v: string): attribute<'msg> => Property("dy", v)

  /// Sets the xlink:href attribute (now just `href` in SVG 2).
  let xlinkHref = (v: string): attribute<'msg> => Property("href", v)

  /// Sets the clip-path reference (e.g. "url(#myClip)").
  let clipPathRef = (v: string): attribute<'msg> => Property("clip-path", v)

  /// Sets the mask reference (e.g. "url(#myMask)").
  let maskRef = (v: string): attribute<'msg> => Property("mask", v)

  /// Sets the filter reference (e.g. "url(#myFilter)").
  let filterRef = (v: string): attribute<'msg> => Property("filter", v)

  /// Sets the CSS class attribute.
  let class_ = Tea_Vdom.class_

  /// Sets the element id attribute.
  let id = Tea_Vdom.id

  /// Sets an inline CSS style property and value.
  let style = Tea_Vdom.style
}
