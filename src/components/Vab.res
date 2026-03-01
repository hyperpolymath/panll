// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL VAB (Verified Assembly Building) Component.
///
/// KSP Vehicle Assembly Building-inspired panel for composing verified server
/// components from the proven-servers catalog. The visual design closely mirrors
/// KSP's iconic VAB: green toolbar and category tabs, orange selection accents,
/// industrial steel rack rails, staging indicators, and part stats.
///
/// Layout:
///   +================================================================+
///   | [KSP-GREEN TOOLBAR]  "Server Name"   [Clear] [Launch] [Close] |
///   +==+===========================+=================================+
///   |  |  Component Grid           |  Server Rack (Assembly Area)    |
///   |G |  +------+ +------+        | ┌─────────────────────────────┐ |
///   |R |  | part | | part |        | │ ● [1] proven-tls       443  │ |
///   |E |  | :443 | |  ✓   |        | │ ● [2] proven-httpd  80,443  │ |
///   |E |  +------+ +------+        | │ ● [3] proven-dbconn   5432  │ |
///   |N |  +------+ +------+        | │ ·  ─ ─ empty slot ─ ─   ·  │ |
///   |  |  | part | | part |        | │ ·  ─ ─ empty slot ─ ─   ·  │ |
///   |C |  |:50051| |  ✓   |        | └─────────────────────────────┘ |
///   |A |  +------+ +------+        |                                 |
///   |T |                           |  ⚠ Missing: proven-socket       |
///   |S |                           |  ⚠ No audit — ops not logged    |
///   +==+===========================+=================================+
///   | [STATS]  RU: 7  Ports: 5  ✓HTTP  ✓DB  ✗Email  ⚠Audit  ✗Cache |
///   +================================================================+
///
/// Colour scheme: KSP VAB (green #4a7c40 toolbar, orange #e8721c accents,
/// industrial steel #2e2e2e/#3a3a3a, green #5a9e50 verified, red #cc3333 errors).

open Msg
open Model
open Tea.Html

// ===========================================================================
// Category Sidebar (KSP-green vertical tab strip)
// ===========================================================================

/// Render a single category icon button in the KSP-green sidebar.
/// Active tab uses the bright green gradient; inactive uses darker green.
let renderCategoryButton = (
  cat: vabCategory,
  isActive: bool,
): Tea_Vdom.t<msg> => {
  let activeClass = isActive ? "vab-sidebar-btn-active" : "vab-sidebar-btn"

  button(
    list{
      Attrs.class_(
        `w-11 h-11 flex items-center justify-center text-xs font-bold rounded ${activeClass}`,
      ),
      Attrs.style("color", isActive ? "white" : "#8ab580"),
      Attrs.title(VabCatalog.categoryName(cat)),
      Attrs.ariaLabel(`Select ${VabCatalog.categoryName(cat)} category`),
      Attrs.ariaPressed(isActive),
      Events.onClick(Vab(SelectCategory(cat))),
    },
    list{text(VabCatalog.categoryIcon(cat))},
  )
}

/// Render the full vertical category sidebar (11 icons) with KSP green styling.
let renderCategorySidebar = (selectedCategory: vabCategory): Tea_Vdom.t<msg> => {
  let categories: array<vabCategory> = [
    VabCore,
    VabNetwork,
    VabDns,
    VabWeb,
    VabIot,
    VabEmail,
    VabSecurity,
    VabData,
    VabApplication,
    VabInfrastructure,
    VabConnectors,
  ]

  div(
    list{
      Attrs.class_("w-14 vab-sidebar flex flex-col gap-1 p-1.5 overflow-y-auto"),
      Attrs.ariaLabel("Component categories"),
      Attrs.role("tablist"),
    },
    List.concat(
      // "PARTS" label at top (like KSP)
      list{
        div(
          list{Attrs.class_("text-center py-1 mb-1")},
          list{
            span(
              list{
                Attrs.class_("text-[8px] font-bold tracking-widest uppercase"),
                Attrs.style("color", "#6ab35e"),
              },
              list{text("PARTS")},
            ),
          },
        ),
      },
      categories
      ->Array.map(cat => renderCategoryButton(cat, cat === selectedCategory))
      ->List.fromArray,
    ),
  )
}

