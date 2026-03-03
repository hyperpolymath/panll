// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Aerie Component — Network diagnostics dashboard.
///
/// Latency gauges, speed test results, BGP route analysis,
/// probe configuration. Backend: V-lang API at :4000.

open Model
open Msg
open Tea.Html

let renderLatencyCard = (result: latencyResult): Tea_Vdom.t<msg> => {
  let color = AerieEngine.latencyColor(result.rttMs)
  let quality = AerieEngine.latencyQuality(result.rttMs)
  div(
    list{
      Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-4"),
      Attrs.role("article"),
      Attrs.ariaLabel(`${result.endpoint}: ${Float.toFixed(result.rttMs, ~digits=1)}ms`),
    },
    list{
      div(list{Attrs.class_("text-xs text-gray-500 truncate mb-1")}, list{text(result.endpoint)}),
      div(
        list{Attrs.class_(`text-2xl font-light ${color}`)},
        list{text(`${Float.toFixed(result.rttMs, ~digits=1)}ms`)},
      ),
      div(list{Attrs.class_("flex justify-between text-xs text-gray-500 mt-2")}, list{
        span(list{}, list{text(quality)}),
        span(list{}, list{text(`jitter: ${Float.toFixed(result.jitterMs, ~digits=1)}ms`)}),
      }),
      if result.packetLoss > 0.0 {
        div(list{Attrs.class_("text-xs text-red-400 mt-1")}, list{text(`${Float.toFixed(result.packetLoss, ~digits=1)}% loss`)})
      } else { noNode },
    },
  )
}

let renderTabs = (active: aerieCategory): Tea_Vdom.t<msg> => {
  let tabs: array<aerieCategory> = [AerieDashboard, AerieSpeedTests, AerieBgp, AerieProbes]
  div(
    list{Attrs.class_("flex gap-1 border-b border-gray-800 mb-4"), Attrs.role("tablist")},
    tabs->Array.map(tab => {
      let isActive = tab === active
      button(
        list{
          Attrs.class_(`px-4 py-2 text-sm rounded-t transition-colors ${isActive ? "bg-gray-800 text-gray-200 border-b-2 border-violet-500" : "text-gray-500 hover:text-gray-300"}`),
          Attrs.role("tab"), Attrs.ariaSelected(isActive),
          Events.onClick(Aerie(SetAerieCategory(tab))),
        },
        list{text(AerieEngine.categoryLabel(tab))},
      )
    })->List.fromArray,
  )
}

let view = (aerie: aerieState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"), Attrs.role("dialog"), Attrs.ariaLabel("Aerie network diagnostics panel")},
    list{
      div(list{Attrs.class_("flex items-center justify-between p-4 border-b border-gray-800")}, list{
        div(list{Attrs.class_("flex items-center gap-3")}, list{
          h2(list{Attrs.class_("text-lg font-medium text-gray-200")}, list{text("Aerie")}),
          span(list{Attrs.class_("text-xs text-gray-500")}, list{text("network diagnostics & BGP forensics")}),
          if aerie.bgpAnomalyCount > 0 {
            span(list{Attrs.class_("text-xs text-red-400 ml-2")}, list{text(`${Int.toString(aerie.bgpAnomalyCount)} BGP anomalies`)})
          } else { noNode },
        }),
        div(list{Attrs.class_("flex items-center gap-3")}, list{
          button(list{Attrs.class_("px-3 py-1 text-xs bg-violet-600 text-white rounded hover:bg-violet-500"), Events.onClick(Aerie(LoadAerie))}, list{text("Refresh")}),
          button(list{Attrs.class_("px-3 py-1 text-sm bg-gray-800 text-gray-300 rounded hover:bg-gray-700"), Events.onClick(PanelSwitcher(ClosePanels))}, list{text("Close")}),
        }),
      }),
      div(list{Attrs.class_("flex-1 overflow-auto p-6")}, list{
        if !aerie.loaded && !aerie.loading {
          div(list{Attrs.class_("text-center text-gray-500 mt-12")}, list{
            div(list{Attrs.class_("text-4xl mb-2")}, list{text("Aerie")}),
            div(list{Attrs.class_("text-sm mb-6")}, list{text("Network health, speed tests, BGP analysis, proof envelopes")}),
            button(list{Attrs.class_("px-4 py-2 bg-violet-600 text-white rounded hover:bg-violet-500"), Events.onClick(Aerie(LoadAerie))}, list{text("Connect to Aerie")}),
          })
        } else {
          div(list{Attrs.class_("space-y-4")}, list{
            renderTabs(aerie.activeCategory),
            switch aerie.activeCategory {
            | AerieDashboard =>
              div(list{Attrs.class_("space-y-6")}, list{
                div(list{Attrs.class_("flex gap-4 text-sm text-gray-400")}, list{
                  text(`${Int.toString(Array.length(aerie.probes))} probes`),
                  text(`avg: ${Float.toFixed(AerieEngine.avgLatency(aerie.latencyResults), ~digits=1)}ms`),
                }),
                div(
                  list{Attrs.class_("grid grid-cols-4 gap-3"), Attrs.role("list"), Attrs.ariaLabel("Latency measurements")},
                  aerie.latencyResults->Array.map(r => renderLatencyCard(r))->List.fromArray,
                ),
              })
            | AerieSpeedTests =>
              div(list{Attrs.class_("space-y-3")},
                aerie.speedTests->Array.map(st =>
                  div(list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-4 flex justify-between")}, list{
                    div(list{}, list{
                      div(list{Attrs.class_("text-green-400 text-lg")}, list{text(`${Float.toFixed(st.downloadMbps, ~digits=1)} Mbps down`)}),
                      div(list{Attrs.class_("text-blue-400 text-sm")}, list{text(`${Float.toFixed(st.uploadMbps, ~digits=1)} Mbps up`)}),
                    }),
                    div(list{Attrs.class_("text-right")}, list{
                      div(list{Attrs.class_("text-xs text-gray-500")}, list{text(st.serverLocation)}),
                      div(list{Attrs.class_("text-xs text-gray-600")}, list{text(`${Float.toFixed(st.pingMs, ~digits=0)}ms ping`)}),
                    }),
                  })
                )->List.fromArray,
              )
            | AerieBgp =>
              div(list{Attrs.class_("text-gray-500 text-sm")}, list{text("BGP route analysis — connect to Aerie backend for live data")})
            | AerieProbes =>
              div(list{Attrs.class_("text-gray-500 text-sm")}, list{text(`${Int.toString(Array.length(aerie.probes))} probe targets configured`)})
            },
          })
        },
        switch aerie.error {
        | Some(e) => div(list{Attrs.class_("mt-4 p-3 bg-red-900/30 border border-red-700 rounded text-sm text-red-300"), Attrs.role("alert")}, list{text(e)})
        | None => noNode
        },
      }),
    },
  )
}
