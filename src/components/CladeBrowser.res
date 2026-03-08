// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Clade Browser — panel component for exploring and customising panel clades.
///
/// Renders four tabs: Overview (stats grid + clade list), By Kind (grouped view),
/// Traits (trait matrix), Panel Map (which panels belong to which clades).
/// Uses Tailwind CSS classes (same as all other PanLL panels).

open Msg
open CladeBrowserModel
open CladeBrowserEngine
open Tea.Html

/// Render a tab button.
let renderTab = (label: string, active: bool, cat: cladeBrowserCategory): Tea_Vdom.t<msg> => {
  let baseClass = "px-3 py-1.5 text-xs rounded-t border-b-2 transition-colors cursor-pointer"
  let cls = active
    ? `${baseClass} text-cyan-300 border-cyan-400 bg-gray-800`
    : `${baseClass} text-gray-500 border-transparent hover:text-gray-300`
  button(
    list{
      Attrs.class_(cls),
      Events.onClick(CladeBrowser(SetCladeCategory(cat))),
      Attrs.role("tab"),
      Attrs.ariaSelected(active),
    },
    list{text(label)},
  )
}

/// Render a trait badge (green if active, gray if not).
let traitBadge = (label: string, active: bool): Tea_Vdom.t<msg> => {
  let cls = active
    ? "inline-block px-2 py-0.5 text-xs rounded border border-green-500/30 bg-green-500/10 text-green-400"
    : "inline-block px-2 py-0.5 text-xs rounded border border-gray-600/30 bg-gray-700/20 text-gray-500"
  span(list{Attrs.class_(cls)}, list{text(label)})
}

/// Render trait badges for a clade entry.
let traitBadges = (traits: cladeTraits): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex flex-wrap gap-1 mt-1")},
    list{
      traitBadge("Persistence", traits.hasPersistence),
      traitBadge("Backend", traits.hasBackend),
      traitBadge("Work Items", traits.hasWorkItems),
      traitBadge("Real-Time", traits.hasRealTime),
      traitBadge("Ambient", traits.isAmbient),
    },
  )
}

/// Render a kind badge with colour-coded background.
let kindBadge = (kind: string): Tea_Vdom.t<msg> => {
  let cls = switch kind {
  | "ai" => "bg-violet-500/20 text-violet-400 border-violet-500/30"
  | "bridge" => "bg-blue-500/20 text-blue-400 border-blue-500/30"
  | "builder" => "bg-amber-500/20 text-amber-400 border-amber-500/30"
  | "database" => "bg-emerald-500/20 text-emerald-400 border-emerald-500/30"
  | "directive" => "bg-red-500/20 text-red-400 border-red-500/30"
  | "loader" => "bg-indigo-500/20 text-indigo-400 border-indigo-500/30"
  | "meta" => "bg-gray-500/20 text-gray-400 border-gray-500/30"
  | "network" => "bg-teal-500/20 text-teal-400 border-teal-500/30"
  | "scanner" => "bg-orange-500/20 text-orange-400 border-orange-500/30"
  | "terminal" => "bg-lime-500/20 text-lime-400 border-lime-500/30"
  | "viewer" => "bg-purple-500/20 text-purple-400 border-purple-500/30"
  | _ => "bg-gray-500/20 text-gray-400 border-gray-500/30"
  }
  span(
    list{Attrs.class_(`inline-block px-2 py-0.5 text-xs rounded-full border ${cls}`)},
    list{text(kind)},
  )
}

/// Render a stat card for the overview grid.
let statCard = (value: string, label: string, colour: string): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("bg-gray-800 rounded-lg p-4 text-center")},
    list{
      div(list{Attrs.class_(`text-2xl font-bold ${colour}`)}, list{text(value)}),
      div(list{Attrs.class_("text-xs text-gray-400 mt-1")}, list{text(label)}),
    },
  )
}

/// Render a protocol badge.
let protocolBadge = (proto: cladeProtocol): Tea_Vdom.t<msg> => {
  span(
    list{Attrs.class_("inline-block px-1.5 py-0.5 text-xs rounded border border-sky-500/30 bg-sky-500/10 text-sky-400")},
    list{text(protocolLabel(proto))},
  )
}

/// Render a capability badge.
let capBadge = (cap: cladeCapability): Tea_Vdom.t<msg> => {
  span(
    list{Attrs.class_("inline-block px-1.5 py-0.5 text-xs rounded border border-amber-500/30 bg-amber-500/10 text-amber-400")},
    list{text(capabilityLabel(cap))},
  )
}

