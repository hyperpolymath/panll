// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL TangleViz Component — view layer for the topological programming panel.
///
/// Renders a full-screen overlay with:
///   - Tangle source input area
///   - Braid word display (algebraic notation with Unicode)
///   - Interactive SVG braid diagram with over/under crossings
///   - Knot invariant selector and result display
///   - Example braid quick-select buttons
///   - View mode tabs (Braid / Knot / Algebraic)
///
/// SVG rendering draws N horizontal strands with crossings at each generator.
/// Over-crossings use solid lines; under-crossings use a gap (white break).
/// Strands are colour-coded for visual strand tracking.

open Model
open Msg
open Tea.Html

// ════════════════════════════════════════════════════════════════════════
// View Mode Tabs
// ════════════════════════════════════════════════════════════════════════

/// Render a single view mode tab button.
let renderViewTab = (
  mode: TangleVizModel.tangleViewMode,
  isActive: bool,
): Tea_Vdom.t<msg> => {
  let activeClass = isActive
    ? "border-indigo-500 text-indigo-300 bg-gray-800/50"
    : "border-transparent text-gray-500 hover:text-gray-300 hover:border-gray-600"
  button(
    list{
      Attrs.class_(`px-4 py-2 text-sm font-medium border-b-2 cursor-pointer transition-colors ${activeClass}`),
      Attrs.role("tab"),
      Events.onClick(TangleViz(SetViewMode(mode))),
    },
    list{text(TangleVizEngine.viewModeLabel(mode))},
  )
}

/// Render the view mode tab bar.
let renderViewTabBar = (activeMode: TangleVizModel.tangleViewMode): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("flex border-b border-gray-800 overflow-x-auto"),
      Attrs.role("tablist"),
      Attrs.ariaLabel("Topology view modes"),
    },
    TangleVizEngine.allViewModes
    ->Array.map(mode => renderViewTab(mode, mode === activeMode))
    ->List.fromArray,
  )
}

// ════════════════════════════════════════════════════════════════════════
// Source Input Area
// ════════════════════════════════════════════════════════════════════════

/// Render the Tangle source code input area.
let renderSourceInput = (inputText: string, parsedProgram: option<TangleVizModel.parsedStatus>): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("p-4 border-b border-gray-800")},
    list{
      div(
        list{Attrs.class_("text-xs font-medium text-gray-500 uppercase tracking-wider mb-2")},
        list{text("Tangle Source")},
      ),
      textarea(
        list{
          Attrs.class_("w-full h-24 bg-gray-900 border border-gray-700 rounded px-3 py-2 text-sm text-gray-200 font-mono placeholder-gray-600 focus:border-indigo-500 focus:outline-none resize-y"),
          Attrs.placeholder("Enter Tangle source code or use an example below..."),
          Attrs.value(inputText),
          Events.onInput(text => TangleViz(SetInputText(text))),
        },
        list{},
      ),
      // Parse status indicator
      switch parsedProgram {
      | None =>
        div(
          list{Attrs.class_("mt-1 text-xs text-gray-600")},
          list{text("No input parsed yet")},
        )
      | Some(ParsedOk) =>
        div(
          list{Attrs.class_("mt-1 text-xs text-emerald-400")},
          list{text("Parsed successfully")},
        )
      | Some(ParseFailed(err)) =>
        div(
          list{Attrs.class_("mt-1 text-xs text-red-400")},
          list{text(`Parse error: ${err}`)},
        )
      },
      // Parse button
      div(
        list{Attrs.class_("mt-2 flex gap-2")},
        list{
          button(
            list{
              Attrs.class_("px-3 py-1.5 text-xs bg-indigo-600 text-white rounded hover:bg-indigo-500 transition-colors"),
              Events.onClick(TangleViz(ParseInput)),
            },
            list{text("Parse")},
          ),
          button(
            list{
              Attrs.class_("px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 transition-colors"),
              Events.onClick(TangleViz(ClearAll)),
            },
            list{text("Clear")},
          ),
        },
      ),
    },
  )
}