// ===========================================================================
// Top Toolbar (KSP-green gradient bar)
// ===========================================================================

/// Render the KSP-green top toolbar with server name and action buttons.
/// Mimics KSP's green gradient toolbar with orange-accented buttons.
let renderTopBar = (server: assembledServer): Tea_Vdom.t<msg> => {
  let componentCount = Array.length(server.components)

  div(
    list{Attrs.class_("flex items-center gap-3 px-4 py-2.5 vab-toolbar")},
    list{
      // VAB icon/title
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          span(
            list{
              Attrs.class_("text-sm font-bold"),
              Attrs.style("color", "#b8e6b0"),
              Attrs.style("text-shadow", "0 1px 2px rgba(0,0,0,0.4)"),
            },
            list{text("VAB")},
          ),
          div(
            list{
              Attrs.class_("w-px h-5"),
              Attrs.style("background-color", "rgba(255,255,255,0.2)"),
            },
            list{},
          ),
        },
      ),
      // Server name input
      div(
        list{Attrs.class_("flex-1 flex items-center gap-2")},
        list{
          span(
            list{
              Attrs.class_("text-[10px] font-bold uppercase tracking-wider"),
              Attrs.style("color", "#8ab580"),
            },
            list{text("Server:")},
          ),
          input(
            list{
              Attrs.class_(
                "rounded px-3 py-1 text-sm text-white w-64 focus:outline-none font-mono",
              ),
              Attrs.style("background-color", "rgba(0,0,0,0.3)"),
              Attrs.style("border", "1px solid rgba(255,255,255,0.15)"),
              Attrs.value(server.name),
              Attrs.placeholder("Untitled Server"),
              Events.onInput(value => Vab(RenameServer(value))),
            },
            list{},
          ),
          span(
            list{
              Attrs.class_("text-[10px] font-mono"),
              Attrs.style("color", "rgba(255,255,255,0.4)"),
            },
            list{text(`${Int.toString(componentCount)} parts`)},
          ),
        },
      ),
      // Action buttons (KSP-style chunky buttons)
      button(
        list{
          Attrs.class_(
            "px-3 py-1.5 rounded text-xs font-bold uppercase tracking-wide transition-colors",
          ),
          Attrs.style("background-color", "rgba(0,0,0,0.25)"),
          Attrs.style("border", "1px solid rgba(255,255,255,0.15)"),
          Attrs.style("color", "#ccc"),
          Events.onClick(Vab(ClearAssembly)),
          Attrs.ariaLabel("Clear all components from server"),
        },
        list{text("Clear")},
      ),
      button(
        list{
          Attrs.class_(
            "px-3 py-1.5 rounded text-xs font-bold uppercase tracking-wide transition-colors",
          ),
          Attrs.style("background-color", "rgba(232,114,28,0.8)"),
          Attrs.style("border", "1px solid #e8721c"),
          Attrs.style("color", "white"),
          Attrs.style("text-shadow", "0 1px 1px rgba(0,0,0,0.3)"),
          Events.onClick(Vab(ToggleVab)),
          Attrs.ariaLabel("Close VAB panel"),
        },
        list{text("Close")},
      ),
    },
  )
}

// ===========================================================================
// Component Grid (Part Picker)
// ===========================================================================

