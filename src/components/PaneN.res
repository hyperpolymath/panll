// SPDX-License-Identifier: PMPL-1.0-or-later

/// Pane-N: Neural Stream Component
///
/// The inference manifold showing the Agent's internal monologue,
/// OODA loop visibility, and Thing-Agency monitor.

open Model
open Msg
open Tea.Html

/// Render the OODA phase indicator
let renderOodaPhase = (phase: oodaPhase): Tea_Vdom.t<msg> => {
  let phases = [
    (Observe, "O", "Observe"),
    (Orient, "O", "Orient"),
    (Decide, "D", "Decide"),
    (Act, "A", "Act"),
  ]

  div(
    list{Attrs.class_("flex gap-1 mb-4")},
    phases
    ->Array.map(((p, letter, label)) => {
      let isActive = p === phase
      let bgClass = isActive ? "bg-emerald-600" : "bg-gray-700"
      let textClass = isActive ? "text-white" : "text-gray-500"

      div(
        list{
          Attrs.class_(`${bgClass} ${textClass} w-8 h-8 rounded flex items-center justify-center text-xs font-bold`),
          Attrs.title(label),
          Attrs.ariaCurrent(isActive ? "step" : "false"),
        },
        list{text(letter)},
      )
    })
    ->List.fromArray,
  )
}

/// Render the Thing-Agency monitor
let renderAgencyMonitor = (agency: agencyState): Tea_Vdom.t<msg> => {
  let autonomyPercent = Int.toString(Int.fromFloat(agency.autonomyLevel *. 100.0))
  let barWidth = autonomyPercent ++ "%"

  div(
    list{Attrs.class_("mb-4 p-3 bg-gray-800/50 rounded")},
    list{
      div(
        list{Attrs.class_("text-xs text-gray-500 mb-2")},
        list{text("THING-AGENCY MONITOR")},
      ),
      renderOodaPhase(agency.phase),
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          div(
            list{Attrs.class_("text-xs text-gray-400 w-20")},
            list{text("Autonomy:")},
          ),
          div(
            list{
              Attrs.class_("flex-1 h-2 bg-gray-700 rounded overflow-hidden"),
              Attrs.role("progressbar"),
              Attrs.ariaLabel("Autonomy Level"),
              Attrs.ariaValueNow(agency.autonomyLevel *. 100.0),
              Attrs.ariaValueMin(0.0),
              Attrs.ariaValueMax(100.0),
            },
            list{
              div(
                list{
                  Attrs.class_("h-full bg-emerald-500 transition-all duration-300"),
                  Attrs.style("width", barWidth),
                },
                list{},
              ),
            },
          ),
          div(
            list{Attrs.class_("text-xs text-emerald-400 w-12 text-right")},
            list{text(autonomyPercent ++ "%")},
          ),
        },
      ),
    },
  )
}

/// Source badge colour and label for token provenance display.
let sourceLabel = (source: tokenSource): (string, string) => switch source {
| NeuralInference => ("N", "bg-emerald-800 text-emerald-300")
| EchidnaProver => ("E", "bg-indigo-800 text-indigo-300")
| TypeLLKernel => ("T", "bg-violet-800 text-violet-300")
| VeriSimInference => ("V", "bg-cyan-800 text-cyan-300")
| AntiCrashGate => ("!", "bg-red-800 text-red-300")
| OperatorInput => ("H", "bg-amber-800 text-amber-300")
| OrbitalSync => ("S", "bg-blue-800 text-blue-300")
}

/// Category icon for semantic reasoning step display.
let categoryIcon = (cat: tokenCategory): string => switch cat {
| Observation => "?"
| Hypothesis => "~"
| Deduction => ">"
| Abduction => "<"
| ProofStep => "#"
| Violation => "X"
| Correction => "^"
| Synthesis => "*"
}

/// OODA phase short label for inline display.
let phaseLabel = (phase: oodaPhase): string => switch phase {
| Observe => "OBS"
| Orient => "ORI"
| Decide => "DEC"
| Act => "ACT"
}

/// Render a neural token with full provenance, category, and causal metadata.
let renderToken = (token: neuralToken): Tea_Vdom.t<msg> => {
  let validatedClass = token.validated ? "border-emerald-700" : "border-amber-700"
  let confidencePercent = Int.toString(Int.fromFloat(token.confidence *. 100.0))
  let (srcLetter, srcColour) = sourceLabel(token.source)
  let catIcon = categoryIcon(token.category)
  let phase = phaseLabel(token.emittedDuring)
  let hasCauses = Array.length(token.causedBy) > 0
  let hasProof = token.proofHash !== None

  div(
    list{
      Attrs.class_(`p-2 mb-1 border-l-2 ${validatedClass} bg-gray-800/30`),
      Attrs.ariaLabel(token.content),
    },
    list{
      // Top row: source badge + content
      div(
        list{Attrs.class_("flex items-start gap-2")},
        list{
          // Source badge (single letter, colour-coded)
          span(
            list{
              Attrs.class_(`w-5 h-5 rounded flex items-center justify-center text-[10px] font-bold shrink-0 ${srcColour}`),
              Attrs.title(switch token.source {
              | NeuralInference => "Neural Inference"
              | EchidnaProver => "ECHIDNA Prover"
              | TypeLLKernel => "TypeLL Kernel"
              | VeriSimInference => "VeriSimDB Inference"
              | AntiCrashGate => "Anti-Crash Gate"
              | OperatorInput => "Operator Input"
              | OrbitalSync => "OrbitalSync"
              }),
            },
            list{text(srcLetter)},
          ),
          // Token content
          div(
            list{Attrs.class_("text-sm text-gray-300 flex-1")},
            list{text(token.content)},
          ),
        },
      ),
      // Bottom row: metadata chips
      div(
        list{Attrs.class_("flex items-center gap-2 mt-1 pl-7")},
        list{
          // Confidence
          span(
            list{Attrs.class_("text-[10px] text-gray-500")},
            list{text(`${confidencePercent}%`)},
          ),
          // Category icon
          span(
            list{
              Attrs.class_("text-[10px] text-gray-600 font-mono"),
              Attrs.title(switch token.category {
              | Observation => "Observation"
              | Hypothesis => "Hypothesis"
              | Deduction => "Deduction"
              | Abduction => "Abduction"
              | ProofStep => "Proof Step"
              | Violation => "Violation"
              | Correction => "Correction"
              | Synthesis => "Synthesis"
              }),
            },
            list{text(`[${catIcon}]`)},
          ),
          // OODA phase
          span(
            list{Attrs.class_("text-[10px] text-gray-600")},
            list{text(phase)},
          ),
          // Causal chain indicator
          if hasCauses {
            span(
              list{
                Attrs.class_("text-[10px] text-gray-600"),
                Attrs.title("Caused by: " ++ Array.join(token.causedBy, ", ")),
              },
              list{text(`<${Int.toString(Array.length(token.causedBy))}`)},
            )
          } else {
            noNode
          },
          // Proof hash indicator
          if hasProof {
            span(
              list{
                Attrs.class_("text-[10px] text-emerald-600 font-mono"),
                Attrs.title(switch token.proofHash {
                | Some(h) => h
                | None => ""
                }),
              },
              list{text("#")},
            )
          } else {
            noNode
          },
        },
      ),
    },
  )
}

