// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Aerie Component — Network diagnostics dashboard.
///
/// Latency gauges, speed test results, BGP route analysis,
/// probe configuration. Backend: V-lang API at :4000.

open Model
open Msg
open Tea.Html

/// Render a single latency measurement card showing RTT, jitter, quality, and packet loss.
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
      div(
        list{Attrs.class_("flex justify-between text-xs text-gray-500 mt-2")},
        list{
          span(list{}, list{text(quality)}),
          span(list{}, list{text(`jitter: ${Float.toFixed(result.jitterMs, ~digits=1)}ms`)}),
        },
      ),
      if result.packetLoss > 0.0 {
        div(
          list{Attrs.class_("text-xs text-red-400 mt-1")},
          list{text(`${Float.toFixed(result.packetLoss, ~digits=1)}% loss`)},
        )
      } else {
        noNode
      },
    },
  )
}

/// Render the category tab bar (Dashboard, Speed Tests, BGP, Probes).
let renderTabs = (active: aerieCategory): Tea_Vdom.t<msg> => {
  let tabs: array<aerieCategory> = [AerieDashboard, AerieSpeedTests, AerieBgp, AerieProbes]
  div(
    list{Attrs.class_("flex gap-1 border-b border-gray-800 mb-4"), Attrs.role("tablist")},
    tabs
    ->Array.map(tab => {
      let isActive = tab === active
      button(
        list{
          Attrs.class_(
            `px-4 py-2 text-sm rounded-t transition-colors ${isActive
                ? "bg-gray-800 text-gray-200 border-b-2 border-violet-500"
                : "text-gray-500 hover:text-gray-300"}`,
          ),
          Attrs.role("tab"),
          Attrs.ariaSelected(isActive),
          Events.onClick(Aerie(SetAerieCategory(tab))),
        },
        list{text(AerieEngine.categoryLabel(tab))},
      )
    })
    ->List.fromArray,
  )
}