/// Render a single part card in the KSP-style component grid.
/// Shows part name, port badges, verified indicator, rack unit size,
/// and dependency count — mimicking KSP's part tooltip.
let renderComponentCard = (
  comp: vabComponent,
  isAssembled: bool,
  isHovered: bool,
): Tea_Vdom.t<msg> => {
  let cardClass = if isAssembled {
    "vab-part vab-part-installed"
  } else if isHovered {
    "vab-part"
  } else {
    "vab-part"
  }

  let hoverBorder = if isHovered && !isAssembled {
    "border-color: #e8721c;"
  } else {
    ""
  }

  div(
    list{
      Attrs.class_(`${cardClass} p-2.5 cursor-pointer`),
      Attrs.style("style", hoverBorder),
      Events.onClick(
        if isAssembled {
          Vab(RemoveComponent(comp.id))
        } else {
          Vab(AddComponent(comp.id))
        },
      ),
      Events.onMouseEnter(Vab(HoverComponent(Some(comp.id)))),
      Events.onMouseLeave(Vab(HoverComponent(None))),
      Attrs.title(comp.description),
      Attrs.ariaLabel(
        if isAssembled {
          `Remove ${comp.name} from server`
        } else {
          `Add ${comp.name} to server`
        },
      ),
    },
    list{
      // Header: short name + verified checkmark
      div(
        list{Attrs.class_("flex items-center justify-between mb-1.5")},
        list{
          span(
            list{
              Attrs.class_("text-xs font-bold truncate"),
              Attrs.style("color", if isAssembled { "#6ab35e" } else { "#ddd" }),
            },
            list{text(comp.shortName)},
          ),
          // Green verified tick (KSP science-unlock style)
          span(
            list{Attrs.class_("vab-verified text-xs font-bold")},
            list{text("V")},
          ),
        },
      ),
      // Port badges (orange-tinted)
      if Array.length(comp.ports) > 0 {
        div(
          list{Attrs.class_("flex flex-wrap gap-1 mb-1.5")},
          comp.ports
          ->Array.map(port =>
            span(
              list{
                Attrs.class_("text-[9px] px-1.5 py-0.5 rounded font-mono font-bold"),
                Attrs.style("background-color", "rgba(232,114,28,0.15)"),
                Attrs.style("color", "#e8a050"),
                Attrs.style("border", "1px solid rgba(232,114,28,0.25)"),
              },
              list{text(Int.toString(port))},
            )
          )
          ->List.fromArray,
        )
      } else {
        noNode
      },
      // Stats row: rack units + dep count (like KSP's mass/cost)
      div(
        list{Attrs.class_("flex items-center justify-between mt-1")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              span(
                list{
                  Attrs.class_("text-[9px] font-mono"),
                  Attrs.style("color", "#888"),
                },
                list{text(`${Int.toString(comp.rackUnits)}U`)},
              ),
              if Array.length(comp.dependencies) > 0 {
                span(
                  list{
                    Attrs.class_("text-[9px] font-mono"),
                    Attrs.style("color", "#e8721c"),
                  },
                  list{text(`${Int.toString(Array.length(comp.dependencies))} deps`)},
                )
              } else {
                span(
                  list{
                    Attrs.class_("text-[9px] font-mono"),
                    Attrs.style("color", "#555"),
                  },
                  list{text("no deps")},
                )
              },
            },
          ),
          // Installed indicator or +add
          if isAssembled {
            span(
              list{
                Attrs.class_("text-[9px] font-bold"),
                Attrs.style("color", "#5a9e50"),
              },
              list{text("INSTALLED")},
            )
          } else {
            span(
              list{
                Attrs.class_("text-[9px] font-bold"),
                Attrs.style("color", "#888"),
              },
              list{text("+ADD")},
            )
          },
        },
      ),
    },
  )
}