/// OODA phase colour for timeline segments.
let phaseColour = (phase: oodaPhase): string => switch phase {
| Observe => "bg-cyan-600"
| Orient => "bg-amber-600"
| Decide => "bg-violet-600"
| Act => "bg-emerald-600"
}

/// Render the OODA phase timeline — a horizontal bar showing the sequence of
/// phases across the token stream, with segment widths proportional to token counts.
let renderOodaTimeline = (tokens: array<neuralToken>): Tea_Vdom.t<msg> => {
  let total = Float.fromInt(Array.length(tokens))
  if total === 0.0 {
    noNode
  } else {
    // Group consecutive tokens by phase into segments
    let segments: array<(oodaPhase, int)> = []
    Array.forEach(tokens, token => {
      let len = Array.length(segments)
      if len > 0 {
        let (lastPhase, lastCount) = segments->Array.getUnsafe(len - 1)
        if lastPhase === token.emittedDuring {
          ignore(segments->Array.splice(~start=len - 1, ~remove=1, ~insert=[
            (lastPhase, lastCount + 1),
          ]))
        } else {
          ignore(Array.push(segments, (token.emittedDuring, 1)))
        }
      } else {
        ignore(Array.push(segments, (token.emittedDuring, 1)))
      }
    })

    div(
      list{Attrs.class_("mb-3")},
      list{
        div(
          list{Attrs.class_("flex items-center justify-between mb-1")},
          list{
            div(
              list{Attrs.class_("text-[10px] text-gray-500 uppercase tracking-wider")},
              list{text("OODA Timeline")},
            ),
            div(
              list{Attrs.class_("flex gap-2 text-[9px] text-gray-600")},
              list{
                span(list{Attrs.class_("flex items-center gap-1")}, list{
                  span(list{Attrs.class_("w-2 h-2 rounded-sm bg-cyan-600")}, list{}),
                  text("Observe"),
                }),
                span(list{Attrs.class_("flex items-center gap-1")}, list{
                  span(list{Attrs.class_("w-2 h-2 rounded-sm bg-amber-600")}, list{}),
                  text("Orient"),
                }),
                span(list{Attrs.class_("flex items-center gap-1")}, list{
                  span(list{Attrs.class_("w-2 h-2 rounded-sm bg-violet-600")}, list{}),
                  text("Decide"),
                }),
                span(list{Attrs.class_("flex items-center gap-1")}, list{
                  span(list{Attrs.class_("w-2 h-2 rounded-sm bg-emerald-600")}, list{}),
                  text("Act"),
                }),
              },
            ),
          },
        ),
        // Timeline bar
        div(
          list{
            Attrs.class_("flex h-3 rounded overflow-hidden"),
            Attrs.role("img"),
            Attrs.ariaLabel("OODA phase distribution across inference tokens"),
          },
          segments
          ->Array.map(((phase, count)) => {
            let widthPct = Float.toString(Float.fromInt(count) /. total *. 100.0) ++ "%"
            div(
              list{
                Attrs.class_(`${phaseColour(phase)} transition-all duration-300`),
                Attrs.style("width", widthPct),
                Attrs.title(phaseLabel(phase) ++ ": " ++ Int.toString(count) ++ " tokens"),
              },
              list{},
            )
          })
          ->List.fromArray,
        ),
      },
    )
  }
}

/// Render source distribution — small horizontal bar showing which subsystems
/// contributed tokens, colour-coded by source.
let renderSourceDistribution = (tokens: array<neuralToken>): Tea_Vdom.t<msg> => {
  let total = Float.fromInt(Array.length(tokens))
  if total === 0.0 {
    noNode
  } else {
    // Count by source
    let counts: array<(tokenSource, string, string, int)> = [
      (NeuralInference, "N", "bg-emerald-700", 0),
      (EchidnaProver, "E", "bg-indigo-700", 0),
      (TypeLLKernel, "T", "bg-violet-700", 0),
      (VeriSimInference, "V", "bg-cyan-700", 0),
      (AntiCrashGate, "!", "bg-red-700", 0),
      (OperatorInput, "H", "bg-amber-700", 0),
      (OrbitalSync, "S", "bg-blue-700", 0),
    ]
    Array.forEach(tokens, token => {
      let idx = counts->Array.findIndex(((src, _, _, _)) => src === token.source)
      if idx >= 0 {
        let (src, lbl, col, n) = counts->Array.getUnsafe(idx)
        ignore(counts->Array.splice(~start=idx, ~remove=1, ~insert=[(src, lbl, col, n + 1)]))
      }
    })
    let active = counts->Array.filter(((_, _, _, n)) => n > 0)

    div(
      list{Attrs.class_("mb-3")},
      list{
        div(
          list{Attrs.class_("text-[10px] text-gray-500 uppercase tracking-wider mb-1")},
          list{text("Source Distribution")},
        ),
        div(
          list{Attrs.class_("flex h-2 rounded overflow-hidden mb-1")},
          active
          ->Array.map(((_, _, col, n)) => {
            let widthPct = Float.toString(Float.fromInt(n) /. total *. 100.0) ++ "%"
            div(
              list{
                Attrs.class_(`${col} transition-all duration-300`),
                Attrs.style("width", widthPct),
              },
              list{},
            )
          })
          ->List.fromArray,
        ),
        // Legend with counts
        div(
          list{Attrs.class_("flex gap-2 flex-wrap")},
          active
          ->Array.map(((_, lbl, col, n)) => {
            span(
              list{Attrs.class_("flex items-center gap-1 text-[9px] text-gray-500")},
              list{
                span(list{Attrs.class_(`w-2 h-2 rounded-sm ${col}`)}, list{}),
                text(lbl ++ ":" ++ Int.toString(n)),
              },
            )
          })
          ->List.fromArray,
        ),
      },
    )
  }
}

/// Render the causal inference graph — a compact ASCII-style DAG showing how
/// tokens are causally linked. Each token shows its ID and arrows to parents.
let renderCausalGraph = (tokens: array<neuralToken>): Tea_Vdom.t<msg> => {
  // Only show tokens that have causal links (either cause or are caused by)
  let linked = tokens->Array.filter(t =>
    Array.length(t.causedBy) > 0 ||
    tokens->Array.some(other => other.causedBy->Array.some(id => id === t.id))
  )
  if Array.length(linked) === 0 {
    noNode
  } else {
    div(
      list{Attrs.class_("mb-3")},
      list{
        div(
          list{Attrs.class_("text-[10px] text-gray-500 uppercase tracking-wider mb-1")},
          list{text("Inference Chain")},
        ),
        div(
          list{
            Attrs.class_("max-h-24 overflow-y-auto bg-gray-900/50 rounded p-2"),
            Attrs.role("img"),
            Attrs.ariaLabel("Causal inference graph"),
          },
          linked
          ->Array.map(token => {
            let (_, srcColour) = sourceLabel(token.source)
            let arrow = if Array.length(token.causedBy) > 0 {
              Array.join(token.causedBy, ",") ++ " -> "
            } else {
              ""
            }
            let proofMark = switch token.proofHash {
            | Some(_) => " #"
            | None => ""
            }
            div(
              list{Attrs.class_("flex items-center gap-1 py-0.5 font-mono text-[10px]")},
              list{
                // Causal arrow
                if arrow !== "" {
                  span(
                    list{Attrs.class_("text-gray-600")},
                    list{text(arrow)},
                  )
                } else {
                  span(
                    list{Attrs.class_("text-gray-700")},
                    list{text("  root -> ")},
                  )
                },
                // Token ID badge
                span(
                  list{Attrs.class_(`px-1 py-0.5 rounded text-[9px] font-bold ${srcColour}`)},
                  list{text(token.id)},
                ),
                // Truncated content
                span(
                  list{Attrs.class_("text-gray-500 truncate flex-1")},
                  list{text(String.slice(token.content, ~start=0, ~end=40))},
                ),
                // Proof indicator
                if proofMark !== "" {
                  span(
                    list{Attrs.class_("text-emerald-500 font-bold")},
                    list{text("#")},
                  )
                } else {
                  noNode
                },
              },
            )
          })
          ->List.fromArray,
        ),
      },
    )
  }
}