/// Render an isolation level badge with colour coding.
let isolationBadgeView = (iso: cladeIsolation): Tea_Vdom.t<msg> => {
  let (cls, label) = switch iso {
  | IsolationNone => ("border-red-500/30 bg-red-500/10 text-red-400", "None")
  | IsolationSoft => ("border-yellow-500/30 bg-yellow-500/10 text-yellow-400", "Soft")
  | IsolationProcess => ("border-blue-500/30 bg-blue-500/10 text-blue-400", "Process")
  | IsolationContainer => ("border-emerald-500/30 bg-emerald-500/10 text-emerald-400", "Container")
  }
  span(
    list{Attrs.class_(`inline-block px-1.5 py-0.5 text-xs rounded border ${cls}`)},
    list{text(label)},
  )
}

/// Render a single clade card.
let cladeCard = (entry: cladeEntry, isSelected: bool): Tea_Vdom.t<msg> => {
  let borderCls = isSelected ? "border-cyan-500 bg-gray-800/80" : "border-gray-700 bg-gray-800/40"
  div(
    list{
      Attrs.class_(`p-3 mb-2 rounded-lg border ${borderCls} cursor-pointer hover:border-gray-500 transition-colors`),
      Events.onClick(CladeBrowser(SelectClade(Some(entry.id)))),
    },
    list{
      // Header row: name + kind badge + version + isolation
      div(
        list{Attrs.class_("flex justify-between items-center mb-1")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              strong(list{Attrs.class_("text-sm text-gray-100")}, list{text(entry.name)}),
              kindBadge(entry.kind),
              isolationBadgeView(entry.isolation),
              span(list{Attrs.class_("text-xs text-gray-600")}, list{text("v" ++ entry.version)}),
            },
          ),
          span(list{Attrs.class_("text-xs text-gray-500 font-mono")}, list{text(entry.id)}),
        },
      ),
      // Summary
      p(list{Attrs.class_("text-xs text-gray-300 my-1")}, list{text(entry.summary)}),
      // Traits
      traitBadges(entry.traits),
      // Protocols (Tier 1.1)
      if entry.protocols->Array.length > 0 {
        div(
          list{Attrs.class_("flex flex-wrap gap-1 mt-1")},
          entry.protocols->Array.map(protocolBadge)->List.fromArray,
        )
      } else {
        noNode
      },
      // Capabilities (Tier 1.2)
      if entry.capabilities->Array.length > 0 {
        div(
          list{Attrs.class_("flex flex-wrap gap-1 mt-1")},
          entry.capabilities->Array.map(capBadge)->List.fromArray,
        )
      } else {
        noNode
      },
      // Dependencies (Tier 1.3)
      if entry.requires->Array.length > 0 {
        div(
          list{Attrs.class_("mt-1 text-xs text-red-400")},
          list{text("requires: " ++ entry.requires->Array.map(d => d.cladeId)->Array.join(", "))},
        )
      } else {
        noNode
      },
      // Enhances (Tier 1.3)
      if entry.enhances->Array.length > 0 {
        div(
          list{Attrs.class_("mt-1 text-xs text-indigo-400")},
          list{text("enhances: " ++ entry.enhances->Array.join(", "))},
        )
      } else {
        noNode
      },
      // Panel IDs
      if entry.panelIds->Array.length > 0 {
        div(
          list{Attrs.class_("mt-1 text-xs text-gray-500")},
          list{text("Panels: " ++ entry.panelIds->Array.join(", "))},
        )
      } else {
        noNode
      },
    },
  )
}