/// Render the component grid for the selected category.
/// Filter bar and sort buttons use KSP-green/orange styling.
let renderComponentGrid = (
  catalog: array<vabComponent>,
  selectedCategory: vabCategory,
  sortBy: vabSortBy,
  filterText: string,
  assembledIds: array<string>,
  hoveredComponent: option<string>,
): Tea_Vdom.t<msg> => {
  // Filter by category
  let categoryComponents = VabCatalog.getByCategory(catalog, selectedCategory)

  // Apply text filter
  let filtered = if filterText === "" {
    categoryComponents
  } else {
    let lower = String.toLowerCase(filterText)
    Array.filter(categoryComponents, c =>
      String.includes(String.toLowerCase(c.name), lower) ||
      String.includes(String.toLowerCase(c.shortName), lower) ||
      String.includes(String.toLowerCase(c.description), lower)
    )
  }

  // Apply sort
  let sorted = switch sortBy {
  | SortByName =>
    Array.toSorted(filtered, (a, b) =>
      a.name < b.name ? -1.0 : a.name > b.name ? 1.0 : 0.0
    )
  | SortByPorts =>
    Array.toSorted(filtered, (a, b) =>
      Float.fromInt(Array.length(a.ports)) -. Float.fromInt(Array.length(b.ports))
    )
  | SortByDeps =>
    Array.toSorted(filtered, (a, b) =>
      Float.fromInt(Array.length(a.dependencies)) -. Float.fromInt(Array.length(b.dependencies))
    )
  }

  // Sort button helper
  let sortBtn = (label: string, sortVal: vabSortBy) => {
    let isActive = sortBy === sortVal
    button(
      list{
        Attrs.class_("px-2 py-1 rounded text-[10px] font-bold uppercase tracking-wide transition-colors"),
        Attrs.style(
          "background-color",
          if isActive { "rgba(232,114,28,0.8)" } else { "rgba(255,255,255,0.05)" },
        ),
        Attrs.style("color", if isActive { "white" } else { "#888" }),
        Attrs.style(
          "border",
          if isActive { "1px solid #e8721c" } else { "1px solid rgba(255,255,255,0.08)" },
        ),
        Events.onClick(Vab(SetSortBy(sortVal))),
      },
      list{text(label)},
    )
  }

  div(
    list{
      Attrs.class_("flex-1 flex flex-col overflow-hidden"),
      Attrs.style("background-color", "#1e1e1e"),
    },
    list{
      // Filter bar
      div(
        list{
          Attrs.class_("flex items-center gap-2 px-3 py-2"),
          Attrs.style("background-color", "#252525"),
          Attrs.style("border-bottom", "1px solid #333"),
        },
        list{
          input(
            list{
              Attrs.class_(
                "flex-1 rounded px-2 py-1 text-xs text-gray-300 focus:outline-none font-mono",
              ),
              Attrs.style("background-color", "rgba(0,0,0,0.3)"),
              Attrs.style("border", "1px solid #444"),
              Attrs.placeholder("Search parts..."),
              Attrs.value(filterText),
              Events.onInput(value => Vab(SetFilterText(value))),
            },
            list{},
          ),
          sortBtn("A-Z", SortByName),
          sortBtn("Ports", SortByPorts),
          sortBtn("Deps", SortByDeps),
        },
      ),
      // Category header
      div(
        list{
          Attrs.class_("px-3 py-1.5 flex items-center gap-2"),
          Attrs.style("border-bottom", "1px solid #2a2a2a"),
        },
        list{
          span(
            list{
              Attrs.class_("text-[10px] font-bold uppercase tracking-widest"),
              Attrs.style("color", "#6ab35e"),
            },
            list{text(VabCatalog.categoryName(selectedCategory))},
          ),
          span(
            list{
              Attrs.class_("text-[10px] font-mono"),
              Attrs.style("color", "#555"),
            },
            list{
              text(`${Int.toString(Array.length(sorted))} parts`),
            },
          ),
        },
      ),
      // Component grid
      div(
        list{
          Attrs.class_("flex-1 overflow-y-auto px-3 pb-3 pt-2"),
          Attrs.role("list"),
          Attrs.ariaLabel("Available components"),
        },
        list{
          div(
            list{Attrs.class_("grid grid-cols-3 gap-2")},
            sorted
            ->Array.map(comp => {
              let isAssembled = Array.some(assembledIds, id => id === comp.id)
              let isHovered = hoveredComponent === Some(comp.id)
              renderComponentCard(comp, isAssembled, isHovered)
            })
            ->List.fromArray,
          ),
        },
      ),
    },
  )
}

// ===========================================================================
// Server Rack (Assembly Area — industrial steel with rail mounts)
// ===========================================================================

