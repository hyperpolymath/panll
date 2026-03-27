// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Network Topology Component — view for the IDApTIK in-game
/// network topology viewer. Force-directed graph of devices, zones,
/// security levels, packet flow, and DNS resolution.

open Model
open Msg
open Tea.Html

/// Render a category tab button.
let renderTab = (
  label: string,
  cat: networkTopologyCategory,
  active: networkTopologyCategory,
): Tea_Vdom.t<msg> => {
  let isActive = cat === active
  let cls = isActive
    ? "px-3 py-1.5 text-xs font-medium bg-gray-700 text-white rounded"
    : "px-3 py-1.5 text-xs text-gray-400 hover:text-gray-200 hover:bg-gray-800 rounded cursor-pointer"
  button(
    list{Attrs.class_(cls), Events.onClick(NetworkTopology(SetTopologyCategory(cat)))},
    list{text(label)},
  )
}

/// Render a single device card in the graph view.
let renderDeviceCard = (device: networkDevice, isSelected: bool): Tea_Vdom.t<msg> => {
  let borderCls = if device.compromised {
    "border-red-500"
  } else if isSelected {
    "border-cyan-400"
  } else {
    "border-gray-600"
  }
  let zoneCls = NetworkTopologyEngine.zoneColour(device.zone)
  div(
    list{
      Attrs.class_(
        `p-3 bg-gray-800 rounded border ${borderCls} cursor-pointer hover:border-gray-400`,
      ),
      Events.onClick(NetworkTopology(SelectDevice(device.id))),
    },
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-1")},
        list{
          span(list{Attrs.class_("text-sm font-medium text-gray-100")}, list{text(device.name)}),
          span(
            list{Attrs.class_(`text-xs ${zoneCls}`)},
            list{text(NetworkTopologyEngine.zoneLabel(device.zone))},
          ),
        },
      ),
      div(
        list{Attrs.class_("flex items-center gap-2 text-xs text-gray-400")},
        list{
          span(list{}, list{text(device.deviceType)}),
          span(list{}, list{text(`Sec: ${Int.toString(device.securityLevel)}`)}),
          if device.compromised {
            span(list{Attrs.class_("text-red-400 font-bold")}, list{text("COMPROMISED")})
          } else if device.active {
            span(list{Attrs.class_("text-emerald-400")}, list{text("Active")})
          } else {
            span(list{Attrs.class_("text-gray-500")}, list{text("Inactive")})
          },
        },
      ),
      if Array.length(device.defenceFlags) > 0 {
        div(
          list{Attrs.class_("flex flex-wrap gap-1 mt-1")},
          device.defenceFlags
          ->Array.map(flag =>
            span(
              list{
                Attrs.class_("px-1.5 py-0.5 text-xs bg-emerald-900/50 text-emerald-300 rounded"),
              },
              list{text(flag)},
            )
          )
          ->List.fromArray,
        )
      } else {
        noNode
      },
    },
  )
}

/// Render the zones summary view.
let renderZones = (state: networkTopologyState): Tea_Vdom.t<msg> => {
  let zones: array<networkZone> = [ZonePublic, ZoneDmz, ZoneInternal, ZoneRestricted, ZoneAirGapped]
  div(
    list{Attrs.class_("space-y-3")},
    zones
    ->Array.map(zone => {
      let devices = NetworkTopologyEngine.devicesByZone(state.devices, zone)
      let bgCls = NetworkTopologyEngine.zoneBgColour(zone)
      let colourCls = NetworkTopologyEngine.zoneColour(zone)
      div(
        list{Attrs.class_(`p-3 rounded ${bgCls}`)},
        list{
          div(
            list{Attrs.class_("flex items-center justify-between mb-2")},
            list{
              span(
                list{Attrs.class_(`text-sm font-medium ${colourCls}`)},
                list{text(NetworkTopologyEngine.zoneLabel(zone))},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-400")},
                list{text(`${Int.toString(Array.length(devices))} devices`)},
              ),
            },
          ),
          if Array.length(devices) === 0 {
            div(
              list{Attrs.class_("text-xs text-gray-500 italic")},
              list{text("No devices in this zone")},
            )
          } else {
            div(
              list{Attrs.class_("space-y-1")},
              devices
              ->Array.map(d =>
                div(
                  list{
                    Attrs.class_(
                      "flex items-center gap-2 text-xs text-gray-300 cursor-pointer hover:text-white",
                    ),
                  },
                  list{
                    span(list{}, list{text(d.name)}),
                    span(list{Attrs.class_("text-gray-500")}, list{text(d.deviceType)}),
                  },
                )
              )
              ->List.fromArray,
            )
          },
        },
      )
    })
    ->List.fromArray,
  )
}