/// Render the token stream with OODA timeline, source distribution,
/// causal graph, and the full token log.
let renderTokenStream = (tokens: array<neuralToken>): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("mb-4")},
    list{
      div(
        list{Attrs.class_("text-xs text-gray-500 mb-2 flex items-center justify-between")},
        list{
          text("TOKEN STREAM"),
          if Array.length(tokens) > 0 {
            span(
              list{Attrs.class_("text-[10px] text-gray-600")},
              list{text(Int.toString(Array.length(tokens)) ++ " tokens")},
            )
          } else {
            noNode
          },
        },
      ),
      if Array.length(tokens) === 0 {
        div(
          list{Attrs.class_("text-gray-600 text-sm italic")},
          list{text("No tokens received")},
        )
      } else {
        div(
          list{},
          list{
            // OODA phase timeline
            renderOodaTimeline(tokens),
            // Source distribution bar
            renderSourceDistribution(tokens),
            // Causal inference graph
            renderCausalGraph(tokens),
            // Token log
            div(
              list{
                Attrs.class_("max-h-40 overflow-y-auto"),
                Attrs.role("log"),
                Attrs.ariaLabel("Token Stream"),
              },
              tokens->Array.map(renderToken)->List.fromArray,
            ),
          },
        )
      },
    },
  )
}

/// Render the monologue/inference stream
let renderMonologue = (monologue: string, inferenceActive: bool): Tea_Vdom.t<msg> => {
  let statusClass = inferenceActive ? "text-emerald-400" : "text-gray-500"
  let statusText = inferenceActive ? "streaming..." : "idle"

  div(
    list{Attrs.class_("flex-1")},
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-2")},
        list{
          div(
            list{Attrs.class_("text-xs text-gray-500")},
            list{text("INFERENCE MANIFOLD")},
          ),
          div(
            list{Attrs.class_(`text-xs ${statusClass}`), Attrs.role("status"), Attrs.ariaLive("polite")},
            list{text(statusText)},
          ),
        },
      ),
      div(
        list{
          Attrs.class_(
            "h-48 bg-gray-800/50 rounded p-3 overflow-y-auto text-sm text-emerald-200 whitespace-pre-wrap",
          ),
        },
        list{text(monologue === "" ? "Awaiting neural inference..." : monologue)},
      ),
    },
  )
}

// ===========================================================================
// ECHIDNA Theorem Prover Panel
// ===========================================================================

/// Render the ECHIDNA connection indicator — green dot when connected,
/// red dot when disconnected. Shows the version string and a "Ping" button
/// to manually trigger a health check.
let renderEchidnaConnectionIndicator = (echidna: echidnaState): Tea_Vdom.t<msg> => {
  let dotClass = echidna.connected ? "bg-emerald-400" : "bg-red-500"
  let statusText = switch (echidna.connected, echidna.version) {
  | (true, Some(v)) => "ECHIDNA v" ++ v
  | (true, None) => "ECHIDNA connected"
  | (false, _) => "ECHIDNA disconnected"
  }

  div(
    list{Attrs.class_("flex items-center gap-2 mb-3")},
    list{
      div(
        list{Attrs.class_(`w-2 h-2 rounded-full ${dotClass}`), Attrs.role("status"), Attrs.ariaLabel(statusText)},
        list{},
      ),
      div(
        list{Attrs.class_("text-xs text-gray-400 flex-1")},
        list{text(statusText)},
      ),
      button(
        list{
          Attrs.class_("text-xs px-2 py-0.5 bg-gray-700 hover:bg-gray-600 text-gray-300 rounded"),
          Attrs.ariaLabel("Ping ECHIDNA"),
          Events.onClick(Echidna(CheckHealth)),
        },
        list{text("Ping")},
      ),
    },
  )
}

/// Render a selectable list of provers from the ECHIDNA catalog.
/// Each prover shows its name, tier badge, and complexity class.
/// The selected prover is highlighted with an active background.
let renderProverCatalog = (echidna: echidnaState): Tea_Vdom.t<msg> => {
  if Array.length(echidna.provers) === 0 {
    div(
      list{Attrs.class_("mb-3")},
      list{
        div(
          list{Attrs.class_("flex items-center justify-between mb-1")},
          list{
            div(
              list{Attrs.class_("text-xs text-gray-500")},
              list{text("PROVERS")},
            ),
            button(
              list{
                Attrs.class_("text-xs px-2 py-0.5 bg-gray-700 hover:bg-gray-600 text-gray-300 rounded"),
                Attrs.ariaLabel("List Provers"),
                Events.onClick(Echidna(ListProvers)),
              },
              list{text("List Provers")},
            ),
          },
        ),
        div(
          list{Attrs.class_("text-gray-600 text-xs italic")},
          list{text("No provers loaded")},
        ),
      },
    )
  } else {
    div(
      list{Attrs.class_("mb-3")},
      list{
        div(
          list{Attrs.class_("flex items-center justify-between mb-1")},
          list{
            div(
              list{Attrs.class_("text-xs text-gray-500")},
              list{text("PROVERS")},
            ),
            button(
              list{
                Attrs.class_("text-xs px-2 py-0.5 bg-gray-700 hover:bg-gray-600 text-gray-300 rounded"),
                Events.onClick(Echidna(ListProvers)),
              },
              list{text("Refresh")},
            ),
          },
        ),
        div(
          list{Attrs.class_("max-h-24 overflow-y-auto"), Attrs.role("list"), Attrs.ariaLabel("Prover Catalog")},
          echidna.provers
          ->Array.map(prover => {
            let isSelected = echidna.selectedProver === Some(prover.name)
            let bgClass = isSelected ? "bg-indigo-900/50 border-indigo-600" : "bg-gray-800/30 border-gray-700"
            div(
              list{
                Attrs.class_(`flex items-center gap-2 p-1.5 border-l-2 ${bgClass} mb-0.5 cursor-pointer hover:bg-gray-700/50`),
                Attrs.role("listitem"),
                Attrs.tabIndex(0),
                Events.onClick(Echidna(SelectProver(isSelected ? None : Some(prover.name)))),
                KeyboardUtil.onEnterOrSpace(Echidna(SelectProver(isSelected ? None : Some(prover.name)))),
              },
              list{
                div(
                  list{Attrs.class_("text-xs text-gray-300 flex-1")},
                  list{text(prover.name)},
                ),
                div(
                  list{Attrs.class_("text-xs px-1 py-0.5 bg-gray-700 rounded text-gray-400")},
                  list{text(prover.tier)},
                ),
                div(
                  list{Attrs.class_("text-xs text-gray-500")},
                  list{text(prover.complexity)},
                ),
              },
            )
          })
          ->List.fromArray,
        ),
      },
    )
  }
}