// ════════════════════════════════════════════════════════════════════════
// Example Braid Quick-Select
// ════════════════════════════════════════════════════════════════════════

/// Render the example braid quick-select buttons.
let renderExamples = (): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("p-4 border-b border-gray-800")},
    list{
      div(
        list{Attrs.class_("text-xs font-medium text-gray-500 uppercase tracking-wider mb-2")},
        list{text("Example Braids")},
      ),
      div(
        list{Attrs.class_("flex flex-wrap gap-2")},
        TangleVizEngine.exampleBraids()
        ->Array.map(ex =>
          button(
            list{
              Attrs.class_("px-3 py-1.5 text-xs bg-gray-800 text-gray-300 rounded border border-gray-700 hover:bg-gray-700 hover:border-gray-600 transition-colors"),
              Attrs.title(ex.description),
              Events.onClick(TangleViz(LoadExample(ex.generators))),
            },
            list{text(ex.name)},
          )
        )
        ->List.fromArray,
      ),
    },
  )
}

// ════════════════════════════════════════════════════════════════════════
// Braid Word Display (Algebraic Notation)
// ════════════════════════════════════════════════════════════════════════

/// Render the algebraic braid word with Unicode notation.
let renderBraidWord = (generators: array<TangleVizModel.braidGenerator>, strandCount: int): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("p-4 border-b border-gray-800")},
    list{
      div(
        list{Attrs.class_("text-xs font-medium text-gray-500 uppercase tracking-wider mb-2")},
        list{text("Braid Word")},
      ),
      div(
        list{Attrs.class_("flex items-center gap-4")},
        list{
          // The braid word in Unicode
          div(
            list{Attrs.class_("text-lg font-mono text-indigo-300")},
            list{text(TangleVizEngine.braidWordToString(generators))},
          ),
          // Strand count badge
          div(
            list{Attrs.class_("text-xs text-gray-500 bg-gray-800 px-2 py-1 rounded")},
            list{text(`${Int.toString(strandCount)} strands`)},
          ),
          // Crossing count badge
          div(
            list{Attrs.class_("text-xs text-gray-500 bg-gray-800 px-2 py-1 rounded")},
            list{text(`${Int.toString(Array.length(generators))} crossings`)},
          ),
        },
      ),
      // Individual generators as clickable chips
      if Array.length(generators) > 0 {
        div(
          list{Attrs.class_("mt-2 flex flex-wrap gap-1")},
          generators
          ->Array.mapWithIndex((gen, idx) => {
            let colour = if gen.exponent > 0 {
              "bg-emerald-900/50 text-emerald-300 border-emerald-700"
            } else {
              "bg-red-900/50 text-red-300 border-red-700"
            }
            span(
              list{
                Attrs.class_(`text-xs px-2 py-0.5 rounded border font-mono ${colour}`),
                Attrs.title(`Generator ${Int.toString(idx + 1)}: ${TangleVizEngine.generatorLabel(gen)}`),
              },
              list{text(TangleVizEngine.generatorLabel(gen))},
            )
          })
          ->List.fromArray,
        )
      } else {
        noNode
      },
    },
  )
}

// ════════════════════════════════════════════════════════════════════════
// SVG Braid Diagram
// ════════════════════════════════════════════════════════════════════════