/// Render DNS entries table.
let renderDns = (state: networkTopologyState): Tea_Vdom.t<msg> => {
  if Array.length(state.dnsEntries) === 0 {
    div(
      list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
      list{text("No DNS entries — connect to a running game to see DNS resolution")},
    )
  } else {
    div(
      list{Attrs.class_("space-y-1")},
      state.dnsEntries
      ->Array.map(entry =>
        div(
          list{Attrs.class_("flex items-center gap-3 p-2 bg-gray-800 rounded text-xs")},
          list{
            span(
              list{Attrs.class_("text-cyan-400 font-mono w-40 truncate")},
              list{text(entry.hostname)},
            ),
            span(list{Attrs.class_("text-gray-500")}, list{text(entry.recordType)}),
            span(list{Attrs.class_("text-gray-300 font-mono")}, list{text(entry.resolvedIp)}),
            span(
              list{Attrs.class_("text-gray-500")},
              list{text(`TTL: ${Int.toString(entry.ttl)}`)},
            ),
          },
        )
      )
      ->List.fromArray,
    )
  }
}

/// Render packet flow animation view.
let renderPacketFlow = (state: networkTopologyState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-3")},
    list{
      // Controls
      div(
        list{Attrs.class_("flex items-center gap-3")},
        list{
          button(
            list{
              Attrs.class_(
                if state.animatePackets {
                  "px-3 py-1.5 text-xs bg-emerald-700 text-white rounded"
                } else {
                  "px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer"
                },
              ),
              Events.onClick(NetworkTopology(TogglePacketAnimation)),
            },
            list{
              text(
                if state.animatePackets {
                  "Animating..."
                } else {
                  "Start Animation"
                },
              ),
            },
          ),
          span(
            list{Attrs.class_("text-xs text-gray-400")},
            list{text(`${Int.toString(Array.length(state.packetFlow))} events`)},
          ),
        },
      ),
      // Recent packet events
      if Array.length(state.packetFlow) === 0 {
        div(
          list{Attrs.class_("text-center text-gray-500 text-sm py-8")},
          list{text("No packet flow events captured")},
        )
      } else {
        div(
          list{Attrs.class_("space-y-1 max-h-96 overflow-y-auto")},
          state.packetFlow
          ->Array.map(evt =>
            div(
              list{
                Attrs.class_(
                  `flex items-center gap-3 p-2 rounded text-xs ${if evt.blocked {
                      "bg-red-900/30"
                    } else {
                      "bg-gray-800"
                    }}`,
                ),
              },
              list{
                span(
                  list{Attrs.class_("text-gray-400 font-mono")},
                  list{text(Float.toString(evt.timestamp))},
                ),
                span(list{Attrs.class_("text-gray-300")}, list{text(evt.connectionId)}),
                span(list{Attrs.class_("text-gray-500")}, list{text(`${Int.toString(evt.size)}B`)}),
                if evt.blocked {
                  span(list{Attrs.class_("text-red-400 font-bold")}, list{text("BLOCKED")})
                } else {
                  span(list{Attrs.class_("text-emerald-400")}, list{text("OK")})
                },
              },
            )
          )
          ->List.fromArray,
        )
      },
    },
  )
}