/// Render the proof input area with a textarea, prover selector, and
/// action buttons (Prove / Verify).
let renderProofInput = (echidna: echidnaState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("mb-3")},
    list{
      div(
        list{Attrs.class_("text-xs text-gray-500 mb-1")},
        list{text("PROOF INPUT")},
      ),
      textarea(
        list{
          Attrs.class_(
            "w-full h-20 bg-gray-800/50 rounded p-2 text-xs text-gray-200 border border-gray-700 focus:border-indigo-500 focus:outline-none resize-none font-mono",
          ),
          Attrs.placeholder("Enter proof content..."),
          Attrs.value(echidna.proofInput),
          Attrs.ariaLabel("Proof content input"),
          Events.onInput(text => Echidna(UpdateProofInput(text))),
        },
        list{},
      ),
      div(
        list{Attrs.class_("flex gap-2 mt-1")},
        list{
          button(
            list{
              Attrs.class_(
                "text-xs px-3 py-1 bg-indigo-700 hover:bg-indigo-600 text-white rounded disabled:opacity-50 disabled:cursor-not-allowed",
              ),
              Attrs.disabled(echidna.proofLoading || echidna.proofInput === ""),
              Attrs.ariaLabel("Submit Proof"),
              Events.onClick(Echidna(SubmitProof)),
            },
            list{text(echidna.proofLoading ? "Proving..." : "Prove")},
          ),
          button(
            list{
              Attrs.class_(
                "text-xs px-3 py-1 bg-emerald-700 hover:bg-emerald-600 text-white rounded disabled:opacity-50 disabled:cursor-not-allowed",
              ),
              Attrs.disabled(echidna.proofLoading || echidna.proofInput === ""),
              Attrs.ariaLabel("Verify Proof"),
              Events.onClick(Echidna(SubmitVerify)),
            },
            list{text(echidna.proofLoading ? "Verifying..." : "Verify")},
          ),
        },
      ),
    },
  )
}

/// Render the trust level badge — colour-coded from red (Level 1) through
/// green (Level 5). This is the primary signal for proof confidence.
let renderTrustBadge = (trustLevel: echidnaTrustLevel): Tea_Vdom.t<msg> => {
  let (label, colour) = switch trustLevel {
  | TrustLevel1 => ("Trust 1", "bg-red-700 text-red-200")
  | TrustLevel2 => ("Trust 2", "bg-orange-700 text-orange-200")
  | TrustLevel3 => ("Trust 3", "bg-yellow-700 text-yellow-200")
  | TrustLevel4 => ("Trust 4", "bg-emerald-700 text-emerald-200")
  | TrustLevel5 => ("Trust 5", "bg-green-700 text-green-200")
  }
  span(
    list{
      Attrs.class_(`text-xs px-2 py-0.5 rounded font-bold ${colour}`),
      Attrs.ariaLabel(label),
    },
    list{text(label)},
  )
}

/// Render the axiom report — a list of axiom usage warnings colour-coded
/// by danger level. Reject-level axioms are shown in red; safe axioms
/// are dimmed. This alerts the operator to unsound assumptions.
let renderAxiomReport = (axioms: array<axiomUsage>): Tea_Vdom.t<msg> => {
  if Array.length(axioms) === 0 {
    noNode
  } else {
    div(
      list{Attrs.class_("mt-2"), Attrs.role("region"), Attrs.ariaLabel("Axiom Report")},
      list{
        div(
          list{Attrs.class_("text-xs text-gray-500 mb-1")},
          list{text("AXIOM REPORT")},
        ),
        div(
          list{Attrs.class_("max-h-16 overflow-y-auto")},
          axioms
          ->Array.map(axiom => {
            let (colour, icon) = switch axiom.dangerLevel {
            | Safe => ("text-gray-500", "")
            | Noted => ("text-blue-400", "i ")
            | Warning => ("text-yellow-400", "! ")
            | Reject => ("text-red-400", "X ")
            }
            div(
              list{Attrs.class_(`text-xs ${colour} py-0.5`)},
              list{text(icon ++ axiom.axiomName ++ " - " ++ axiom.description)},
            )
          })
          ->List.fromArray,
        ),
      },
    )
  }
}

/// Render the full proof result panel — verified/failed status, trust badge,
/// provers used, proof time, remaining goals, certificate hash, and axiom report.
let renderProofResult = (result: echidnaDispatchResult): Tea_Vdom.t<msg> => {
  let statusClass = result.verified ? "text-emerald-400" : "text-red-400"
  let statusText = result.verified ? "VERIFIED" : "FAILED"
  let proversText = Array.join(result.proversUsed, ", ")
  let timeText = Float.toString(result.proofTimeMs) ++ "ms"

  div(
    list{Attrs.class_("mt-2 p-2 bg-gray-800/50 rounded border border-gray-700")},
    list{
      // Status row with trust badge
      div(
        list{Attrs.class_("flex items-center justify-between mb-2")},
        list{
          div(
            list{Attrs.class_(`text-sm font-bold ${statusClass}`)},
            list{text(statusText)},
          ),
          renderTrustBadge(result.trustLevel),
        },
      ),
      // Details grid
      div(
        list{Attrs.class_("grid grid-cols-2 gap-1 text-xs")},
        list{
          div(list{Attrs.class_("text-gray-500")}, list{text("Provers:")}),
          div(list{Attrs.class_("text-gray-300")}, list{text(proversText === "" ? "none" : proversText)}),
          div(list{Attrs.class_("text-gray-500")}, list{text("Time:")}),
          div(list{Attrs.class_("text-gray-300")}, list{text(timeText)}),
          div(list{Attrs.class_("text-gray-500")}, list{text("Goals left:")}),
          div(list{Attrs.class_("text-gray-300")}, list{text(Int.toString(result.goalsRemaining))}),
        },
      ),
      // Certificate hash (if present)
      switch result.certificateHash {
      | Some(hash) =>
        div(
          list{Attrs.class_("text-xs text-gray-500 mt-1 truncate")},
          list{text("cert: " ++ hash)},
        )
      | None => noNode
      },
      // Message
      if result.message !== "" {
        div(
          list{Attrs.class_("text-xs text-gray-400 mt-1 italic")},
          list{text(result.message)},
        )
      } else {
        noNode
      },
      // Axiom report
      renderAxiomReport(result.axiomReport),
      // Clear button
      div(
        list{Attrs.class_("mt-2 text-right")},
        list{
          button(
            list{
              Attrs.class_("text-xs px-2 py-0.5 bg-gray-700 hover:bg-gray-600 text-gray-400 rounded"),
              Attrs.ariaLabel("Clear proof result"),
              Events.onClick(Echidna(ClearProofResult)),
            },
            list{text("Clear")},
          ),
        },
      ),
    },
  )
}