/// Render the SVG braid diagram.
///
/// Layout: N horizontal strands flow left-to-right. At each generator σᵢ,
/// strands i and i+1 cross. Positive crossings: strand i goes over (drawn
/// on top). Negative crossings: strand i goes under (drawn with a gap).
///
/// The strands maintain their physical position tracking through crossings
/// so colours follow the actual strand paths.
let renderBraidSvg = (generators: array<TangleVizModel.braidGenerator>, strandCount: int): Tea_Vdom.t<msg> => {
  let crossingW = TangleVizEngine.crossingWidth
  let strandSp = TangleVizEngine.strandSpacing
  let leftM = TangleVizEngine.svgLeftMargin
  let topM = TangleVizEngine.svgTopMargin

  let numCrossings = Array.length(generators)
  let svgWidth = leftM *. 2.0 +. Int.toFloat(numCrossings + 1) *. crossingW
  let svgHeight = topM *. 2.0 +. Int.toFloat(strandCount - 1) *. strandSp

  // Track which physical strand is at each vertical position.
  // strandAt[position] = original strand index (for colour).
  let strandAt = Array.fromInitializer(~length=strandCount, i => i)

  // Build path segments for each strand through each crossing column.
  // We collect SVG elements: lines for straight segments, paths for crossings.
  let elements: array<Tea_Vdom.t<msg>> = []

  // Draw initial left-side strand labels
  for pos in 0 to strandCount - 1 {
    let y = topM +. Int.toFloat(pos) *. strandSp
    let colour = TangleVizEngine.strandColour(pos)
    let _ = elements->Array.push(
      Tea_Svg.text'(
        list{
          Tea_Svg.Attrs.class_("text-xs"),
          Tea_Svg.Attrs.x(Float.toString(leftM -. 20.0)),
          Tea_Svg.Attrs.y(Float.toString(y +. 4.0)),
          Tea_Svg.Attrs.fill(colour),
          Tea_Svg.Attrs.textAnchor("middle"),
        },
        list{Tea.Html.text(Int.toString(pos + 1))},
      )
    )
  }

  // For each crossing column, draw the crossing and straight-through strands
  for col in 0 to numCrossings - 1 {
    let gen = generators->Array.getUnsafe(col)
    let crossIdx = gen.index - 1 // Convert 1-based to 0-based position
    let x1 = leftM +. Int.toFloat(col) *. crossingW
    let x2 = leftM +. Int.toFloat(col + 1) *. crossingW

    // Draw straight-through strands (those not involved in this crossing)
    for pos in 0 to strandCount - 1 {
      if pos !== crossIdx && pos !== crossIdx + 1 {
        let y = topM +. Int.toFloat(pos) *. strandSp
        let origStrand = strandAt->Array.getUnsafe(pos)
        let colour = TangleVizEngine.strandColour(origStrand)
        let _ = elements->Array.push(
          Tea_Svg.line(
            list{
              Tea_Svg.Attrs.x1(Float.toString(x1)),
              Tea_Svg.Attrs.y1(Float.toString(y)),
              Tea_Svg.Attrs.x2(Float.toString(x2)),
              Tea_Svg.Attrs.y2(Float.toString(y)),
              Tea_Svg.Attrs.stroke(colour),
              Tea_Svg.Attrs.strokeWidth("2.5"),
            },
            list{},
          )
        )
      }
    }

    // Draw the crossing between positions crossIdx and crossIdx+1
    if crossIdx >= 0 && crossIdx + 1 < strandCount {
      let yTop = topM +. Int.toFloat(crossIdx) *. strandSp
      let yBot = topM +. Int.toFloat(crossIdx + 1) *. strandSp
      let origTop = strandAt->Array.getUnsafe(crossIdx)
      let origBot = strandAt->Array.getUnsafe(crossIdx + 1)
      let colourTop = TangleVizEngine.strandColour(origTop)
      let colourBot = TangleVizEngine.strandColour(origBot)

      // Compute cubic bezier control points for smooth crossing
      let mx = (x1 +. x2) /. 2.0

      if gen.exponent > 0 {
        // Positive crossing: top strand goes OVER
        // Draw under-strand first (with gap), then over-strand
        // Under strand: bottom→top, drawn with a gap in the middle
        let _ = elements->Array.push(
          Tea_Svg.path(
            list{
              Tea_Svg.Attrs.d(`M ${Float.toString(x1)} ${Float.toString(yBot)} C ${Float.toString(mx)} ${Float.toString(yBot)}, ${Float.toString(mx)} ${Float.toString(yTop)}, ${Float.toString(x2)} ${Float.toString(yTop)}`),
              Tea_Svg.Attrs.stroke(colourBot),
              Tea_Svg.Attrs.strokeWidth("2.5"),
              Tea_Svg.Attrs.fill("none"),
              Tea_Svg.Attrs.strokeDasharray("20 12 20 0"),
            },
            list{},
          )
        )
        // Over strand: top→bottom, solid line on top
        let _ = elements->Array.push(
          Tea_Svg.path(
            list{
              Tea_Svg.Attrs.d(`M ${Float.toString(x1)} ${Float.toString(yTop)} C ${Float.toString(mx)} ${Float.toString(yTop)}, ${Float.toString(mx)} ${Float.toString(yBot)}, ${Float.toString(x2)} ${Float.toString(yBot)}`),
              Tea_Svg.Attrs.stroke(colourTop),
              Tea_Svg.Attrs.strokeWidth("2.5"),
              Tea_Svg.Attrs.fill("none"),
            },
            list{},
          )
        )
      } else {
        // Negative crossing: top strand goes UNDER
        // Draw over-strand first (bottom→top, solid), then under-strand (top→bottom, gapped)
        let _ = elements->Array.push(
          Tea_Svg.path(
            list{
              Tea_Svg.Attrs.d(`M ${Float.toString(x1)} ${Float.toString(yTop)} C ${Float.toString(mx)} ${Float.toString(yTop)}, ${Float.toString(mx)} ${Float.toString(yBot)}, ${Float.toString(x2)} ${Float.toString(yBot)}`),
              Tea_Svg.Attrs.stroke(colourTop),
              Tea_Svg.Attrs.strokeWidth("2.5"),
              Tea_Svg.Attrs.fill("none"),
              Tea_Svg.Attrs.strokeDasharray("20 12 20 0"),
            },
            list{},
          )
        )
        // Over strand: bottom→top, solid line on top
        let _ = elements->Array.push(
          Tea_Svg.path(
            list{
              Tea_Svg.Attrs.d(`M ${Float.toString(x1)} ${Float.toString(yBot)} C ${Float.toString(mx)} ${Float.toString(yBot)}, ${Float.toString(mx)} ${Float.toString(yTop)}, ${Float.toString(x2)} ${Float.toString(yTop)}`),
              Tea_Svg.Attrs.stroke(colourBot),
              Tea_Svg.Attrs.strokeWidth("2.5"),
              Tea_Svg.Attrs.fill("none"),
            },
            list{},
          )
        )
      }

      // Swap the strand tracking
      let tmp = strandAt->Array.getUnsafe(crossIdx)
      let _ = strandAt->Array.set(crossIdx, strandAt->Array.getUnsafe(crossIdx + 1))
      let _ = strandAt->Array.set(crossIdx + 1, tmp)
    }
  }

  // Draw final right-side straight segments from last crossing to edge
  let xFinal = leftM +. Int.toFloat(numCrossings) *. crossingW
  let xEnd = xFinal +. crossingW *. 0.5
  for pos in 0 to strandCount - 1 {
    let y = topM +. Int.toFloat(pos) *. strandSp
    let origStrand = strandAt->Array.getUnsafe(pos)
    let colour = TangleVizEngine.strandColour(origStrand)
    let _ = elements->Array.push(
      Tea_Svg.line(
        list{
          Tea_Svg.Attrs.x1(Float.toString(xFinal)),
          Tea_Svg.Attrs.y1(Float.toString(y)),
          Tea_Svg.Attrs.x2(Float.toString(xEnd)),
          Tea_Svg.Attrs.y2(Float.toString(y)),
          Tea_Svg.Attrs.stroke(colour),
          Tea_Svg.Attrs.strokeWidth("2.5"),
        },
        list{},
      )
    )
  }

  // Also draw initial left-side straight segments from edge to first crossing
  let xStart = leftM -. crossingW *. 0.3
  for pos in 0 to strandCount - 1 {
    let y = topM +. Int.toFloat(pos) *. strandSp
    let colour = TangleVizEngine.strandColour(pos)
    let _ = elements->Array.push(
      Tea_Svg.line(
        list{
          Tea_Svg.Attrs.x1(Float.toString(xStart)),
          Tea_Svg.Attrs.y1(Float.toString(y)),
          Tea_Svg.Attrs.x2(Float.toString(leftM)),
          Tea_Svg.Attrs.y2(Float.toString(y)),
          Tea_Svg.Attrs.stroke(colour),
          Tea_Svg.Attrs.strokeWidth("2.5"),
        },
        list{},
      )
    )
  }

  div(
    list{
      Attrs.class_("p-4 flex-1 overflow-auto"),
      Attrs.ariaLabel("Braid diagram visualization"),
    },
    list{
      div(
        list{Attrs.class_("text-xs font-medium text-gray-500 uppercase tracking-wider mb-2")},
        list{text("Braid Diagram")},
      ),
      div(
        list{Attrs.class_("bg-gray-900 rounded-lg border border-gray-800 p-4 overflow-x-auto")},
        list{
          if numCrossings === 0 && strandCount <= 2 {
            div(
              list{Attrs.class_("text-gray-600 text-sm text-center py-8")},
              list{text("Select an example or enter a braid word to visualize")},
            )
          } else {
            Tea_Svg.svg(
              list{
                Tea_Svg.Attrs.class_("block mx-auto"),
                Tea_Svg.Attrs.viewBox(`0 0 ${Float.toString(svgWidth)} ${Float.toString(svgHeight)}`),
                Tea_Svg.Attrs.width(Float.toString(Float.fromInt(Math.Int.min(Float.toInt(svgWidth), 800)))),
                Tea_Svg.Attrs.height(Float.toString(svgHeight)),
              },
              // Background
              list{
                Tea_Svg.rect(
                  list{
                    Tea_Svg.Attrs.x("0"),
                    Tea_Svg.Attrs.y("0"),
                    Tea_Svg.Attrs.width(Float.toString(svgWidth)),
                    Tea_Svg.Attrs.height(Float.toString(svgHeight)),
                    Tea_Svg.Attrs.fill("#0a0a0f"),
                    Tea_Svg.Attrs.rx("8"),
                  },
                  list{},
                ),
                ...elements->List.fromArray,
              },
            )
          },
        },
      ),
    },
  )
}

