// SPDX-License-Identifier: MPL-2.0

/// PanLL StrategyDrift Component — visualises the learning loop's
/// top-prover-per-class recommendations, the PROVEN/SANCTIFY certificate
/// landscape, and strategy-shift events.
///
/// Data sources (all polled on a timer):
///   GET http://localhost:8080/api/v1/proof_attempts/certificates
///   GET http://localhost:8080/api/v1/proof_attempts/coverage
///   Hypatia.Rules.StrategyDrift.snapshot/0 (via HTTP bridge — TODO)
///
/// Layout: three stacked panels
///   1. Certs Grid   — 11 classes × N provers, cert-status colouring
///   2. Coverage Bars — per-class n_repos × n_provers × n_attempts
///   3. Drift Events — append-only log of shift events

open Tea.Html

// ── Shared types ───────────────────────────────────────────────────────

type certStatus = Proven | Pending | Sanctified | Unknown

type proverCert = {
  obligation_class: string,
  prover_used: string,
  success_rate: float,
  total_attempts: int,
  status: certStatus,
}

type classCoverage = {
  obligation_class: string,
  n_repos: int,
  n_provers: int,
  n_attempts: int,
  n_success: int,
}

type driftEvent = {
  timestamp: string,
  obligation_class: string,
  old_top: string,
  new_top: string,
  candidates_requeued: int,
}

type strategyDriftModel = {
  certs: array<proverCert>,
  coverage: array<classCoverage>,
  drift_events: array<driftEvent>,
  last_refresh: string,
  error: option<string>,
}

// ── Render helpers ─────────────────────────────────────────────────────

let statusBadge = (status: certStatus): Tea_Vdom.t<'msg> => {
  let (color, label) = switch status {
  | Proven => ("text-green-400 border-green-500", "PROVEN")
  | Sanctified => ("text-amber-300 border-amber-400 border-2", "SANCTIFIED")
  | Pending => ("text-gray-400 border-gray-600", "pending")
  | Unknown => ("text-gray-500 border-gray-700", "?")
  }
  span(
    list{Attrs.class_("inline-block px-2 py-1 text-xs font-mono border " ++ color)},
    list{text(label)},
  )
}

let certCell = (cert: proverCert): Tea_Vdom.t<'msg> => {
  let rate_pct = Js.Float.toFixedWithPrecision(cert.success_rate *. 100.0, ~digits=0)
  let intensity = if cert.success_rate > 0.9 {
    "bg-green-900/40"
  } else if cert.success_rate > 0.5 {
    "bg-yellow-900/40"
  } else {
    "bg-red-900/40"
  }
  div(
    list{Attrs.class_("p-2 border border-gray-700 " ++ intensity)},
    list{
      div(
        list{Attrs.class_("text-sm font-mono text-gray-200")},
        list{text(cert.prover_used)},
      ),
      div(
        list{Attrs.class_("text-xs font-mono text-gray-400")},
        list{text(rate_pct ++ "% · n=" ++ Belt.Int.toString(cert.total_attempts))},
      ),
      statusBadge(cert.status),
    },
  )
}

let certsGrid = (certs: array<proverCert>): Tea_Vdom.t<'msg> => {
  let grouped = Belt.Array.reduce(certs, Js.Dict.empty(), (acc, cert) => {
    let key = cert.obligation_class
    let existing = switch Js.Dict.get(acc, key) {
    | Some(arr) => arr
    | None => []
    }
    Js.Dict.set(acc, key, Belt.Array.concat(existing, [cert]))
    acc
  })
  let classes = Js.Dict.keys(grouped)

  div(
    list{Attrs.class_("mb-4")},
    list{
      h3(
        list{Attrs.class_("text-lg font-bold text-gray-200 mb-2")},
        list{text("Certificates Grid")},
      ),
      div(
        list{Attrs.class_("space-y-2")},
        Belt.Array.map(classes, class_name => {
          let class_certs = switch Js.Dict.get(grouped, class_name) {
          | Some(arr) => arr
          | None => []
          }
          div(
            list{Attrs.class_("border-l-2 border-blue-500 pl-2")},
            list{
              div(
                list{Attrs.class_("text-sm font-mono text-gray-300 mb-1")},
                list{text(class_name)},
              ),
              div(
                list{Attrs.class_("flex gap-2 flex-wrap")},
                Belt.Array.map(class_certs, certCell)->Belt.List.fromArray,
              ),
            },
          )
        })->Belt.List.fromArray,
      ),
    },
  )
}

