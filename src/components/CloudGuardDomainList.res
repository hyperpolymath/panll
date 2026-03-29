// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL CloudGuard Domain List — Horizontal domain selector ribbon.
///
/// Renders a scrollable horizontal ribbon of domain checkboxes at the top of
/// the CloudGuard panel. Users can select/deselect individual domains, use
/// "Select All" / "None" shortcuts, and filter by name.
///
/// Layout:
///   [Select All] [None] [Filter: ________]
///   [x wokelang.org] [x axel-protocol.org] [ betlang.org] [x cc-studio.dev] ...
///
/// Selected domains are highlighted with an indigo border. Domains with
/// compliance issues show a small red/yellow dot indicator.

open Msg
open Model
open Tea.Html

/// Render a single domain chip in the ribbon.
/// Selected chips have an indigo border, deselected have a gray border.
let renderDomainChip = (zone: cfZone, isSelected: bool): Tea_Vdom.t<msg> => {
  let borderClass = isSelected
    ? "border-indigo-500 bg-indigo-950/30"
    : "border-gray-700 bg-gray-800/30"

  let statusDot = switch zone.status {
  | "active" =>
    span(list{Attrs.class_("w-2 h-2 rounded-full bg-green-400 inline-block mr-1.5")}, list{})
  | "pending" =>
    span(list{Attrs.class_("w-2 h-2 rounded-full bg-yellow-400 inline-block mr-1.5")}, list{})
  | _ => span(list{Attrs.class_("w-2 h-2 rounded-full bg-gray-500 inline-block mr-1.5")}, list{})
  }

  let planBadge = switch zone.plan {
  | Free => noNode
  | Pro => span(list{Attrs.class_("ml-1.5 text-xs text-orange-400 font-medium")}, list{text("PRO")})
  | Business =>
    span(list{Attrs.class_("ml-1.5 text-xs text-purple-400 font-medium")}, list{text("BIZ")})
  | Enterprise =>
    span(list{Attrs.class_("ml-1.5 text-xs text-blue-400 font-medium")}, list{text("ENT")})
  }

  button(
    list{
      Attrs.class_(
        `inline-flex items-center px-3 py-1.5 rounded border text-sm font-mono cursor-pointer transition-colors ${borderClass} hover:border-indigo-400`,
      ),
      Attrs.ariaPressed(isSelected),
      Attrs.ariaLabel(`${isSelected ? "Deselect" : "Select"} ${zone.name}`),
      Events.onClick(CloudGuard(ToggleZoneSelection(zone.id))),
    },
    list{statusDot, span(list{Attrs.class_("text-gray-200")}, list{text(zone.name)}), planBadge},
  )
}

/// Render the domain filter input.
let renderFilterInput = (filterText: string): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex items-center gap-2")},
    list{
      span(list{Attrs.class_("text-xs text-gray-500")}, list{text("Filter:")}),
      input(
        list{
          Attrs.class_(
            "bg-gray-800 border border-gray-700 rounded px-2 py-1 text-sm text-gray-300 w-40 focus:border-indigo-500 focus:outline-none",
          ),
          Attrs.type_("text"),
          Attrs.value(filterText),
          Attrs.placeholder("domain name..."),
          Attrs.ariaLabel("Filter domains"),
          Events.onInput(text => CloudGuard(SetFilterText(text))),
        },
        list{},
      ),
    },
  )
}

/// Render the "Select All" and "None" shortcut buttons.
let renderSelectionControls = (): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("flex items-center gap-2")},
    list{
      button(
        list{
          Attrs.class_("text-xs text-indigo-400 hover:text-indigo-300 cursor-pointer font-medium"),
          Attrs.ariaLabel("Select all domains"),
          Events.onClick(CloudGuard(SelectAllZones)),
          KeyboardNav.onActivate(CloudGuard(SelectAllZones)),
        },
        list{text("Select All")},
      ),
      span(list{Attrs.class_("text-gray-600")}, list{text("|")}),
      button(
        list{
          Attrs.class_("text-xs text-gray-400 hover:text-gray-300 cursor-pointer font-medium"),
          Attrs.ariaLabel("Deselect all domains"),
          Events.onClick(CloudGuard(DeselectAllZones)),
          KeyboardNav.onActivate(CloudGuard(DeselectAllZones)),
        },
        list{text("None")},
      ),
    },
  )
}

/// Render the complete domain ribbon: controls bar + scrollable chip list.
let view = (zones: array<cfZone>, selectedZoneIds: array<string>, filterText: string): Tea_Vdom.t<
  msg,
> => {
  let filteredZones = CloudGuardEngine.filterZones(zones, filterText)

  div(
    list{
      Attrs.class_("border-b border-gray-800 pb-3"),
      Attrs.role("region"),
      Attrs.ariaLabel("Domain selector"),
    },
    list{
      // Controls row: Select All | None | Filter
      div(
        list{Attrs.class_("flex items-center justify-between mb-2")},
        list{
          renderSelectionControls(),
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              span(
                list{Attrs.class_("text-xs text-gray-500")},
                list{
                  text(
                    `${Int.toString(Array.length(selectedZoneIds))}/${Int.toString(
                        Array.length(zones),
                      )} selected`,
                  ),
                },
              ),
              renderFilterInput(filterText),
            },
          ),
        },
      ),
      // Domain chips ribbon (scrollable)
      div(
        list{
          Attrs.class_("flex flex-wrap gap-1.5 max-h-20 overflow-y-auto"),
          Attrs.role("listbox"),
          Attrs.ariaLabel("Domains"),
          Attrs.prop("aria-multiselectable", "true"),
        },
        filteredZones
        ->Array.map(zone => {
          let isSelected = Array.includes(selectedZoneIds, zone.id)
          renderDomainChip(zone, isSelected)
        })
        ->List.fromArray,
      ),
    },
  )
}