// ===========================================================================
// ECHIDNA Interactive Session UI
// ===========================================================================

/// Render session controls — "Start Session" button when no session is active,
/// "Cancel" button when a session is running. Disabled during loading.
let renderSessionControls = (echidna: echidnaState): Tea_Vdom.t<msg> => {
  switch echidna.session {
  | None =>
    div(
      list{Attrs.class_("flex gap-2 mt-2")},
      list{
        button(
          list{
            Attrs.class_(
              "text-xs px-3 py-1 bg-indigo-700 hover:bg-indigo-600 text-white rounded disabled:opacity-50 disabled:cursor-not-allowed",
            ),
            Attrs.disabled(
              echidna.sessionLoading || echidna.proofInput === "",
            ),
            Attrs.ariaLabel("Start Proof Session"),
            Events.onClick(Echidna(CreateSession)),
          },
          list{
            text(echidna.sessionLoading ? "Creating..." : "Start Session"),
          },
        ),
      },
    )
  | Some(_session) =>
    div(
      list{Attrs.class_("flex gap-2 mt-2")},
      list{
        button(
          list{
            Attrs.class_(
              "text-xs px-3 py-1 bg-red-700 hover:bg-red-600 text-white rounded",
            ),
            Attrs.ariaLabel("Cancel Session"),
            Events.onClick(Echidna(CancelSession)),
          },
          list{text("Cancel Session")},
        ),
        button(
          list{
            Attrs.class_(
              "text-xs px-3 py-1 bg-gray-700 hover:bg-gray-600 text-gray-300 rounded",
            ),
            Attrs.ariaLabel("Refresh Session State"),
            Events.onClick(Echidna(GetSessionState)),
          },
          list{text("Refresh")},
        ),
      },
    )
  }
}

/// Render session status header — session ID (truncated), prover, status badge,
/// and elapsed time.
let renderSessionStatus = (session: echidnaSessionState): Tea_Vdom.t<msg> => {
  let (statusText, statusColour) = switch session.status {
  | Pending => ("PENDING", "bg-gray-600 text-gray-200")
  | InProgress => ("IN PROGRESS", "bg-blue-700 text-blue-200")
  | ProofSuccess => ("SUCCESS", "bg-green-700 text-green-200")
  | ProofFailed => ("FAILED", "bg-red-700 text-red-200")
  | ProofTimeout => ("TIMEOUT", "bg-yellow-700 text-yellow-200")
  | ProofError => ("ERROR", "bg-red-800 text-red-200")
  }

  let truncatedId = if String.length(session.sessionId) > 12 {
    String.slice(session.sessionId, ~start=0, ~end=12) ++ "..."
  } else {
    session.sessionId
  }

  let timeText = switch session.timeElapsed {
  | Some(t) => Float.toFixed(t, ~digits=1) ++ "s"
  | None => "-"
  }

  div(
    list{Attrs.class_("p-2 bg-gray-800/50 rounded mb-2")},
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-1")},
        list{
          div(
            list{Attrs.class_("text-xs text-gray-400")},
            list{text("Session: " ++ truncatedId)},
          ),
          span(
            list{
              Attrs.class_(`text-xs px-2 py-0.5 rounded font-bold ${statusColour}`),
              Attrs.ariaLabel("Proof status: " ++ statusText),
            },
            list{text(statusText)},
          ),
        },
      ),
      div(
        list{Attrs.class_("flex items-center gap-3 text-xs text-gray-400")},
        list{
          div(list{}, list{text("Prover: " ++ session.prover)}),
          div(list{}, list{text("Time: " ++ timeText)}),
        },
      ),
      switch session.errorMessage {
      | Some(err) =>
        div(
          list{Attrs.class_("text-xs text-red-400 mt-1")},
          list{text(err)},
        )
      | None => noNode
      },
    },
  )
}

/// Render the current goal list — numbered, first goal highlighted as "active".
let renderGoalList = (goals: array<string>): Tea_Vdom.t<msg> => {
  if Array.length(goals) === 0 {
    div(
      list{Attrs.class_("text-xs text-emerald-400 italic mb-2")},
      list{text("All goals discharged")},
    )
  } else {
    div(
      list{Attrs.class_("mb-2")},
      list{
        div(
          list{Attrs.class_("text-xs text-gray-500 mb-1")},
          list{text("GOALS (" ++ Int.toString(Array.length(goals)) ++ ")")},
        ),
        div(
          list{
            Attrs.class_("max-h-24 overflow-y-auto"),
            Attrs.role("list"),
            Attrs.ariaLabel("Proof Goals"),
          },
          goals
          ->Array.mapWithIndex((goal, idx) => {
            let isActive = idx === 0
            let bgClass = isActive
              ? "bg-indigo-900/30 border-indigo-500"
              : "bg-gray-800/30 border-gray-700"
            div(
              list{
                Attrs.class_(`text-xs p-1.5 border-l-2 ${bgClass} mb-0.5 font-mono`),
                Attrs.role("listitem"),
              },
              list{
                text(Int.toString(idx + 1) ++ ". " ++ goal),
              },
            )
          })
          ->List.fromArray,
        ),
      },
    )
  }
}

/// Render a manual tactic input field with an "Apply" button.
/// Disabled when no session is active.
let renderTacticInput = (echidna: echidnaState): Tea_Vdom.t<msg> => {
  let hasSession = switch echidna.session {
  | Some(_) => true
  | None => false
  }

  div(
    list{Attrs.class_("mb-2")},
    list{
      div(
        list{Attrs.class_("text-xs text-gray-500 mb-1")},
        list{text("TACTIC INPUT")},
      ),
      div(
        list{Attrs.class_("flex gap-1")},
        list{
          input(
            list{
              Attrs.class_(
                "flex-1 bg-gray-800/50 rounded px-2 py-1 text-xs text-gray-200 border border-gray-700 focus:border-indigo-500 focus:outline-none font-mono",
              ),
              Attrs.placeholder("e.g., intro x"),
              Attrs.value(echidna.tacticInput),
              Attrs.disabled(!hasSession),
              Attrs.ariaLabel("Manual tactic input"),
              Events.onInput(text => Echidna(UpdateTacticInput(text))),
            },
            list{},
          ),
          button(
            list{
              Attrs.class_(
                "text-xs px-3 py-1 bg-indigo-700 hover:bg-indigo-600 text-white rounded disabled:opacity-50 disabled:cursor-not-allowed",
              ),
              Attrs.disabled(!hasSession || echidna.tacticInput === ""),
              Attrs.ariaLabel("Apply Tactic"),
              Events.onClick(Echidna(ApplyTactic(echidna.tacticInput, []))),
            },
            list{text("Apply")},
          ),
        },
      ),
    },
  )
}