// ════════════════════════════════════════════════════════════════════════
// Knot Diagram Placeholder
// ════════════════════════════════════════════════════════════════════════

/// Render the knot diagram view (braid closure).
/// This is a placeholder — full Reidemeister-move based rendering
/// would require a more sophisticated layout algorithm.
let renderKnotDiagram = (generators: array<TangleVizModel.braidGenerator>, strandCount: int): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("p-4 flex-1")},
    list{
      div(
        list{Attrs.class_("text-xs font-medium text-gray-500 uppercase tracking-wider mb-2")},
        list{text("Knot Diagram (Braid Closure)")},
      ),
      div(
        list{Attrs.class_("bg-gray-900 rounded-lg border border-gray-800 p-6 text-center")},
        list{
          div(
            list{Attrs.class_("text-gray-400 text-sm mb-4")},
            list{text(`${Int.toString(strandCount)}-strand braid with ${Int.toString(Array.length(generators))} crossings`)},
          ),
          div(
            list{Attrs.class_("text-lg font-mono text-indigo-300 mb-4")},
            list{text(TangleVizEngine.braidWordToString(generators))},
          ),
          div(
            list{Attrs.class_("text-xs text-gray-600")},
            list{text("Full knot projection rendering requires Reidemeister-move simplification (future work)")},
          ),
        },
      ),
    },
  )
}