let coverageBar = (cov: classCoverage): Tea_Vdom.t<'msg> => {
  let bar_width = Js.Math.min_int(cov.n_attempts * 2, 400)
  let bar_width_str = Belt.Int.toString(bar_width) ++ "px"
  div(
    list{Attrs.class_("flex items-center gap-3 py-1")},
    list{
      span(
        list{Attrs.class_("text-xs font-mono text-gray-400 w-24")},
        list{text(cov.obligation_class)},
      ),
      div(
        list{
          Attrs.class_("h-4 bg-blue-900/60 border border-blue-700"),
          Attrs.style("width", bar_width_str),
        },
        list{},
      ),
      span(
        list{Attrs.class_("text-xs font-mono text-gray-400")},
        list{
          text(
            "n=" ++
            Belt.Int.toString(cov.n_attempts) ++
            " · " ++
            Belt.Int.toString(cov.n_repos) ++
            " repos · " ++
            Belt.Int.toString(cov.n_provers) ++
            " provers",
          ),
        },
      ),
    },
  )
}

let coverageBars = (coverage: array<classCoverage>): Tea_Vdom.t<'msg> => {
  div(
    list{Attrs.class_("mb-4")},
    list{
      h3(
        list{Attrs.class_("text-lg font-bold text-gray-200 mb-2")},
        list{text("Cross-Repo Coverage")},
      ),
      div(list{Attrs.class_("space-y-1")}, Belt.Array.map(coverage, coverageBar)->Belt.List.fromArray),
    },
  )
}

let driftEventRow = (event: driftEvent): Tea_Vdom.t<'msg> => {
  div(
    list{Attrs.class_("flex gap-3 py-1 text-xs font-mono border-b border-gray-800")},
    list{
      span(list{Attrs.class_("text-gray-500 w-40")}, list{text(event.timestamp)}),
      span(list{Attrs.class_("text-blue-300 w-24")}, list{text(event.obligation_class)}),
      span(
        list{Attrs.class_("text-gray-400")},
        list{text(event.old_top ++ " → ")},
      ),
      span(list{Attrs.class_("text-green-400")}, list{text(event.new_top)}),
      span(
        list{Attrs.class_("text-amber-300 ml-auto")},
        list{
          text("re-queued " ++ Belt.Int.toString(event.candidates_requeued)),
        },
      ),
    },
  )
}

let driftEventsPanel = (events: array<driftEvent>): Tea_Vdom.t<'msg> => {
  div(
    list{},
    list{
      h3(
        list{Attrs.class_("text-lg font-bold text-gray-200 mb-2")},
        list{text("Strategy Drift Events")},
      ),
      if Array.length(events) == 0 {
        div(
          list{Attrs.class_("text-sm text-gray-500 italic")},
          list{text("No shifts detected yet.")},
        )
      } else {
        div(list{Attrs.class_("space-y-0")}, Belt.Array.map(events, driftEventRow)->Belt.List.fromArray)
      },
    },
  )
}

// ── Top-level view ─────────────────────────────────────────────────────

let view = (model: strategyDriftModel): Tea_Vdom.t<'msg> => {
  div(
    list{Attrs.class_("strategy-drift-panel p-4 bg-gray-900 text-gray-200 min-h-full")},
    list{
      div(
        list{Attrs.class_("flex items-baseline justify-between mb-4")},
        list{
          h2(
            list{Attrs.class_("text-xl font-bold")},
            list{text("Strategy Drift")},
          ),
          span(
            list{Attrs.class_("text-xs font-mono text-gray-500")},
            list{text("refreshed: " ++ model.last_refresh)},
          ),
        },
      ),
      switch model.error {
      | Some(err) =>
        div(
          list{Attrs.class_("mb-4 p-2 border border-red-700 bg-red-900/40 text-red-300 text-xs")},
          list{text("error: " ++ err)},
        )
      | None => noNode
      },
      certsGrid(model.certs),
      coverageBars(model.coverage),
      driftEventsPanel(model.drift_events),
    },
  )
}

// ── Decoders (JSON from verisim-api) ───────────────────────────────────

let certStatusOfString = (s: string): certStatus => {
  switch s {
  | "proven" => Proven
  | "sanctified" => Sanctified
  | "pending" => Pending
  | _ => Unknown
  }
}
