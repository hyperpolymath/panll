// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Device Network Designer Component — wire devices, configure security
/// levels, and validate network topology. Displays device palette, canvas
/// placeholder, wiring mode toggle, and validation results panel.

open Model
open Msg
open Tea.Html

/// Main view function for the Device Network Designer panel.
let view = (state: deviceNetworkDesignerState): Tea_Vdom.t<msg> => {
  let deviceCount = Array.length(state.devices)
  let connectionCount = Array.length(state.connections)

  div(
    list{
      Attrs.class_("flex flex-col h-full bg-gray-950 text-gray-100 overflow-hidden"),
      Attrs.role("region"),
      Attrs.ariaLabel("Device Network Designer — Network Topology Editor"),
    },
    list{
      // Header row
      div(
        list{Attrs.class_("flex items-center justify-between px-4 py-2 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(
                list{Attrs.class_("text-lg font-bold text-blue-300")},
                list{text("Device Network Designer")},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-400")},
                list{
                  text(
                    Int.toString(deviceCount) ++
                    " devices, " ++
                    Int.toString(connectionCount) ++ " connections",
                  ),
                },
              ),
              span(
                list{
                  Attrs.class_(
                    "text-xs px-2 py-0.5 rounded " ++ if state.wiringMode {
                      "bg-blue-700 text-blue-100"
                    } else {
                      "bg-gray-800 text-gray-400"
                    },
                  ),
                },
                list{
                  text(
                    if state.wiringMode {
                      "Wiring ON"
                    } else {
                      "Wiring OFF"
                    },
                  ),
                },
              ),
            },
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 text-xs bg-blue-800 hover:bg-blue-700 text-white rounded"),
              Events.onClick(DeviceNetworkDesigner(DndStarted)),
            },
            list{text("Validate")},
          ),
        },
      ),
      // Tab bar
      div(
        list{Attrs.class_("flex gap-1 px-4 py-2 border-b border-gray-800")},
        list{
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Designer {
                  "bg-blue-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(DeviceNetworkDesigner(SetDndCategory(Designer))),
            },
            list{text("Designer")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Devices {
                  "bg-blue-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(DeviceNetworkDesigner(SetDndCategory(Devices))),
            },
            list{text("Devices")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Wiring {
                  "bg-blue-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(DeviceNetworkDesigner(SetDndCategory(Wiring))),
            },
            list{text("Wiring")},
          ),
          button(
            list{
              Attrs.class_(
                "px-3 py-1 text-xs rounded " ++ if state.activeTab == Validation {
                  "bg-blue-700 text-white"
                } else {
                  "bg-gray-800 text-gray-400 hover:text-gray-200"
                },
              ),
              Events.onClick(DeviceNetworkDesigner(SetDndCategory(Validation))),
            },
            list{text("Validation")},
          ),
        },
      ),
      // Error banner
      switch state.error {
      | Some(err) =>
        div(
          list{
            Attrs.class_(
              "mx-4 mt-2 px-3 py-2 bg-red-900/50 border border-red-700 rounded text-sm text-red-200 flex justify-between items-center",
            ),
          },
          list{
            text(err),
            button(
              list{
                Attrs.class_("text-red-400 hover:text-red-200 text-xs ml-2"),
                Events.onClick(DeviceNetworkDesigner(DismissDndError)),
              },
              list{text("Dismiss")},
            ),
          },
        )
      | None => Tea_Html.noNode
      },
      // Content area
      div(
        list{Attrs.class_("flex-1 overflow-y-auto px-4 py-4")},
        list{
          switch state.activeTab {
          | Designer =>
            div(
              list{Attrs.class_("space-y-3")},
              list{
                // Device palette
                div(
                  list{Attrs.class_("flex gap-2 flex-wrap mb-3")},
                  ["Router", "Server", "Camera", "Firewall", "Switch", "Sensor"]
                  ->Array.map(dt =>
                    span(
                      list{
                        Attrs.class_(
                          "px-3 py-1.5 text-xs bg-gray-800 border border-gray-700 text-gray-300 rounded cursor-pointer hover:border-blue-600",
                        ),
                      },
                      list{text(dt)},
                    )
                  )
                  ->List.fromArray,
                ),
                // Canvas placeholder
                div(
                  list{
                    Attrs.class_(
                      "w-full h-48 bg-gray-900 border border-gray-800 rounded flex items-center justify-center",
                    ),
                  },
                  list{
                    span(
                      list{Attrs.class_("text-gray-600 text-sm")},
                      list{
                        text(
                          "Network graph canvas — " ++
                          Int.toString(deviceCount) ++
                          " nodes, " ++
                          Int.toString(connectionCount) ++ " edges",
                        ),
                      },
                    ),
                  },
                ),
              },
            )
          | Devices =>
            div(
              list{Attrs.class_("space-y-2")},
              state.devices
              ->Array.map(d => {
                let isSelected = state.selectedDevice == Some(d.id)
                div(
                  list{
                    Attrs.class_(
                      "px-3 py-2 border rounded " ++ if isSelected {
                        "bg-blue-900/20 border-blue-700"
                      } else {
                        "bg-gray-900 border-gray-800"
                      },
                    ),
                  },
                  list{
                    div(
                      list{Attrs.class_("flex items-center justify-between")},
                      list{
                        div(
                          list{Attrs.class_("flex items-center gap-2")},
                          list{
                            span(
                              list{Attrs.class_("text-sm font-bold text-blue-300")},
                              list{text(d.deviceType)},
                            ),
                            span(
                              list{Attrs.class_("text-xs text-gray-500 font-mono")},
                              list{text(d.id)},
                            ),
                          },
                        ),
                        span(
                          list{
                            Attrs.class_("px-2 py-0.5 text-xs bg-gray-800 text-gray-300 rounded"),
                          },
                          list{text(d.zone ++ " (L" ++ Int.toString(d.securityLevel) ++ ")")},
                        ),
                      },
                    ),
                    div(
                      list{Attrs.class_("text-xs text-gray-500 mt-1 font-mono")},
                      list{
                        text(
                          "(" ++
                          Float.toFixed(d.x, ~digits=0) ++
                          ", " ++
                          Float.toFixed(d.y, ~digits=0) ++ ")",
                        ),
                      },
                    ),
                  },
                )
              })
              ->List.fromArray,
            )
          | Wiring =>
            div(
              list{Attrs.class_("space-y-1")},
              list{
                // Table header
                div(
                  list{
                    Attrs.class_(
                      "flex gap-2 text-xs text-gray-500 font-mono border-b border-gray-800 pb-1 mb-2",
                    ),
                  },
                  list{
                    span(list{Attrs.class_("w-20")}, list{text("From")}),
                    span(list{Attrs.class_("w-20")}, list{text("To")}),
                    span(list{Attrs.class_("w-16")}, list{text("Protocol")}),
                    span(list{Attrs.class_("w-16")}, list{text("BW")}),
                    span(list{Attrs.class_("w-12")}, list{text("Enc")}),
                  },
                ),
                div(
                  list{Attrs.class_("space-y-1")},
                  state.connections
                  ->Array.map(c => {
                    let isSelected = state.selectedConnection == Some(c.id)
                    div(
                      list{
                        Attrs.class_(
                          "flex gap-2 text-xs py-1 border-b border-gray-800/30 " ++ if isSelected {
                            "bg-blue-900/20"
                          } else {
                            ""
                          },
                        ),
                      },
                      list{
                        span(
                          list{Attrs.class_("w-20 font-mono text-gray-400 truncate")},
                          list{text(c.fromDevice)},
                        ),
                        span(
                          list{Attrs.class_("w-20 font-mono text-gray-400 truncate")},
                          list{text(c.toDevice)},
                        ),
                        span(list{Attrs.class_("w-16 text-blue-400")}, list{text(c.protocol)}),
                        span(list{Attrs.class_("w-16 text-gray-500")}, list{text(c.bandwidth)}),
                        span(
                          list{
                            Attrs.class_(
                              "w-12 " ++ if c.encrypted {
                                "text-green-400"
                              } else {
                                "text-red-400"
                              },
                            ),
                          },
                          list{
                            text(
                              if c.encrypted {
                                "Yes"
                              } else {
                                "No"
                              },
                            ),
                          },
                        ),
                      },
                    )
                  })
                  ->List.fromArray,
                ),
              },
            )
          | Validation =>
            switch state.validation {
            | Some(v) =>
              div(
                list{Attrs.class_("space-y-3")},
                list{
                  // Validation summary
                  div(
                    list{Attrs.class_("flex items-center gap-3 mb-3")},
                    list{
                      span(
                        list{
                          Attrs.class_(
                            "px-3 py-1 text-sm rounded font-bold " ++ if v.valid {
                              "bg-green-700 text-green-100"
                            } else {
                              "bg-red-700 text-red-100"
                            },
                          ),
                        },
                        list{
                          text(
                            if v.valid {
                              "VALID"
                            } else {
                              "INVALID"
                            },
                          ),
                        },
                      ),
                      span(
                        list{Attrs.class_("text-xs text-gray-400")},
                        list{
                          text(
                            Int.toString(v.deviceCount) ++
                            " devices, " ++
                            Int.toString(v.connectionCount) ++ " connections",
                          ),
                        },
                      ),
                    },
                  ),
                  // Errors
                  if Array.length(v.errors) > 0 {
                    div(
                      list{Attrs.class_("space-y-1")},
                      list{
                        h3(list{Attrs.class_("text-sm text-red-400 mb-1")}, list{text("Errors")}),
                        div(
                          list{},
                          v.errors
                          ->Array.map(e =>
                            div(
                              list{
                                Attrs.class_(
                                  "px-2 py-1 text-xs text-red-200 bg-red-900/30 rounded mb-1",
                                ),
                              },
                              list{text(e)},
                            )
                          )
                          ->List.fromArray,
                        ),
                      },
                    )
                  } else {
                    Tea_Html.noNode
                  },
                  // Warnings
                  if Array.length(v.warnings) > 0 {
                    div(
                      list{Attrs.class_("space-y-1")},
                      list{
                        h3(
                          list{Attrs.class_("text-sm text-yellow-400 mb-1")},
                          list{text("Warnings")},
                        ),
                        div(
                          list{},
                          v.warnings
                          ->Array.map(w =>
                            div(
                              list{
                                Attrs.class_(
                                  "px-2 py-1 text-xs text-yellow-200 bg-yellow-900/30 rounded mb-1",
                                ),
                              },
                              list{text(w)},
                            )
                          )
                          ->List.fromArray,
                        ),
                      },
                    )
                  } else {
                    Tea_Html.noNode
                  },
                },
              )
            | None =>
              div(
                list{Attrs.class_("text-center text-gray-500 py-8")},
                list{text("Run validation to check the network topology for errors.")},
              )
            }
          },
        },
      ),
    },
  )
}