// ════════════════════════════════════════════════════════════════════════
// Algebraic View
// ════════════════════════════════════════════════════════════════════════

/// Render the algebraic view — braid group notation and relations.
let renderAlgebraicView = (generators: array<TangleVizModel.braidGenerator>, strandCount: int): Tea_Vdom.t<msg> => {
  let writhe = TangleVizEngine.computeWrithe(generators)
  div(
    list{Attrs.class_("p-4 flex-1")},
    list{
      div(
        list{Attrs.class_("text-xs font-medium text-gray-500 uppercase tracking-wider mb-2")},
        list{text("Algebraic View")},
      ),
      div(
        list{Attrs.class_("bg-gray-900 rounded-lg border border-gray-800 p-6 space-y-4")},
        list{
          // Braid group header
          div(
            list{Attrs.class_("text-sm text-gray-400")},
            list{text(`Braid group B${TangleVizEngine.toSubscript(strandCount)}`)},
          ),
          // Braid word
          div(
            list{Attrs.class_("text-xl font-mono text-indigo-300")},
            list{text(TangleVizEngine.braidWordToString(generators))},
          ),
          // Properties
          div(
            list{Attrs.class_("border-t border-gray-800 pt-4 space-y-2")},
            list{
              div(
                list{Attrs.class_("text-sm text-gray-400")},
                list{text(`Word length: ${Int.toString(Array.length(generators))}`)},
              ),
              div(
                list{Attrs.class_("text-sm text-gray-400")},
                list{text(`Writhe: ${Int.toString(writhe)}`)},
              ),
              div(
                list{Attrs.class_("text-sm text-gray-400")},
                list{text(`Strand count: ${Int.toString(strandCount)}`)},
              ),
              // Braid group relations
              div(
                list{Attrs.class_("border-t border-gray-800 pt-3 mt-3")},
                list{
                  div(
                    list{Attrs.class_("text-xs text-gray-600 mb-1")},
                    list{text("Braid group relations:")},
                  ),
                  div(
                    list{Attrs.class_("text-xs font-mono text-gray-500 space-y-1")},
                    list{
                      div(list{}, list{text("\xcf\x83\xe2\x82\x96\xcf\x83\xe2\x82\x97 = \xcf\x83\xe2\x82\x97\xcf\x83\xe2\x82\x96  when |i-j| \xe2\x89\xa5 2")}), // σᵢσⱼ = σⱼσᵢ
                      div(list{}, list{text("\xcf\x83\xe2\x82\x96\xcf\x83\xe2\x82\x97\xcf\x83\xe2\x82\x96 = \xcf\x83\xe2\x82\x97\xcf\x83\xe2\x82\x96\xcf\x83\xe2\x82\x97  when |i-j| = 1")}), // σᵢσⱼσᵢ = σⱼσᵢσⱼ
                    },
                  ),
                },
              ),
            },
          ),
        },
      ),
    },
  )
}