/// Overview tab — stats grid + full clade list.
let viewOverview = (state: cladeBrowserState): Tea_Vdom.t<msg> => {
  let filtered = filterClades(state.clades, state.kindFilter, state.searchQuery)
  let total = state.clades->Array.length

  div(
    list{},
    list{
      // Stats grid (row 1: counts, row 2: Tier 1 metrics)
      div(
        list{Attrs.class_("grid grid-cols-4 gap-3 mb-3")},
        list{
          statCard(Int.toString(total), "Total Clades", "text-cyan-400"),
          statCard(Int.toString(countWithTrait(state.clades, t => t.hasBackend)), "With Backend", "text-green-400"),
          statCard(Int.toString(countWithTrait(state.clades, t => t.hasRealTime)), "Real-Time", "text-amber-400"),
          statCard(Int.toString(countWithTrait(state.clades, t => t.isAmbient)), "Ambient", "text-violet-400"),
        },
      ),
      div(
        list{Attrs.class_("grid grid-cols-4 gap-3 mb-5")},
        list{
          statCard(Int.toString(countWithProtocols(state.clades)), "With Protocols", "text-sky-400"),
          statCard(Int.toString(countWithCapabilities(state.clades)), "With Capabilities", "text-amber-400"),
          statCard(Int.toString(countByIsolation(state.clades, IsolationProcess) + countByIsolation(state.clades, IsolationContainer)), "Process/Container", "text-blue-400"),
          statCard(Int.toString(countWithParent(state.clades)), "With Inheritance", "text-indigo-400"),
        },
      ),
      // Kind distribution
      div(
        list{Attrs.class_("flex flex-wrap gap-3 mb-4 text-xs")},
        allKinds
        ->Array.filter(k => k !== KindAll)
        ->Array.map(k => {
          let count = countByKind(state.clades, k)
          div(
            list{Attrs.class_("flex items-center gap-1")},
            list{
              span(list{Attrs.class_("w-2 h-2 rounded-full bg-current")}, list{}),
              text(kindLabel(k) ++ " (" ++ Int.toString(count) ++ ")"),
            },
          )
        })->List.fromArray,
      ),
      // Clade list
      div(
        list{},
        filtered->Array.map(entry =>
          cladeCard(entry, state.selectedClade === Some(entry.id))
        )->List.fromArray,
      ),
    },
  )
}

/// By Kind tab — clades grouped by their kind.
let viewByKind = (state: cladeBrowserState): Tea_Vdom.t<msg> => {
  let kinds = allKinds->Array.filter(k => k !== KindAll)
  div(
    list{},
    kinds->Array.map(kind => {
      let kindsClades = filterByKind(state.clades, kind)
      if kindsClades->Array.length > 0 {
        div(
          list{Attrs.class_("mb-5")},
          list{
            div(
              list{Attrs.class_("flex items-center gap-2 mb-2")},
              list{
                kindBadge(kindLabel(kind)->String.toLowerCase),
                h3(list{Attrs.class_("text-sm font-semibold text-gray-200 m-0")}, list{
                  text(kindLabel(kind) ++ " (" ++ Int.toString(kindsClades->Array.length) ++ ")"),
                }),
              },
            ),
            div(
              list{},
              kindsClades->Array.map(entry =>
                cladeCard(entry, state.selectedClade === Some(entry.id))
              )->List.fromArray,
            ),
          },
        )
      } else {
        noNode
      }
    })->List.fromArray,
  )
}

/// Traits tab — matrix of all clades vs traits.
let viewTraits = (state: cladeBrowserState): Tea_Vdom.t<msg> => {
  let check = (v: bool): Tea_Vdom.t<msg> =>
    if v {
      span(list{Attrs.class_("text-green-400")}, list{text("Yes")})
    } else {
      span(list{Attrs.class_("text-gray-600")}, list{text("-")})
    }

  table(
    list{Attrs.class_("w-full text-xs")},
    list{
      thead(
        list{},
        list{
          tr(
            list{Attrs.class_("border-b border-gray-700")},
            list{
              th(list{Attrs.class_("text-left p-2 text-gray-400")}, list{text("Clade")}),
              th(list{Attrs.class_("text-left p-2 text-gray-400")}, list{text("Kind")}),
              th(list{Attrs.class_("text-left p-2 text-gray-400")}, list{text("Persist")}),
              th(list{Attrs.class_("text-left p-2 text-gray-400")}, list{text("Backend")}),
              th(list{Attrs.class_("text-left p-2 text-gray-400")}, list{text("Work Items")}),
              th(list{Attrs.class_("text-left p-2 text-gray-400")}, list{text("Real-Time")}),
              th(list{Attrs.class_("text-left p-2 text-gray-400")}, list{text("Ambient")}),
              th(list{Attrs.class_("text-left p-2 text-gray-400")}, list{text("Isolation")}),
              th(list{Attrs.class_("text-left p-2 text-gray-400")}, list{text("Protocols")}),
              th(list{Attrs.class_("text-left p-2 text-gray-400")}, list{text("Capabilities")}),
            },
          ),
        },
      ),
      tbody(
        list{},
        state.clades->Array.map(entry =>
          tr(
            list{Attrs.class_("border-b border-gray-800 hover:bg-gray-800/50")},
            list{
              td(list{Attrs.class_("p-2 font-medium text-gray-200")}, list{text(entry.name)}),
              td(list{Attrs.class_("p-2")}, list{kindBadge(entry.kind)}),
              td(list{Attrs.class_("p-2")}, list{check(entry.traits.hasPersistence)}),
              td(list{Attrs.class_("p-2")}, list{check(entry.traits.hasBackend)}),
              td(list{Attrs.class_("p-2")}, list{check(entry.traits.hasWorkItems)}),
              td(list{Attrs.class_("p-2")}, list{check(entry.traits.hasRealTime)}),
              td(list{Attrs.class_("p-2")}, list{check(entry.traits.isAmbient)}),
              td(list{Attrs.class_("p-2")}, list{isolationBadgeView(entry.isolation)}),
              td(
                list{Attrs.class_("p-2")},
                list{span(list{Attrs.class_("text-sky-400")}, list{text(Int.toString(entry.protocols->Array.length))})},
              ),
              td(
                list{Attrs.class_("p-2")},
                list{span(list{Attrs.class_("text-amber-400")}, list{text(Int.toString(entry.capabilities->Array.length))})},
              ),
            },
          )
        )->List.fromArray,
      ),
    },
  )
}