/// Render a single component in the server rack as a mounted rack unit.
/// Uses KSP-style staging numbers (orange), green/red LEDs, and
/// industrial steel appearance. Components with missing deps get red LED.
let renderRackUnit = (
  comp: vabComponent,
  index: int,
  warnings: array<vabWarning>,
  _catalog: array<vabComponent>,
): Tea_Vdom.t<msg> => {
  // Check if this component has any critical warnings
  let hasCritical = Array.some(warnings, w =>
    switch w {
    | MissingRequired(compId, _) => compId === comp.id
    | PortConflict(_, a, b) => a === comp.id || b === comp.id
    | _ => false
    }
  )

  let unitClass = hasCritical ? "vab-rack-unit vab-rack-unit-error" : "vab-rack-unit"

  div(
    list{
      Attrs.class_(
        `${unitClass} flex items-center gap-2 px-2 py-2 rounded-sm transition-all group`,
      ),
      Attrs.role("listitem"),
    },
    list{
      // Mounting bolt (left)
      div(list{Attrs.class_("vab-bolt flex-shrink-0")}, list{}),
      // Staging number (KSP orange)
      div(
        list{Attrs.class_("vab-stage flex-shrink-0")},
        list{text(Int.toString(index + 1))},
      ),
      // LED indicator (green=ok, red=missing deps)
      div(
        list{Attrs.class_(hasCritical ? "vab-led-red flex-shrink-0" : "vab-led-green flex-shrink-0")},
        list{},
      ),
      // Component name
      span(
        list{
          Attrs.class_("flex-1 text-xs font-mono font-bold"),
          Attrs.style("color", if hasCritical { "#cc6666" } else { "#ddd" }),
        },
        list{text(comp.shortName)},
      ),
      // Rack unit size
      span(
        list{
          Attrs.class_("text-[9px] font-mono"),
          Attrs.style("color", "#666"),
        },
        list{text(`${Int.toString(comp.rackUnits)}U`)},
      ),
      // Port display (orange-tinted)
      if Array.length(comp.ports) > 0 {
        span(
          list{
            Attrs.class_("text-[10px] font-mono font-bold"),
            Attrs.style("color", "#e8a050"),
          },
          list{
            text(
              comp.ports->Array.map(p => Int.toString(p))->Array.join(","),
            ),
          },
        )
      } else {
        noNode
      },
      // Remove button (visible on hover — red X)
      button(
        list{
          Attrs.class_(
            "opacity-0 group-hover:opacity-100 w-5 h-5 flex items-center justify-center rounded text-xs font-bold transition-all",
          ),
          Attrs.style("color", "#cc3333"),
          Events.onClick(Vab(RemoveComponent(comp.id))),
          Attrs.ariaLabel(`Remove ${comp.name} from rack`),
        },
        list{text("X")},
      ),
      // Mounting bolt (right)
      div(list{Attrs.class_("vab-bolt flex-shrink-0")}, list{}),
    },
  )
}

/// Render an empty rack slot with mounting hole pattern.
let renderEmptySlot = (_index: int): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("vab-rack-empty flex items-center gap-2 px-2 py-2 rounded-sm opacity-40"),
    },
    list{
      div(list{Attrs.class_("vab-bolt flex-shrink-0")}, list{}),
      div(
        list{
          Attrs.class_("flex-1 text-center"),
        },
        list{
          span(
            list{
              Attrs.class_("text-[10px] font-mono"),
              Attrs.style("color", "#333"),
            },
            list{text("--- empty slot ---")},
          ),
        },
      ),
      div(list{Attrs.class_("vab-bolt flex-shrink-0")}, list{}),
    },
  )
}