/// Main Aerie panel view — full-screen overlay for network diagnostics and BGP forensics.
let view = (aerie: aerieState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Aerie network diagnostics panel"),
    },
    list{
      div(
        list{Attrs.class_("flex items-center justify-between p-4 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(list{Attrs.class_("text-lg font-medium text-gray-200")}, list{text("Aerie")}),
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text("network diagnostics & BGP forensics")},
              ),
              if aerie.bgpAnomalyCount > 0 {
                span(
                  list{Attrs.class_("text-xs text-red-400 ml-2")},
                  list{text(`${Int.toString(aerie.bgpAnomalyCount)} BGP anomalies`)},
                )
              } else {
                noNode
              },
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 text-xs bg-violet-600 text-white rounded hover:bg-violet-500",
                  ),
                  Events.onClick(Aerie(LoadAerie)),
                },
                list{text("Refresh")},
              ),
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 text-sm bg-gray-800 text-gray-300 rounded hover:bg-gray-700",
                  ),
                  Events.onClick(PanelSwitcher(ClosePanels)),
                },
                list{text("Close")},
              ),
            },
          ),
        },
      ),
      div(
        list{Attrs.class_("flex-1 overflow-auto p-6")},
        list{
          if !aerie.loaded && !aerie.loading {
            div(
              list{Attrs.class_("text-center text-gray-500 mt-12")},
              list{
                div(list{Attrs.class_("text-4xl mb-2")}, list{text("Aerie")}),
                div(
                  list{Attrs.class_("text-sm mb-6")},
                  list{text("Network health, speed tests, BGP analysis, proof envelopes")},
                ),
                button(
                  list{
                    Attrs.class_("px-4 py-2 bg-violet-600 text-white rounded hover:bg-violet-500"),
                    Events.onClick(Aerie(LoadAerie)),
                  },
                  list{text("Connect to Aerie")},
                ),
              },
            )
          } else {
            div(
              list{Attrs.class_("space-y-4")},
              list{
                renderTabs(aerie.activeCategory),
                switch aerie.activeCategory {
                | AerieDashboard =>
                  div(
                    list{Attrs.class_("space-y-6")},
                    list{
                      {
                        let avg = AerieEngine.avgLatency(aerie.latencyResults)
                        let maxRtt =
                          aerie.latencyResults->Array.reduce(0.0, (acc, r) =>
                            Math.max(acc, r.rttMs)
                          )
                        let minRtt = if Array.length(aerie.latencyResults) > 0 {
                          aerie.latencyResults->Array.reduce(99999.0, (acc, r) =>
                            Math.min(acc, r.rttMs)
                          )
                        } else {
                          0.0
                        }
                        let totalLoss =
                          aerie.latencyResults->Array.reduce(0.0, (acc, r) => acc +. r.packetLoss)
                        div(
                          list{Attrs.class_("flex gap-6 text-sm")},
                          list{
                            div(
                              list{Attrs.class_("text-gray-400")},
                              list{text(`${Int.toString(Array.length(aerie.probes))} probes`)},
                            ),
                            div(
                              list{Attrs.class_(AerieEngine.latencyColor(avg))},
                              list{text(`avg: ${Float.toFixed(avg, ~digits=1)}ms`)},
                            ),
                            div(
                              list{Attrs.class_("text-green-400")},
                              list{text(`min: ${Float.toFixed(minRtt, ~digits=1)}ms`)},
                            ),
                            div(
                              list{Attrs.class_(AerieEngine.latencyColor(maxRtt))},
                              list{text(`max: ${Float.toFixed(maxRtt, ~digits=1)}ms`)},
                            ),
                            if totalLoss > 0.0 {
                              div(
                                list{Attrs.class_("text-red-400")},
                                list{text(`loss: ${Float.toFixed(totalLoss, ~digits=1)}%`)},
                              )
                            } else {
                              div(list{Attrs.class_("text-green-500")}, list{text("0% loss")})
                            },
                            div(
                              list{Attrs.class_("text-gray-400")},
                              list{
                                text(
                                  `jitter: ${Float.toFixed(
                                      AerieEngine.avgJitter(aerie.latencyResults),
                                      ~digits=1,
                                    )}ms`,
                                ),
                              },
                            ),
                            div(
                              list{Attrs.class_(AerieEngine.mtuColor(aerie.mtuResult))},
                              list{text(`MTU: ${AerieEngine.mtuStatus(aerie.mtuResult)}`)},
                            ),
                            div(
                              list{Attrs.class_("text-gray-400")},
                              list{
                                text(
                                  `${Int.toString(
                                      AerieEngine.interfacesUp(aerie.interfaces),
                                    )}/${Int.toString(Array.length(aerie.interfaces))} ifaces up`,
                                ),
                              },
                            ),
                            if aerie.bgpAnomalyCount > 0 {
                              div(
                                list{Attrs.class_("text-red-400 font-medium")},
                                list{text(`${Int.toString(aerie.bgpAnomalyCount)} BGP anomalies`)},
                              )
                            } else {
                              noNode
                            },
                          },
                        )
                      },
                      // Interface summary cards
                      if Array.length(aerie.interfaces) > 0 {
                        div(
                          list{Attrs.class_("grid grid-cols-3 gap-3")},
                          aerie.interfaces
                          ->Array.map(iface =>
                            div(
                              list{
                                Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-3"),
                              },
                              list{
                                div(
                                  list{Attrs.class_("flex justify-between items-center mb-1")},
                                  list{
                                    span(
                                      list{Attrs.class_("text-sm text-gray-200 font-mono")},
                                      list{text(iface.name)},
                                    ),
                                    span(
                                      list{
                                        Attrs.class_(
                                          `text-xs ${iface.isUp
                                              ? "text-green-400"
                                              : "text-red-400"}`,
                                        ),
                                      },
                                      list{
                                        text(
                                          if iface.isUp {
                                            "UP"
                                          } else {
                                            "DOWN"
                                          },
                                        ),
                                      },
                                    ),
                                  },
                                ),
                                div(
                                  list{Attrs.class_("text-xs text-gray-500")},
                                  list{
                                    text(iface.linkType),
                                    switch iface.ipAddress {
                                    | Some(ip) => span(list{Attrs.class_("ml-2")}, list{text(ip)})
                                    | None =>
                                      span(
                                        list{Attrs.class_("ml-2 text-gray-600")},
                                        list{text("no IP")},
                                      )
                                    },
                                    switch iface.signalDbm {
                                    | Some(dbm) =>
                                      span(
                                        list{Attrs.class_("ml-2")},
                                        list{text(`${Int.toString(dbm)} dBm`)},
                                      )
                                    | None => noNode
                                    },
                                  },
                                ),
                              },
                            )
                          )
                          ->List.fromArray,
                        )
                      } else {
                        noNode
                      },
                      // Latency cards
                      div(
                        list{
                          Attrs.class_("grid grid-cols-4 gap-3"),
                          Attrs.role("list"),
                          Attrs.ariaLabel("Latency measurements"),
                        },
                        aerie.latencyResults->Array.map(r => renderLatencyCard(r))->List.fromArray,
                      ),
                      // Latency histogram (bar chart of measurements)
                      if Array.length(aerie.latencyResults) > 0 {
                        div(
                          list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-4")},
                          list{
                            div(
                              list{Attrs.class_("text-sm font-medium text-gray-300 mb-3")},
                              list{text("Latency Distribution")},
                            ),
                            div(
                              list{Attrs.class_("flex items-end gap-1 h-24")},
                              aerie.latencyResults
                              ->Array.map(r => {
                                let maxH = 96.0 // h-24 = 6rem = 96px
                                let maxRttForScale =
                                  aerie.latencyResults->Array.reduce(1.0, (acc, r2) =>
                                    Math.max(acc, r2.rttMs)
                                  )
                                let barH = Math.max(4.0, r.rttMs /. maxRttForScale *. maxH)
                                let barColor = if r.rttMs < 20.0 {
                                  "bg-green-500"
                                } else if r.rttMs < 50.0 {
                                  "bg-emerald-500"
                                } else if r.rttMs < 100.0 {
                                  "bg-amber-500"
                                } else {
                                  "bg-red-500"
                                }
                                div(
                                  list{
                                    Attrs.class_(
                                      `flex-1 ${barColor} rounded-t transition-all cursor-default`,
                                    ),
                                    Attrs.prop(
                                      "style",
                                      `height: ${Float.toFixed(barH, ~digits=0)}px`,
                                    ),
                                    Attrs.title(
                                      `${r.endpoint}: ${Float.toFixed(r.rttMs, ~digits=1)}ms`,
                                    ),
                                  },
                                  list{},
                                )
                              })
                              ->List.fromArray,
                            ),
                            // Endpoint labels
                            div(
                              list{Attrs.class_("flex gap-1 mt-1")},
                              aerie.latencyResults
                              ->Array.map(r =>
                                div(
                                  list{
                                    Attrs.class_(
                                      "flex-1 text-[8px] text-gray-600 truncate text-center",
                                    ),
                                  },
                                  list{text(r.endpoint)},
                                )
                              )
                              ->List.fromArray,
                            ),
                          },
                        )
                      } else {
                        noNode
                      },
                    },
                  )
                | AerieSpeedTests =>
                  div(
                    list{Attrs.class_("space-y-3")},
                    aerie.speedTests
                    ->Array.map(st =>
                      div(
                        list{
                          Attrs.class_(
                            "bg-gray-900 border border-gray-700 rounded-lg p-4 flex justify-between",
                          ),
                        },
                        list{
                          div(
                            list{},
                            list{
                              div(
                                list{Attrs.class_("text-green-400 text-lg")},
                                list{
                                  text(`${Float.toFixed(st.downloadMbps, ~digits=1)} Mbps down`),
                                },
                              ),
                              div(
                                list{Attrs.class_("text-blue-400 text-sm")},
                                list{text(`${Float.toFixed(st.uploadMbps, ~digits=1)} Mbps up`)},
                              ),
                            },
                          ),
                          div(
                            list{Attrs.class_("text-right")},
                            list{
                              div(
                                list{Attrs.class_("text-xs text-gray-500")},
                                list{text(st.serverLocation)},
                              ),
                              div(
                                list{Attrs.class_("text-xs text-gray-600")},
                                list{text(`${Float.toFixed(st.pingMs, ~digits=0)}ms ping`)},
                              ),
                            },
                          ),
                        },
                      )
                    )
                    ->List.fromArray,
                  )
                | AerieBgp =>
                  div(
                    list{Attrs.class_("space-y-4")},
                    list{
                      {
                        let total = Array.length(aerie.bgpRoutes)
                        let anomalous =
                          aerie.bgpRoutes->Array.filter(r => r.anomalous)->Array.length
                        let clean = total - anomalous
                        div(
                          list{Attrs.class_("flex gap-4 text-xs")},
                          list{
                            span(
                              list{Attrs.class_("text-gray-400")},
                              list{text(`${Int.toString(total)} routes`)},
                            ),
                            span(
                              list{Attrs.class_("text-green-400")},
                              list{text(`${Int.toString(clean)} clean`)},
                            ),
                            if anomalous > 0 {
                              span(
                                list{Attrs.class_("text-red-400 font-medium")},
                                list{text(`${Int.toString(anomalous)} anomalous`)},
                              )
                            } else {
                              span(list{Attrs.class_("text-green-500")}, list{text("No anomalies")})
                            },
                          },
                        )
                      },
                      // BGP route table
                      if Array.length(aerie.bgpRoutes) > 0 {
                        div(
                          list{Attrs.class_("border border-gray-700 rounded-lg overflow-hidden")},
                          list{
                            // Header
                            div(
                              list{
                                Attrs.class_(
                                  "flex items-center gap-3 p-3 bg-gray-900 border-b border-gray-700 text-xs text-gray-500",
                                ),
                              },
                              list{
                                span(list{Attrs.class_("w-8")}, list{text("")}),
                                span(list{Attrs.class_("w-40")}, list{text("Prefix")}),
                                span(list{Attrs.class_("flex-1")}, list{text("AS Path")}),
                                span(list{Attrs.class_("w-32")}, list{text("Next Hop")}),
                                span(list{Attrs.class_("w-48")}, list{text("Detail")}),
                              },
                            ),
                            // Routes
                            div(
                              list{Attrs.class_("max-h-96 overflow-y-auto")},
                              aerie.bgpRoutes
                              ->Array.map(route => {
                                let rowBg = route.anomalous
                                  ? "bg-red-900/20"
                                  : "hover:bg-gray-900/50"
                                div(
                                  list{
                                    Attrs.class_(
                                      `flex items-center gap-3 p-3 border-b border-gray-800 ${rowBg}`,
                                    ),
                                    Attrs.role("row"),
                                  },
                                  list{
                                    // Anomaly indicator
                                    span(
                                      list{
                                        Attrs.class_(
                                          `w-8 text-center text-xs font-bold ${route.anomalous
                                              ? "text-red-400"
                                              : "text-green-500"}`,
                                        ),
                                      },
                                      list{text(route.anomalous ? "!" : "ok")},
                                    ),
                                    // Prefix
                                    span(
                                      list{Attrs.class_("w-40 text-sm text-gray-300 font-mono")},
                                      list{text(route.prefix)},
                                    ),
                                    // AS Path
                                    span(
                                      list{
                                        Attrs.class_(
                                          "flex-1 text-xs text-gray-400 font-mono truncate",
                                        ),
                                      },
                                      list{
                                        text(
                                          route.asPath
                                          ->Array.map(asn => Int.toString(asn))
                                          ->Array.join(" → "),
                                        ),
                                      },
                                    ),
                                    // Next hop
                                    span(
                                      list{Attrs.class_("w-32 text-xs text-gray-500 font-mono")},
                                      list{text(route.nextHop)},
                                    ),
                                    // Anomaly detail
                                    switch route.anomalyDetail {
                                    | Some(detail) =>
                                      span(
                                        list{Attrs.class_("w-48 text-xs text-red-400 truncate")},
                                        list{text(detail)},
                                      )
                                    | None =>
                                      span(
                                        list{Attrs.class_("w-48 text-xs text-gray-700")},
                                        list{text("-")},
                                      )
                                    },
                                  },
                                )
                              })
                              ->List.fromArray,
                            ),
                          },
                        )
                      } else {
                        div(
                          list{Attrs.class_("text-center py-12")},
                          list{
                            div(
                              list{Attrs.class_("text-gray-600 text-sm")},
                              list{text("No BGP route data available")},
                            ),
                            div(
                              list{Attrs.class_("text-xs text-gray-700 mt-1")},
                              list{text("Connect to the Aerie backend for live BGP analysis")},
                            ),
                          },
                        )
                      },
                    },
                  )
                | AerieProbes =>
                  div(
                    list{Attrs.class_("space-y-4")},
                    list{
                      {
                        let active = aerie.probes->Array.filter(p => p.active)->Array.length
                        let inactive = Array.length(aerie.probes) - active
                        div(
                          list{Attrs.class_("flex gap-4 text-xs")},
                          list{
                            span(
                              list{Attrs.class_("text-gray-400")},
                              list{
                                text(
                                  `${Int.toString(Array.length(aerie.probes))} probes configured`,
                                ),
                              },
                            ),
                            span(
                              list{Attrs.class_("text-green-400")},
                              list{text(`${Int.toString(active)} active`)},
                            ),
                            if inactive > 0 {
                              span(
                                list{Attrs.class_("text-gray-600")},
                                list{text(`${Int.toString(inactive)} inactive`)},
                              )
                            } else {
                              noNode
                            },
                          },
                        )
                      },
                      // Probe list
                      if Array.length(aerie.probes) > 0 {
                        div(
                          list{Attrs.class_("space-y-2")},
                          aerie.probes
                          ->Array.map(probe => {
                            let statusColor = probe.active ? "bg-green-500" : "bg-gray-600"
                            div(
                              list{
                                Attrs.class_(
                                  "flex items-center gap-3 p-3 bg-gray-900 border border-gray-700 rounded-lg",
                                ),
                              },
                              list{
                                // Active indicator
                                div(
                                  list{Attrs.class_(`w-2 h-2 rounded-full ${statusColor}`)},
                                  list{},
                                ),
                                // Label
                                div(
                                  list{Attrs.class_("flex-1")},
                                  list{
                                    div(
                                      list{Attrs.class_("text-sm text-gray-200")},
                                      list{text(probe.label)},
                                    ),
                                    div(
                                      list{Attrs.class_("text-xs text-gray-500 font-mono")},
                                      list{text(probe.endpoint)},
                                    ),
                                  },
                                ),
                                // Protocol badge
                                span(
                                  list{
                                    Attrs.class_(
                                      "px-2 py-0.5 text-xs bg-gray-800 text-gray-400 rounded border border-gray-700",
                                    ),
                                  },
                                  list{text(probe.protocol)},
                                ),
                                // Toggle button
                                button(
                                  list{
                                    Attrs.class_(
                                      `px-3 py-1 text-xs rounded transition-colors ${probe.active
                                          ? "bg-red-900/40 text-red-400 hover:bg-red-900/60"
                                          : "bg-green-900/40 text-green-400 hover:bg-green-900/60"}`,
                                    ),
                                    Events.onClick(Aerie(ToggleProbe(probe.endpoint))),
                                  },
                                  list{text(probe.active ? "Disable" : "Enable")},
                                ),
                              },
                            )
                          })
                          ->List.fromArray,
                        )
                      } else {
                        div(
                          list{Attrs.class_("text-center py-12")},
                          list{
                            div(
                              list{Attrs.class_("text-gray-600 text-sm")},
                              list{text("No probes configured")},
                            ),
                            div(
                              list{Attrs.class_("text-xs text-gray-700 mt-1")},
                              list{text("Connect to Aerie backend to configure network probes")},
                            ),
                          },
                        )
                      },
                    },
                  )
                },
              },
            )
          },
          switch aerie.error {
          | Some(e) =>
            div(
              list{
                Attrs.class_(
                  "mt-4 p-3 bg-red-900/30 border border-red-700 rounded text-sm text-red-300",
                ),
                Attrs.role("alert"),
              },
              list{text(e)},
            )
          | None => noNode
          },
        },
      ),
    },
  )
}