/// Render the tactic suggestion ribbon — horizontal scrollable row of clickable chips
/// sorted by confidence (descending). Each chip shows "tactic (confidence%)".
/// Clicking a chip dispatches ApplyTactic with the tactic name and args.
let renderTacticSuggestionRibbon = (suggestions: array<echidnaTacticSuggestion>): Tea_Vdom.t<msg> => {
  if Array.length(suggestions) === 0 {
    noNode
  } else {
    // Sort by confidence descending
    let sorted = Array.copy(suggestions)
    sorted->Array.sort((a, b) => Float.compare(b.confidence, a.confidence))

    div(
      list{Attrs.class_("mb-2")},
      list{
        div(
          list{Attrs.class_("text-xs text-gray-500 mb-1")},
          list{text("SUGGESTED TACTICS")},
        ),
        div(
          list{
            Attrs.class_("flex gap-1 overflow-x-auto pb-1"),
            Attrs.role("list"),
            Attrs.ariaLabel("Tactic Suggestions"),
          },
          sorted
          ->Array.map(suggestion => {
            let pct = Int.toString(Int.fromFloat(suggestion.confidence *. 100.0))
            button(
              list{
                Attrs.class_(
                  "text-xs px-2 py-1 bg-indigo-900/50 hover:bg-indigo-800/70 text-indigo-300 rounded whitespace-nowrap border border-indigo-700/50 cursor-pointer",
                ),
                Attrs.title(suggestion.description),
                Attrs.role("listitem"),
                Attrs.ariaLabel(suggestion.tactic ++ " (" ++ pct ++ "% confidence)"),
                Events.onClick(Echidna(ApplyTactic(suggestion.tactic, suggestion.args))),
              },
              list{text(suggestion.tactic ++ " (" ++ pct ++ "%)")},
            )
          })
          ->List.fromArray,
        ),
      },
    )
  }
}

/// Render the proof script — a scrollable list of applied tactics (proof history).
/// Displayed in monospace font with sequential numbering.
let renderProofScript = (script: array<string>): Tea_Vdom.t<msg> => {
  if Array.length(script) === 0 {
    noNode
  } else {
    div(
      list{Attrs.class_("mb-2")},
      list{
        div(
          list{Attrs.class_("text-xs text-gray-500 mb-1")},
          list{text("PROOF SCRIPT")},
        ),
        div(
          list{
            Attrs.class_("max-h-20 overflow-y-auto bg-gray-800/30 rounded p-1.5"),
            Attrs.role("log"),
            Attrs.ariaLabel("Proof Script"),
          },
          script
          ->Array.mapWithIndex((step, idx) =>
            div(
              list{Attrs.class_("text-xs text-gray-300 font-mono py-0.5")},
              list{text(Int.toString(idx + 1) ++ ". " ++ step)},
            )
          )
          ->List.fromArray,
        ),
      },
    )
  }
}

// ===========================================================================
// TypeLL Proof Obligations Display
// ===========================================================================

/// Render TypeLL proof obligations result (if available).
/// Parses the raw JSON via TypeLLEngine.parseCheckResult and displays
/// proof obligation details with linearity notes.
let viewProofObligations = (lastProofObligations: option<string>): Tea_Vdom.t<msg> => {
  switch lastProofObligations {
  | None => noNode
  | Some(json) =>
    switch TypeLLEngine.parseCheckResult(json) {
    | Error(_) => noNode
    | Ok(result) =>
      let narrative = TypeLLEngine.generateNarrative(result)
      let borderColour = if result.valid { "border-green-700 bg-green-900/20" } else { "border-red-700 bg-red-900/20" }
      let labelColour = if result.valid { "text-green-400" } else { "text-red-400" }
      let statusText = if result.valid { "Obligations generated" } else { "No obligations" }
      div(
        list{Attrs.class_("mt-4 p-3 rounded-lg border " ++ borderColour)},
        list{
          div(
            list{Attrs.class_("flex items-center gap-2 mb-2")},
            list{
              span(list{Attrs.class_("text-xs font-bold uppercase tracking-wider " ++ labelColour)}, list{text("TypeLL Proof Obligations")}),
              span(list{Attrs.class_("text-xs text-gray-400")}, list{text(statusText)}),
            },
          ),
          div(list{Attrs.class_("text-sm text-gray-300 font-mono mb-1")}, list{text(result.typeSignature)}),
          div(list{Attrs.class_("text-xs text-gray-400 mb-1")}, list{text(narrative.celebrate)}),
          if Array.length(result.proofObligations) > 0 {
            div(list{Attrs.class_("text-xs text-yellow-400 mt-1")}, list{
              text("Proof obligations: " ++ Array.join(result.proofObligations, ", ")),
            })
          } else {
            noNode
          },
          if Array.length(result.linearityIssues) > 0 {
            div(list{Attrs.class_("text-xs text-orange-400 mt-1")}, list{
              text("Linearity: " ++ Array.join(result.linearityIssues, ", ")),
            })
          } else {
            noNode
          },
        },
      )
    }
  }
}

// ===========================================================================
// Enterprise Model Checking Tab (MOF / OCL / ArchiMate)
// ===========================================================================

/// Render metamodel standard label.
let metamodelLabel = (m: metamodelStandard): string => {
  switch m {
  | UML => "UML"
  | SysML => "SysML"
  | ArchiMate => "ArchiMate"
  | BPMN => "BPMN"
  | DMN => "DMN"
  | CMMN => "CMMN"
  | ODM => "ODM"
  | CustomProfile => "Custom Profile"
  }
}

/// Render MOF layer label.
let mofLayerLabel = (l: mofLayer): string => {
  switch l {
  | M3_MetaMetaModel => "M3 (MOF)"
  | M2_Metamodel => "M2 (Metamodel)"
  | M2_Profile => "M2 (Profile)"
  | M1_Model => "M1 (Model)"
  | M0_Instance => "M0 (Instance)"
  }
}

/// Render OCL severity badge.
let oclSeverityBadge = (s: oclSeverity): Tea_Vdom.t<msg> => {
  let (label, colour) = switch s {
  | OclInvariant => ("inv", "bg-indigo-900/50 text-indigo-300 border-indigo-700/40")
  | OclPrecondition => ("pre", "bg-amber-900/50 text-amber-300 border-amber-700/40")
  | OclPostcondition => ("post", "bg-emerald-900/50 text-emerald-300 border-emerald-700/40")
  | OclDerive => ("derive", "bg-cyan-900/50 text-cyan-300 border-cyan-700/40")
  | OclInit => ("init", "bg-gray-800 text-gray-400 border-gray-700")
  | OclBody => ("body", "bg-gray-800 text-gray-400 border-gray-700")
  }
  span(
    list{Attrs.class_(`text-[9px] px-1.5 py-0.5 rounded border font-mono ${colour}`)},
    list{text(label)},
  )
}

/// Render a model element row.
let renderModelElement = (elem: modelElement): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex items-center gap-2 py-1.5 px-2 bg-gray-900/50 rounded text-[10px]")},
    list{
      span(list{Attrs.class_("text-gray-500 font-mono")}, list{text(mofLayerLabel(elem.layer))}),
      span(list{Attrs.class_("text-indigo-300 font-medium truncate flex-1")}, list{text(elem.qualifiedName)}),
      span(list{Attrs.class_("text-gray-600")}, list{text(elem.metaclass)}),
      span(
        list{Attrs.class_("text-[9px] px-1 py-0.5 bg-gray-800 rounded text-gray-500")},
        list{text(metamodelLabel(elem.metamodel))},
      ),
    },
  )
}

