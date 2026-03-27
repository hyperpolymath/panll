// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Interfaces Component — ABI/FFI inventory dashboard.
///
/// Idris2 ABI definitions, Zig FFI implementations, per-language
/// binding coverage matrix, believe_me audit.

open Model
open Msg
open Tea.Html

let renderAbiRow = (def: abiDefinition): Tea_Vdom.t<msg> => {
  let verifiedIcon = def.verified ? "text-green-400" : "text-red-400"
  let verifiedText = def.verified ? "Verified" : "Unverified"
  div(
    list{Attrs.class_("flex items-center gap-4 p-2 border-b border-gray-800"), Attrs.role("row")},
    list{
      span(list{Attrs.class_(`text-xs ${verifiedIcon} w-16`)}, list{text(verifiedText)}),
      span(list{Attrs.class_("text-sm text-gray-300 w-32")}, list{text(def.moduleName)}),
      span(list{Attrs.class_("text-xs text-gray-500 flex-1 truncate")}, list{text(def.path)}),
      span(
        list{Attrs.class_("text-xs text-gray-400 w-20 text-right")},
        list{text(`${Int.toString(def.exportCount)} exports`)},
      ),
      if def.believeMeCount > 0 {
        span(
          list{Attrs.class_("text-xs text-red-400 w-24 text-right font-bold")},
          list{text(`${Int.toString(def.believeMeCount)} believe_me`)},
        )
      } else {
        span(
          list{Attrs.class_("text-xs text-green-400 w-24 text-right")},
          list{text("0 believe_me")},
        )
      },
    },
  )
}

let renderBindingRow = (binding: bindingCoverage): Tea_Vdom.t<msg> => {
  let covColor = if binding.coverage > 80.0 {
    "bg-green-500"
  } else if binding.coverage > 40.0 {
    "bg-amber-500"
  } else {
    "bg-red-500"
  }
  div(
    list{Attrs.class_("flex items-center gap-3 mb-2")},
    list{
      div(
        list{Attrs.class_("w-24 text-sm text-gray-300 text-right")},
        list{text(binding.language)},
      ),
      div(
        list{Attrs.class_("flex-1 bg-gray-800 rounded-full h-3")},
        list{
          div(
            list{
              Attrs.class_(`${covColor} h-full rounded-full transition-all`),
              Attrs.prop("style", `width: ${Float.toFixed(binding.coverage, ~digits=0)}%`),
            },
            list{},
          ),
        },
      ),
      div(
        list{Attrs.class_("w-20 text-xs text-gray-400 text-right")},
        list{text(`${Int.toString(binding.boundCount)}/${Int.toString(binding.totalCount)}`)},
      ),
      div(
        list{Attrs.class_("w-14 text-xs text-gray-500")},
        list{text(`${Float.toFixed(binding.coverage, ~digits=0)}%`)},
      ),
    },
  )
}

let renderTabs = (active: interfacesCategory): Tea_Vdom.t<msg> => {
  let tabs: array<interfacesCategory> = [IfaceDashboard, IfaceAbi, IfaceFfi, IfaceBindings]
  div(
    list{Attrs.class_("flex gap-1 border-b border-gray-800 mb-4"), Attrs.role("tablist")},
    tabs
    ->Array.map(tab => {
      let isActive = tab === active
      button(
        list{
          Attrs.class_(
            `px-4 py-2 text-sm rounded-t transition-colors ${isActive
                ? "bg-gray-800 text-gray-200 border-b-2 border-orange-500"
                : "text-gray-500 hover:text-gray-300"}`,
          ),
          Attrs.role("tab"),
          Attrs.ariaSelected(isActive),
          Events.onClick(Interfaces(SetIfaceCategory(tab))),
        },
        list{text(InterfacesEngine.categoryLabel(tab))},
      )
    })
    ->List.fromArray,
  )
}