// ════════════════════════════════════════════════════════════════════════
// Invariant Selector and Result
// ════════════════════════════════════════════════════════════════════════

/// Render the invariant selector and computation result.
let renderInvariants = (
  generators: array<TangleVizModel.braidGenerator>,
  selectedInvariant: option<TangleVizModel.knotInvariant>,
  invariantResult: option<string>,
): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("p-4 border-t border-gray-800")},
    list{
      div(
        list{Attrs.class_("text-xs font-medium text-gray-500 uppercase tracking-wider mb-2")},
        list{text("Knot Invariants")},
      ),
      // Invariant buttons
      div(
        list{Attrs.class_("flex flex-wrap gap-2 mb-3")},
        TangleVizEngine.allInvariants
        ->Array.map(inv => {
          let isSelected = selectedInvariant === Some(inv)
          let activeClass = isSelected
            ? "bg-indigo-600 text-white border-indigo-500"
            : "bg-gray-800 text-gray-400 border-gray-700 hover:bg-gray-700 hover:text-gray-300"
          button(
            list{
              Attrs.class_(`px-3 py-1.5 text-xs rounded border transition-colors ${activeClass}`),
              Events.onClick(TangleViz(SelectInvariant(inv))),
            },
            list{text(TangleVizEngine.invariantLabel(inv))},
          )
        })
        ->List.fromArray,
      ),
      // Compute button
      switch selectedInvariant {
      | None => noNode
      | Some(_) =>
        div(
          list{Attrs.class_("flex items-center gap-3")},
          list{
            button(
              list{
                Attrs.class_("px-4 py-2 text-sm bg-emerald-600 text-white rounded hover:bg-emerald-500 transition-colors"),
                Events.onClick(TangleViz(ComputeInvariant)),
              },
              list{text("Compute")},
            ),
            // Result display
            switch invariantResult {
            | None => noNode
            | Some(result) =>
              div(
                list{Attrs.class_("text-sm font-mono text-emerald-300 bg-gray-900 px-3 py-2 rounded border border-gray-800")},
                list{text(result)},
              )
            },
          },
        )
      },
      // Disabled state when no generators
      if Array.length(generators) === 0 {
        div(
          list{Attrs.class_("mt-2 text-xs text-gray-600")},
          list{text("Load a braid word to compute invariants")},
        )
      } else {
        noNode
      },
    },
  )
}