/// Render an OCL constraint row with check result.
let renderOclConstraintRow = (c: oclConstraint, index: int, result: option<oclCheckResult>): Tea_Vdom.t<msg> => {
  let statusIndicator = switch result {
  | Some(r) if r.satisfied =>
    span(list{Attrs.class_("text-emerald-400 font-mono text-[10px]")}, list{text("[OK]")})
  | Some(_) =>
    span(list{Attrs.class_("text-red-400 font-mono text-[10px]")}, list{text("[!!]")})
  | None =>
    span(list{Attrs.class_("text-gray-600 font-mono text-[10px]")}, list{text("[..]")})
  }

  div(
    list{Attrs.class_("py-2 px-2 bg-gray-900/50 rounded space-y-1")},
    list{
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          statusIndicator,
          oclSeverityBadge(c.severity),
          span(list{Attrs.class_("text-xs text-gray-200 font-medium")}, list{text(c.name)}),
          span(list{Attrs.class_("text-[10px] text-gray-600 ml-auto")}, list{text(c.context)}),
          button(
            list{
              Attrs.class_("text-gray-600 hover:text-red-400 text-[10px] px-1"),
              Attrs.title("Remove constraint"),
              Events.onClick(Echidna(RemoveOclConstraint(index))),
            },
            list{text("x")},
          ),
        },
      ),
      div(
        list{Attrs.class_("font-mono text-[10px] text-cyan-200/80 pl-6")},
        list{text(c.expression)},
      ),
      switch result {
      | Some(r) =>
        switch r.counterExample {
        | Some(ce) =>
          div(
            list{Attrs.class_("text-[10px] text-red-400/80 pl-6")},
            list{text("Counter-example: " ++ ce)},
          )
        | None => noNode
        }
      | None => noNode
      },
    },
  )
}

/// Render the enterprise model checking tab content.
let renderEnterpriseModelTab = (echidna: echidnaState): Tea_Vdom.t<msg> => {
  let em = echidna.enterpriseModel
  let elementCount = Array.length(em.elements)
  let constraintCount = Array.length(em.constraints)
  let passedCount = em.checkResults->Array.filter(r => r.satisfied)->Array.length
  let failedCount = Array.length(em.checkResults) - passedCount

  div(
    list{Attrs.class_("space-y-3")},
    list{
      // ─── Overview strip ───
      div(
        list{Attrs.class_("flex items-center gap-3 text-[10px]")},
        list{
          span(list{Attrs.class_("text-gray-500")}, list{text(`${Int.toString(elementCount)} elements`)}),
          span(list{Attrs.class_("text-gray-500")}, list{text(`${Int.toString(constraintCount)} constraints`)}),
          if Array.length(em.checkResults) > 0 {
            span(
              list{Attrs.class_("text-emerald-400")},
              list{text(`${Int.toString(passedCount)} passed`)},
            )
          } else { noNode },
          if failedCount > 0 {
            span(list{Attrs.class_("text-red-400")}, list{text(`${Int.toString(failedCount)} failed`)})
          } else { noNode },
        },
      ),

      // ─── Import / Actions ───
      div(
        list{Attrs.class_("flex gap-2")},
        list{
          button(
            list{
              Attrs.class_("px-3 py-1.5 text-xs bg-indigo-900/50 hover:bg-indigo-800/50 border border-indigo-700/40 rounded text-indigo-300"),
              Events.onClick(Echidna(ImportXmiModel)),
            },
            list{text("Import XMI")},
          ),
          button(
            list{
              Attrs.class_(
                `px-3 py-1.5 text-xs rounded font-medium ${em.checking
                  ? "bg-amber-900/50 text-amber-300 border border-amber-700/40"
                  : "bg-emerald-900/50 hover:bg-emerald-800/50 text-emerald-300 border border-emerald-700/40"}`,
              ),
              Events.onClick(Echidna(RunOclCheck)),
            },
            list{text(em.checking ? "Checking..." : "Run OCL Check")},
          ),
          button(
            list{
              Attrs.class_("px-3 py-1.5 text-xs bg-gray-800 hover:bg-gray-700 rounded text-gray-400"),
              Events.onClick(Echidna(ClearEnterpriseModel)),
            },
            list{text("Clear")},
          ),
        },
      ),

      // ─── Metamodel / Layer Filters ───
      div(
        list{Attrs.class_("flex items-center gap-2 flex-wrap")},
        list{
          span(list{Attrs.class_("text-[10px] text-gray-500")}, list{text("Filter:")}),
          ...[UML, SysML, ArchiMate, BPMN, DMN]
          ->Array.map(m => {
            let isActive = em.activeMetamodel === Some(m)
            button(
              list{
                Attrs.class_(
                  `px-2 py-0.5 text-[10px] rounded ${isActive
                    ? "bg-indigo-700 text-white"
                    : "bg-gray-800 text-gray-500 hover:text-gray-300"}`,
                ),
                Events.onClick(Echidna(SetMetamodelFilter(isActive ? None : Some(m)))),
              },
              list{text(metamodelLabel(m))},
            )
          })
          ->List.fromArray,
        },
      ),

      // ─── Model Elements ───
      if elementCount > 0 {
        div(
          list{Attrs.class_("space-y-1")},
          list{
            div(
              list{Attrs.class_("text-[10px] text-gray-500 font-semibold uppercase tracking-wider mb-1")},
              list{text("Model Elements")},
            ),
            ...em.elements
            ->Array.filter(e => {
              let metamodelMatch = switch em.activeMetamodel {
              | Some(m) => e.metamodel === m
              | None => true
              }
              let layerMatch = switch em.activeLayer {
              | Some(l) => e.layer === l
              | None => true
              }
              metamodelMatch && layerMatch
            })
            ->Array.map(renderModelElement)
            ->List.fromArray,
          },
        )
      } else {
        div(
          list{Attrs.class_("text-xs text-gray-600 italic p-3 text-center")},
          list{text("No model loaded. Import XMI from Visual Paradigm, Sparx EA, Archi, or other MOF-compliant tools.")},
        )
      },

      // ─── OCL Constraints ───
      div(
        list{Attrs.class_("space-y-1")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-2 mb-1")},
            list{
              span(list{Attrs.class_("text-[10px] text-gray-500 font-semibold uppercase tracking-wider")}, list{text("OCL Constraints")}),
              span(list{Attrs.class_("text-[9px] text-gray-600")}, list{text("(Object Constraint Language)")}),
            },
          ),
          ...em.constraints
          ->Array.mapWithIndex((c, i) => {
            let result = em.checkResults->Array.find(r => r.oclRule.name === c.name)
            renderOclConstraintRow(c, i, result)
          })
          ->List.fromArray,
          if constraintCount === 0 {
            div(
              list{Attrs.class_("text-[10px] text-gray-600 italic")},
              list{text("No constraints defined. Add OCL invariants, preconditions, or postconditions.")},
            )
          } else {
            noNode
          },
        },
      ),

      // ─── Standards Reference ───
      div(
        list{Attrs.class_("p-2 bg-gray-900/30 rounded border border-gray-800 text-[10px] text-gray-600 space-y-1")},
        list{
          div(list{Attrs.class_("font-semibold text-gray-500")}, list{text("Supported Standards")}),
          div(list{}, list{text("OMG: MOF 2.5, UML 2.5, SysML 1.7, BPMN 2.0, OCL 2.4, XMI 2.5, QVT 1.3")}),
          div(list{}, list{text("The Open Group: ArchiMate 3.2, TOGAF 10 (via ArchiMate)")}),
          div(list{}, list{text("Tools: Visual Paradigm, Sparx EA, Archi, Camunda, MagicDraw/Cameo")}),
        },
      ),
    },
  )
}