/// Main view function.
let view = (state: networkTopologyState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Network Topology panel"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-3 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              span(
                list{Attrs.class_("text-lg font-semibold text-gray-100")},
                list{text("Network Topology")},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text(`${Int.toString(Array.length(state.devices))} devices`)},
              ),
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              // Toggle labels
              button(
                list{
                  Attrs.class_(
                    if state.showLabels {
                      "px-2 py-1 text-xs bg-cyan-800 text-cyan-200 rounded"
                    } else {
                      "px-2 py-1 text-xs bg-gray-700 text-gray-400 rounded cursor-pointer"
                    },
                  ),
                  Events.onClick(NetworkTopology(ToggleLabels)),
                },
                list{text("Labels")},
              ),
              // Toggle security levels
              button(
                list{
                  Attrs.class_(
                    if state.showSecurityLevels {
                      "px-2 py-1 text-xs bg-amber-800 text-amber-200 rounded"
                    } else {
                      "px-2 py-1 text-xs bg-gray-700 text-gray-400 rounded cursor-pointer"
                    },
                  ),
                  Events.onClick(NetworkTopology(ToggleSecurityLevels)),
                },
                list{text("Security")},
              ),
              // Refresh
              button(
                list{
                  Attrs.class_(
                    "px-2 py-1 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 cursor-pointer",
                  ),
                  Events.onClick(NetworkTopology(RefreshTopology)),
                },
                list{text("Refresh")},
              ),
            },
          ),
        },
      ),
      // Category tabs
      div(
        list{Attrs.class_("flex items-center gap-1 px-4 py-2 border-b border-gray-800")},
        list{
          renderTab("Graph", TopologyGraph, state.activeCategory),
          renderTab("Zones", TopologyZones, state.activeCategory),
          renderTab("DNS", TopologyDns, state.activeCategory),
          renderTab("Packet Flow", TopologyPacketFlow, state.activeCategory),
        },
      ),
      // Error banner
      switch state.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_(
              "mx-4 mt-2 p-2 bg-red-900/50 border border-red-700 rounded text-xs text-red-300",
            ),
          },
          list{
            div(
              list{Attrs.class_("flex items-center justify-between")},
              list{
                text(err),
                button(
                  list{
                    Attrs.class_("text-red-400 hover:text-red-200 cursor-pointer"),
                    Events.onClick(NetworkTopology(DismissTopoError)),
                  },
                  list{text("Dismiss")},
                ),
              },
            ),
          },
        )
      | None => noNode
      },
      // Loading indicator
      if state.loading {
        div(
          list{Attrs.class_("px-4 py-2 text-xs text-cyan-400 animate-pulse")},
          list{text("Loading topology...")},
        )
      } else {
        noNode
      },
      // Main content
      div(
        list{Attrs.class_("flex-1 overflow-auto p-4")},
        list{
          switch state.activeCategory {
          | TopologyGraph =>
            if Array.length(state.devices) === 0 {
              div(
                list{Attrs.class_("text-center text-gray-500 text-sm py-16")},
                list{
                  div(list{Attrs.class_("text-4xl mb-4")}, list{text("~")}),
                  div(list{}, list{text("No network topology loaded")}),
                  div(
                    list{Attrs.class_("mt-2 text-xs")},
                    list{text("Connect to a running IDApTIK game to see the network graph")},
                  ),
                },
              )
            } else {
              div(
                list{Attrs.class_("grid grid-cols-2 lg:grid-cols-3 gap-3")},
                state.devices
                ->Array.map(device => {
                  let isSelected = state.selectedDeviceId === Some(device.id)
                  renderDeviceCard(device, isSelected)
                })
                ->List.fromArray,
              )
            }
          | TopologyZones => renderZones(state)
          | TopologyDns => renderDns(state)
          | TopologyPacketFlow => renderPacketFlow(state)
          },
        },
      ),
    },
  )
}
