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

/// Render a neural token
let renderToken = (token: neuralToken): Tea_Vdom.t<msg> => {
  let validatedClass = token.validated ? "border-emerald-700" : "border-amber-700"
  let confidencePercent = Int.toString(Int.fromFloat(token.confidence *. 100.0))

  div(
    list{Attrs.class_(`p-2 mb-1 border-l-2 ${validatedClass} bg-gray-800/30`)},
    list{
      div(
        list{Attrs.class_("text-sm text-gray-300")},
        list{text(token.content)},
      ),
      div(
        list{Attrs.class_("text-xs text-gray-600 mt-1")},
        list{text(`confidence: ${confidencePercent}%`)},
      ),
    },
  )
}

/// Render the token stream
let renderTokenStream = (tokens: array<neuralToken>): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("mb-4")},
    list{
      div(
        list{Attrs.class_("text-xs text-gray-500 mb-2")},
        list{text("TOKEN STREAM")},
      ),
      if Array.length(tokens) === 0 {
        div(
          list{Attrs.class_("text-gray-600 text-sm italic")},
          list{text("No tokens received")},
        )
      } else {
        div(
          list{Attrs.class_("max-h-32 overflow-y-auto"), Attrs.role("log"), Attrs.ariaLabel("Token Stream")},
          tokens->Array.map(renderToken)->List.fromArray,
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
                Events.onClick(Echidna(SelectProver(isSelected ? None : Some(prover.name)))),
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
      list{Attrs.class_("mt-2")},
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
              Events.onClick(Echidna(ClearProofResult)),
            },
            list{text("Clear")},
          ),
        },
      ),
    },
  )
}

/// Render the complete ECHIDNA panel — a collapsible container that
/// composes the connection indicator, prover catalog, proof input,
/// and proof result into a coherent proving workbench.
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
            renderProverCatalog(echidna),
            renderProofInput(echidna),
            // Error display
            switch echidna.proofError {
            | Some(err) =>
              div(
                list{Attrs.class_("text-xs text-red-400 mt-1 p-1 bg-red-900/20 rounded")},
                list{text(err)},
              )
            | None => noNode
            },
            // Proof result
            switch echidna.lastProofResult {
            | Some(result) => renderProofResult(result)
            | None => noNode
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
let view = (state: paneNState, echidna: echidnaState): Tea_Vdom.t<msg> => {
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

      // Monologue
      renderMonologue(state.monologue, state.inferenceActive),

      // ECHIDNA Theorem Prover Panel
      renderEchidnaPanel(echidna),
    },
  )
}