/// Render the server rack — the right-hand assembly area.
/// Industrial steel appearance with mounting rails, staging numbers,
/// LED indicators, and KSP-style dependency warnings below.
let renderAssemblyRack = (
  server: assembledServer,
  catalog: array<vabComponent>,
  warnings: array<vabWarning>,
): Tea_Vdom.t<msg> => {
  let assembledComponents = Array.filterMap(server.components, id =>
    VabCatalog.findById(catalog, id)
  )
  let componentCount = Array.length(assembledComponents)

  // Calculate total rack units
  let totalRU = Array.reduce(assembledComponents, 0, (acc, comp) => acc + comp.rackUnits)

  // Calculate empty slots (minimum 6 visible rack slots)
  let totalSlots = if componentCount < 6 { 6 } else { componentCount + 2 }
  let emptySlots = totalSlots - componentCount

  div(
    list{
      Attrs.class_("w-[400px] flex flex-col overflow-hidden"),
      Attrs.style("background-color", "#181818"),
      Attrs.style("border-left", "2px solid #333"),
    },
    list{
      // Rack header with KSP-style label
      div(
        list{
          Attrs.class_("px-3 py-2 flex items-center justify-between"),
          Attrs.style("background-color", "#222"),
          Attrs.style("border-bottom", "2px solid #333"),
        },
        list{
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              span(
                list{
                  Attrs.class_("text-xs font-bold uppercase tracking-widest"),
                  Attrs.style("color", "#6ab35e"),
                },
                list{text("Assembly")},
              ),
            },
          ),
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              span(
                list{
                  Attrs.class_("text-[10px] font-mono font-bold"),
                  Attrs.style("color", "#e8721c"),
                },
                list{text(`${Int.toString(componentCount)} parts`)},
              ),
              span(
                list{
                  Attrs.class_("text-[10px] font-mono"),
                  Attrs.style("color", "#666"),
                },
                list{text(`${Int.toString(totalRU)} RU`)},
              ),
            },
          ),
        },
      ),

      // Rack body (with rail mounts and grid background)
      div(
        list{
          Attrs.class_("flex-1 overflow-y-auto vab-rack vab-rack-rails px-3 py-2"),
          Attrs.role("list"),
          Attrs.ariaLabel("Assembled server components"),
        },
        list{
          div(
            list{Attrs.class_("flex flex-col gap-1")},
            List.concat(
              // Assembled components (with staging numbers)
              assembledComponents
              ->Array.mapWithIndex((comp, i) =>
                renderRackUnit(comp, i, warnings, catalog)
              )
              ->List.fromArray,
              // Empty slots
              Array.make(~length=emptySlots, 0)
              ->Array.mapWithIndex((_, i) =>
                renderEmptySlot(componentCount + i)
              )
              ->List.fromArray,
            ),
          ),
        },
      ),

      // Warning list below rack (KSP-style klaxon warnings)
      if Array.length(warnings) > 0 {
        div(
          list{
            Attrs.class_("px-3 py-2 max-h-36 overflow-y-auto"),
            Attrs.style("background-color", "rgba(30,10,10,0.6)"),
            Attrs.style("border-top", "2px solid #cc3333"),
            Attrs.role("alert"),
            Attrs.ariaLive("polite"),
          },
          list{
            div(
              list{
                Attrs.class_("text-[10px] font-bold uppercase tracking-widest mb-1.5"),
                Attrs.style("color", "#cc3333"),
              },
              list{text("WARNINGS")},
            ),
            div(
              list{Attrs.class_("flex flex-col gap-1")},
              warnings
              ->Array.map(w => {
                let severity = VabEngine.warningSeverity(w)
                let colourClass = switch severity {
                | "error" => "vab-warning-error"
                | "warning" => "vab-warning-caution"
                | _ => "vab-warning-info"
                }
                let iconText = switch severity {
                | "error" => "!!"
                | "warning" => "!~"
                | _ => "??"
                }
                div(
                  list{Attrs.class_(`flex items-start gap-1.5 text-[10px] ${colourClass}`)},
                  list{
                    span(list{Attrs.class_("font-bold font-mono")}, list{text(iconText)}),
                    span(list{Attrs.class_("font-mono")}, list{text(VabEngine.warningLabel(w, catalog))}),
                  },
                )
              })
              ->List.fromArray,
            ),
          },
        )
      } else if componentCount > 0 {
        div(
          list{
            Attrs.class_("px-3 py-2"),
            Attrs.style("background-color", "rgba(10,30,10,0.4)"),
            Attrs.style("border-top", "2px solid #3a6332"),
          },
          list{
            div(
              list{
                Attrs.class_("text-[10px] font-bold font-mono"),
                Attrs.style("color", "#5a9e50"),
              },
              list{text("ALL CHECKS PASSED — Ready for deployment")},
            ),
          },
        )
      } else {
        div(
          list{
            Attrs.class_("px-3 py-2"),
            Attrs.style("border-top", "1px solid #2a2a2a"),
          },
          list{
            div(
              list{
                Attrs.class_("text-[10px] font-mono"),
                Attrs.style("color", "#555"),
              },
              list{text("Click parts to add to rack")},
            ),
          },
        )
      },
    },
  )
}

// ===========================================================================
// Status Bar (Capabilities — KSP stats instrument panel)
// ===========================================================================