// ===========================================================================
// ECHIDNA Panel (tabbed: Proof + Enterprise Model)
// ===========================================================================

/// Render the complete ECHIDNA panel — a collapsible container with tab
/// switching between the theorem prover workbench and enterprise model
/// checking (MOF/OCL/ArchiMate).
let renderEchidnaPanel = (echidna: echidnaState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("mt-4 border-t border-gray-700 pt-3"), Attrs.role("region"), Attrs.ariaLabel("ECHIDNA Theorem Prover")},
    list{
      // Collapsible header
      button(
        list{
          Attrs.class_("flex items-center justify-between w-full mb-2 cursor-pointer"),
          Attrs.ariaExpanded(echidna.menuExpanded),
          Attrs.ariaLabel("Toggle ECHIDNA panel"),
          Events.onClick(Echidna(ToggleMenu)),
        },
        list{
          div(
            list{Attrs.class_("text-indigo-400 font-semibold text-sm")},
            list{text("ECHIDNA Prover")},
          ),
          div(
            list{Attrs.class_("text-gray-500 text-xs")},
            list{text(echidna.menuExpanded ? "[-]" : "[+]")},
          ),
        },
      ),
      // Connection indicator (always visible)
      renderEchidnaConnectionIndicator(echidna),
      // Collapsible content
      if echidna.menuExpanded {
        div(
          list{},
          list{
            // Tab bar
            div(
              list{Attrs.class_("flex gap-1 mb-3 border-b border-gray-800 pb-1")},
              list{
                button(
                  list{
                    Attrs.class_(
                      `px-3 py-1 text-xs rounded-t ${echidna.activeTab === EchidnaProofTab
                        ? "bg-gray-800 text-indigo-300 border-b-2 border-indigo-500"
                        : "text-gray-500 hover:text-gray-300"}`,
                    ),
                    Events.onClick(Echidna(SelectEchidnaTab(EchidnaProofTab))),
                  },
                  list{text("Proof")},
                ),
                button(
                  list{
                    Attrs.class_(
                      `px-3 py-1 text-xs rounded-t ${echidna.activeTab === EchidnaEnterpriseTab
                        ? "bg-gray-800 text-indigo-300 border-b-2 border-indigo-500"
                        : "text-gray-500 hover:text-gray-300"}`,
                    ),
                    Events.onClick(Echidna(SelectEchidnaTab(EchidnaEnterpriseTab))),
                  },
                  list{text("Enterprise (MOF/OCL)")},
                ),
              },
            ),
            // Tab content
            switch echidna.activeTab {
            | EchidnaProofTab =>
              div(
                list{},
                list{
                  renderProverCatalog(echidna),
                  renderProofInput(echidna),
                  renderSessionControls(echidna),
                  switch echidna.session {
                  | Some(session) =>
                    div(
                      list{Attrs.class_("mt-2"), Attrs.role("region"), Attrs.ariaLabel("Interactive Proof Session")},
                      list{
                        renderSessionStatus(session),
                        renderGoalList(session.goals),
                        renderTacticSuggestionRibbon(echidna.tacticSuggestions),
                        renderTacticInput(echidna),
                        renderProofScript(session.proofScript),
                        ProofChain.view(session),
                      },
                    )
                  | None => noNode
                  },
                  switch echidna.proofError {
                  | Some(err) =>
                    div(
                      list{Attrs.class_("text-xs text-red-400 mt-1 p-1 bg-red-900/20 rounded")},
                      list{text(err)},
                    )
                  | None => noNode
                  },
                  switch echidna.lastProofResult {
                  | Some(result) => renderProofResult(result)
                  | None => noNode
                  },
                  viewProofObligations(echidna.lastProofObligations),
                },
              )
            | EchidnaEnterpriseTab =>
              renderEnterpriseModelTab(echidna)
            },
          },
        )
      } else {
        noNode
      },
    },
  )
}

/// Main Pane-N view — renders the neural stream panel and the ECHIDNA
/// theorem prover panel below it.
/// Render VQL inference stream suggestions from VeriSimDB.
let renderInferenceStream = (suggestions: array<string>): Tea_Vdom.t<msg> => {
  if Array.length(suggestions) == 0 {
    noNode
  } else {
    div(
      list{Attrs.class_("mt-3 p-3 bg-violet-900/20 border border-violet-500/20 rounded")},
      list{
        div(
          list{Attrs.class_("flex items-center justify-between mb-2")},
          list{
            div(
              list{Attrs.class_("text-xs text-violet-400 font-semibold tracking-wide uppercase")},
              list{text(`VQL Inference Stream (${Int.toString(Array.length(suggestions))})`)},
            ),
            button(
              list{
                Attrs.class_("px-2 py-0.5 text-[10px] bg-violet-800/40 hover:bg-violet-700/40 rounded text-violet-300"),
                Events.onClick(VeriSimDB(ClearInferenceSuggestions)),
              },
              list{text("Clear")},
            ),
          },
        ),
        div(
          list{Attrs.class_("space-y-1 max-h-32 overflow-y-auto")},
          suggestions->Array.map(suggestion =>
            div(
              list{Attrs.class_("text-xs text-violet-300/80 font-mono pl-2 border-l-2 border-violet-500/30")},
              list{text(suggestion)},
            )
          )->List.fromArray,
        ),
      },
    )
  }
}

let view = (state: paneNState, echidna: echidnaState, ~inferenceStream: array<string>=[]): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("h-full flex flex-col p-4 bg-gray-900"), Attrs.role("region"), Attrs.ariaLabel("Neural Stream Panel")},
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between mb-4")},
        list{
          div(
            list{Attrs.class_("text-emerald-400 font-semibold")},
            list{text("Neural Stream")},
          ),
          div(
            list{Attrs.class_("text-xs text-gray-600")},
            list{text("Ctrl+Shift+N")},
          ),
        },
      ),

      // Agency monitor
      renderAgencyMonitor(state.agency),

      // Token stream
      renderTokenStream(state.tokens),

      // VQL Inference stream (from VeriSimDB)
      renderInferenceStream(inferenceStream),

      // Monologue
      renderMonologue(state.monologue, state.inferenceActive),

      // ECHIDNA Theorem Prover Panel
      renderEchidnaPanel(echidna),
    },
  )
}