/// Panel Map tab — which panels belong to which clades, with inheritance chains.
let viewPanelMap = (state: cladeBrowserState): Tea_Vdom.t<msg> => {
  let withParent = countWithParent(state.clades)
  let roots = rootClades(state.clades)->Array.length
  div(
    list{},
    list{
      p(
        list{Attrs.class_("text-xs text-gray-400 mb-2")},
        list{text("Panel-to-clade assignments. Each panel inherits traits from its clade and ancestors.")},
      ),
      // Inheritance stats
      div(
        list{Attrs.class_("flex gap-4 text-xs text-gray-500 mb-4")},
        list{
          span(list{}, list{text(`${Int.toString(roots)} root clades`)}),
          span(list{}, list{text(`${Int.toString(withParent)} with inheritance`)}),
        },
      ),
      div(
        list{},
        state.clades
        ->Array.filter(c => c.panelIds->Array.length > 0)
        ->Array.map(entry => {
          let chain = inheritanceLabel(state.clades, entry.id)
          let effectiveTraits = resolveTraits(state.clades, entry.id)
          div(
            list{Attrs.class_("py-2 border-b border-gray-800")},
            list{
              div(
                list{Attrs.class_("flex items-baseline gap-3")},
                list{
                  div(
                    list{Attrs.class_("min-w-[180px] flex items-center gap-2")},
                    list{
                      strong(list{Attrs.class_("text-sm text-gray-200")}, list{text(entry.name)}),
                      kindBadge(entry.kind),
                    },
                  ),
                  div(
                    list{Attrs.class_("flex flex-wrap gap-1")},
                    entry.panelIds->Array.map(pid =>
                      span(
                        list{Attrs.class_("bg-gray-700 px-2 py-0.5 rounded text-xs text-gray-200")},
                        list{text(pid)},
                      )
                    )->List.fromArray,
                  ),
                },
              ),
              // Inheritance chain
              if chain != entry.id {
                div(
                  list{Attrs.class_("mt-1 ml-[180px] flex items-center gap-2")},
                  list{
                    span(list{Attrs.class_("text-xs text-indigo-400")}, list{text(chain)}),
                  },
                )
              } else {
                noNode
              },
              // Effective traits (from inheritance)
              switch effectiveTraits {
              | Some(traits) =>
                div(
                  list{Attrs.class_("mt-1 ml-[180px] flex gap-2 text-xs")},
                  list{
                    if traits.hasPersistence {
                      span(list{Attrs.class_("text-green-500")}, list{text("persist")})
                    } else {
                      noNode
                    },
                    if traits.hasBackend {
                      span(list{Attrs.class_("text-blue-500")}, list{text("backend")})
                    } else {
                      noNode
                    },
                    if traits.hasWorkItems {
                      span(list{Attrs.class_("text-amber-500")}, list{text("work")})
                    } else {
                      noNode
                    },
                    if traits.hasRealTime {
                      span(list{Attrs.class_("text-cyan-500")}, list{text("realtime")})
                    } else {
                      noNode
                    },
                    if traits.isAmbient {
                      span(list{Attrs.class_("text-purple-500")}, list{text("ambient")})
                    } else {
                      noNode
                    },
                  },
                )
              | None => noNode
              },
              // Sibling clades
              if entry.siblingClades->Array.length > 0 {
                div(
                  list{Attrs.class_("mt-1 ml-[180px] text-xs text-gray-600")},
                  list{text("siblings: " ++ entry.siblingClades->Array.join(", "))},
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

/// Render the permission rules for a clade.
let permissionBadge = (rules: array<cladePermissionRule>, cladeId: string): Tea_Vdom.t<msg> => {
  let rule = CladeBrowserEngine.findPermissionRule(rules, cladeId)
  switch rule {
  | None =>
    span(
      list{Attrs.class_("text-xs text-emerald-500 cursor-pointer"),
        Events.onClick(CladeBrowser(SetCladePermission(cladeId, PermitNone)))},
      list{text("open")},
    )
  | Some({permission: PermitAll}) =>
    span(
      list{Attrs.class_("text-xs text-emerald-500 cursor-pointer"),
        Events.onClick(CladeBrowser(SetCladePermission(cladeId, PermitNone)))},
      list{text("open")},
    )
  | Some({permission: PermitNone}) =>
    span(
      list{Attrs.class_("text-xs text-red-400 cursor-pointer"),
        Events.onClick(CladeBrowser(RemoveCladePermission(cladeId)))},
      list{text("locked")},
    )
  | Some({permission: PermitOnly(allowed)}) =>
    span(
      list{Attrs.class_("text-xs text-amber-400 cursor-pointer"),
        Events.onClick(CladeBrowser(RemoveCladePermission(cladeId)))},
      list{text(`restricted (${Int.toString(Array.length(allowed))})`)},
    )
  }
}

/// Render the permission rules section.
let viewPermissions = (state: cladeBrowserState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("mt-4 pt-4 border-t border-gray-700")},
    list{
      div(
        list{Attrs.class_("flex items-center justify-between mb-2")},
        list{
          h3(list{Attrs.class_("text-sm font-semibold text-gray-200 m-0")}, list{text("Cross-Clade Permissions")}),
          span(
            list{Attrs.class_("text-xs text-gray-500")},
            list{text(`${Int.toString(Array.length(state.permissionRules))} rules active`)},
          ),
        },
      ),
      p(
        list{Attrs.class_("text-xs text-gray-500 mb-3")},
        list{text("Controls which clades may cross-reference each other via the Panel Bus. Click to toggle.")},
      ),
      div(
        list{Attrs.class_("space-y-1")},
        state.clades->Array.map(entry =>
          div(
            list{Attrs.class_("flex items-center justify-between py-1 px-2 rounded hover:bg-gray-800/50")},
            list{
              div(
                list{Attrs.class_("flex items-center gap-2")},
                list{
                  span(list{Attrs.class_("text-xs text-gray-300 font-mono w-36 truncate")}, list{text(entry.id)}),
                  kindBadge(entry.kind),
                },
              ),
              permissionBadge(state.permissionRules, entry.id),
            },
          )
        )->List.fromArray,
      ),
    },
  )
}

/// Main view function — renders the complete clade browser panel.
let view = (state: cladeBrowserState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("p-5 text-gray-200 font-mono overflow-y-auto max-h-screen"),
      Attrs.role("region"),
      Attrs.ariaLabel("Clade Browser"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex justify-between items-center mb-4")},
        list{
          h2(list{Attrs.class_("text-lg font-bold m-0")}, list{text("Clade Browser")}),
          span(
            list{Attrs.class_("text-xs text-gray-500")},
            list{text(Int.toString(state.clades->Array.length) ++ " clades loaded")},
          ),
        },
      ),
      // Tabs
      div(
        list{Attrs.class_("flex gap-1 mb-4 border-b border-gray-700 pb-2")},
        allCategories->Array.map(cat =>
          renderTab(categoryLabel(cat), state.category === cat, cat)
        )->List.fromArray,
      ),
      // Content
      switch state.category {
      | CategoryOverview => viewOverview(state)
      | CategoryByKind => viewByKind(state)
      | CategoryTraits => viewTraits(state)
      | CategoryPanelMap =>
        div(
          list{},
          list{
            viewPanelMap(state),
            viewPermissions(state),
          },
        )
      },
    },
  )
}