/// Render the bottom capability status bar — dark instrument panel style.
/// Green badges for CAN DO, muted badges for CANNOT, orange for warnings.
/// Warning counts displayed as KSP-style mission readiness indicators.
let renderStatusBar = (
  capabilities: array<capabilityStatus>,
  warnings: array<vabWarning>,
): Tea_Vdom.t<msg> => {
  let (reqCount, recCount, secCount) = VabEngine.countWarnings(warnings)
  let totalWarnings = reqCount + recCount + secCount

  div(
    list{
      Attrs.class_("flex items-center gap-2 px-4 py-2 vab-stats overflow-x-auto"),
      Attrs.role("status"),
      Attrs.ariaLabel("Server capabilities"),
    },
    list{
      // Mission readiness — warning summary counts
      if totalWarnings > 0 {
        div(
          list{
            Attrs.class_("flex items-center gap-2 mr-3 pr-3"),
            Attrs.style("border-right", "1px solid #444"),
          },
          list{
            span(
              list{
                Attrs.class_("text-[10px] font-bold uppercase tracking-wider mr-1"),
                Attrs.style("color", "#cc3333"),
              },
              list{text("HOLD")},
            ),
            if reqCount > 0 {
              span(
                list{
                  Attrs.class_("text-[10px] font-mono font-bold vab-warning-error"),
                },
                list{text(`${Int.toString(reqCount)} critical`)},
              )
            } else {
              noNode
            },
            if secCount > 0 {
              span(
                list{
                  Attrs.class_("text-[10px] font-mono font-bold vab-warning-caution"),
                },
                list{text(`${Int.toString(secCount)} security`)},
              )
            } else {
              noNode
            },
            if recCount > 0 {
              span(
                list{
                  Attrs.class_("text-[10px] font-mono vab-warning-info"),
                },
                list{text(`${Int.toString(recCount)} advisory`)},
              )
            } else {
              noNode
            },
          },
        )
      } else {
        div(
          list{
            Attrs.class_("flex items-center gap-1 mr-3 pr-3"),
            Attrs.style("border-right", "1px solid #444"),
          },
          list{
            span(
              list{
                Attrs.class_("text-[10px] font-bold uppercase tracking-wider"),
                Attrs.style("color", "#5a9e50"),
              },
              list{text("GO")},
            ),
          },
        )
      },
      // Capability badges (green=yes, gray=no, orange=warning)
      div(
        list{Attrs.class_("flex items-center gap-1 flex-wrap")},
        capabilities
        ->Array.map(cap => {
          let (label, badgeClass, icon) = switch cap {
          | CanDo(name) => (name, "vab-cap-yes", "V")
          | CannotDo(name) => (name, "vab-cap-no", "X")
          | WarningCap(name) => (name, "vab-cap-warn", "!")
          }
          span(
            list{
              Attrs.class_(
                `inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded text-[9px] font-mono font-bold ${badgeClass}`,
              ),
              Attrs.title(label),
            },
            list{
              span(list{}, list{text(icon)}),
              span(list{}, list{text(label)}),
            },
          )
        })
        ->List.fromArray,
      ),
    },
  )
}

// ===========================================================================
// Main View
// ===========================================================================

/// The main VAB panel view, rendered as a full-screen overlay.
/// Composes: KSP-green toolbar + green category sidebar + part grid +
/// industrial assembly rack + instrument panel status bar.
let view = (vab: vabState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 flex flex-col z-40"),
      Attrs.style("background-color", "#1a1a1a"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Verified Assembly Building — Server Component Composer"),
      KeyboardUtil.onEscape(Vab(ToggleVab)),
    },
    list{
      // Top toolbar — KSP green gradient
      renderTopBar(vab.server),

      // Main content — sidebar + grid + rack
      div(
        list{Attrs.class_("flex-1 flex overflow-hidden")},
        list{
          // Left: KSP-green category sidebar
          renderCategorySidebar(vab.selectedCategory),

          // Centre: component grid (part picker)
          renderComponentGrid(
            vab.catalog,
            vab.selectedCategory,
            vab.sortBy,
            vab.filterText,
            vab.server.components,
            vab.hoveredComponent,
          ),

          // Right: industrial server rack
          renderAssemblyRack(vab.server, vab.catalog, vab.warnings),
        },
      ),

      // Bottom: capability instrument panel
      renderStatusBar(vab.capabilities, vab.warnings),
    },
  )
}