// ════════════════════════════════════════════════════════════════════════
// Header
// ════════════════════════════════════════════════════════════════════════

/// Render the panel header with title and close button.
let renderHeader = (): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex items-center justify-between px-6 py-4 border-b border-gray-800")},
    list{
      div(
        list{Attrs.class_("flex items-center gap-4")},
        list{
          div(
            list{Attrs.class_("text-lg font-medium text-gray-200")},
            list{text("Tangle Viz")},
          ),
          div(
            list{Attrs.class_("text-xs text-gray-500")},
            list{text("Topological Programming Visualizer")},
          ),
        },
      ),
      div(
        list{Attrs.class_("flex items-center gap-3")},
        list{
          button(
            list{
              Attrs.class_("px-3 py-1.5 text-sm text-gray-400 hover:text-gray-200 bg-gray-800 rounded hover:bg-gray-700 transition-colors"),
              Events.onClick(PanelSwitcher(ClosePanels)),
            },
            list{text("Close")},
          ),
        },
      ),
    },
  )
}

// ════════════════════════════════════════════════════════════════════════
// Error Display
// ════════════════════════════════════════════════════════════════════════

/// Render an error banner if present.
let renderError = (error: option<string>): Tea_Vdom.t<msg> => {
  switch error {
  | None => noNode
  | Some(err) =>
    div(
      list{Attrs.class_("mx-4 mt-2 px-4 py-2 bg-red-900/30 border border-red-800 rounded text-sm text-red-300")},
      list{
        text(err),
        button(
          list{
            Attrs.class_("ml-3 text-xs text-red-400 hover:text-red-200 underline"),
            Events.onClick(TangleViz(DismissError)),
          },
          list{text("dismiss")},
        ),
      },
    )
  }
}

// ════════════════════════════════════════════════════════════════════════
// Main View
// ════════════════════════════════════════════════════════════════════════

/// Main TangleViz panel view — full-screen overlay.
let view = (tv: tangleVizState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.ariaLabel("Tangle Viz panel"),
    },
    list{
      // Header
      renderHeader(),
      // Error banner
      renderError(tv.error),
      // View mode tabs
      renderViewTabBar(tv.viewMode),
      // Two-column layout: left = input/controls, right = visualization
      div(
        list{Attrs.class_("flex-1 flex overflow-hidden")},
        list{
          // Left sidebar: source input, examples, invariants
          div(
            list{Attrs.class_("w-96 flex-shrink-0 border-r border-gray-800 overflow-y-auto")},
            list{
              renderSourceInput(tv.inputText, tv.parsedProgram),
              renderExamples(),
              renderBraidWord(tv.braidWord, tv.strandCount),
              renderInvariants(tv.braidWord, tv.selectedInvariant, tv.invariantResult),
            },
          ),
          // Right main area: visualization based on view mode
          div(
            list{Attrs.class_("flex-1 overflow-auto")},
            list{
              switch tv.viewMode {
              | BraidDiagram => renderBraidSvg(tv.braidWord, tv.strandCount)
              | KnotDiagram => renderKnotDiagram(tv.braidWord, tv.strandCount)
              | AlgebraicView => renderAlgebraicView(tv.braidWord, tv.strandCount)
              },
            },
          ),
        },
      ),
    },
  )
}