let view = (iface: interfacesState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Interfaces ABI/FFI panel"),
    },
    list{
      div(
        list{Attrs.class_("flex items-center justify-between p-4 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(list{Attrs.class_("text-lg font-medium text-gray-200")}, list{text("Interfaces")}),
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text("Idris2 ABI + Zig FFI inventory")},
              ),
              if iface.totalBelieveMe > 0 {
                span(
                  list{Attrs.class_("text-xs text-red-400 ml-2 font-bold")},
                  list{text(`${Int.toString(iface.totalBelieveMe)} believe_me VIOLATIONS`)},
                )
              } else {
                span(list{Attrs.class_("text-xs text-green-400 ml-2")}, list{text("0 believe_me")})
              },
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              button(
                list{
                  Attrs.class_(
                    "px-3 py-1 text-xs bg-orange-600 text-white rounded hover:bg-orange-500",
                  ),
                  Events.onClick(Interfaces(ScanInterfaces)),
                },
                list{text("Scan")},
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
          if !iface.loaded {
            div(
              list{Attrs.class_("text-center text-gray-500 mt-12")},
              list{
                div(list{Attrs.class_("text-4xl mb-2")}, list{text("Interfaces")}),
                div(
                  list{Attrs.class_("text-sm mb-6")},
                  list{
                    text("ABI definitions (Idris2) + FFI implementations (Zig) + binding coverage"),
                  },
                ),
                button(
                  list{
                    Attrs.class_("px-4 py-2 bg-orange-600 text-white rounded hover:bg-orange-500"),
                    Events.onClick(Interfaces(ScanInterfaces)),
                  },
                  list{text("Scan ABI/FFI")},
                ),
              },
            )
          } else {
            div(
              list{Attrs.class_("space-y-4")},
              list{
                renderTabs(iface.activeCategory),
                switch iface.activeCategory {
                | IfaceDashboard =>
                  div(
                    list{Attrs.class_("space-y-6")},
                    list{
                      div(
                        list{Attrs.class_("flex gap-6 text-sm")},
                        list{
                          div(
                            list{Attrs.class_("text-gray-400")},
                            list{text(`${Int.toString(Array.length(iface.abiDefs))} ABI modules`)},
                          ),
                          div(
                            list{Attrs.class_("text-gray-400")},
                            list{
                              text(
                                `${Int.toString(
                                    InterfacesEngine.totalAbiExports(iface.abiDefs),
                                  )} exports`,
                              ),
                            },
                          ),
                          div(
                            list{Attrs.class_("text-gray-400")},
                            list{
                              text(
                                `${Float.toFixed(
                                    InterfacesEngine.verificationRate(iface.abiDefs) *. 100.0,
                                    ~digits=0,
                                  )}% verified`,
                              ),
                            },
                          ),
                          div(
                            list{Attrs.class_("text-gray-400")},
                            list{
                              text(
                                `${Float.toFixed(
                                    InterfacesEngine.avgCoverage(iface.bindings),
                                    ~digits=0,
                                  )}% avg binding coverage`,
                              ),
                            },
                          ),
                        },
                      ),
                      div(
                        list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-4")},
                        list{
                          div(
                            list{Attrs.class_("text-sm font-medium text-gray-300 mb-3")},
                            list{text("Binding Coverage by Language")},
                          ),
                          div(
                            list{},
                            iface.bindings->Array.map(b => renderBindingRow(b))->List.fromArray,
                          ),
                        },
                      ),
                    },
                  )
                | IfaceAbi =>
                  div(
                    list{Attrs.class_("border border-gray-700 rounded-lg overflow-hidden")},
                    list{
                      div(
                        list{Attrs.class_("max-h-96 overflow-y-auto")},
                        iface.abiDefs->Array.map(d => renderAbiRow(d))->List.fromArray,
                      ),
                    },
                  )
                | IfaceFfi =>
                  div(
                    list{Attrs.class_("text-gray-500 text-sm")},
                    list{
                      text(`${Int.toString(Array.length(iface.ffiImpls))} Zig FFI implementations`),
                    },
                  )
                | IfaceBindings =>
                  div(
                    list{Attrs.class_("bg-gray-900 border border-gray-700 rounded-lg p-4")},
                    list{
                      div(
                        list{},
                        iface.bindings->Array.map(b => renderBindingRow(b))->List.fromArray,
                      ),
                    },
                  )
                },
              },
            )
          },
        },
      ),
    },
  )
}
