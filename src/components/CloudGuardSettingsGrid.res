// SPDX-License-Identifier: MPL-2.0

/// PanLL CloudGuard Settings Grid — Grouped toggle/switch grid for zone settings.
///
/// Renders Cloudflare zone settings as an interactive grid of toggles, dropdowns,
/// and number inputs, grouped by category. Settings unavailable on the user's plan
/// are greyed out with a "Requires Pro/Business/Enterprise" badge.
///
/// Modified settings (different from last-pushed state) show an orange dot indicator.
/// Settings that differ from the policy default show a yellow warning icon.
///
/// Layout (within a category tab):
///   +-----------------------------------------+
///   | SSL Mode          [Full (Strict)    v]  |
///   | Min TLS Version   [1.2             v]  |
///   | Always HTTPS      [================ON]  |
///   | Auto Rewrites     [================ON]  |
///   | Opportunistic Enc [================ON]  |
///   | TLS 1.3           [zrt (0-RTT)     v]  |
///   +-----------------------------------------+

open Msg
open Model
open Tea.Html

/// Render a toggle switch for on/off settings.
/// The toggle is a styled checkbox that looks like a sliding switch.
let renderToggle = (setting: cfSetting): Tea_Vdom.t<msg> => {
  let isOn = CloudGuardEngine.isSettingEnabled(setting.value)
  let bgClass = isOn ? "bg-indigo-600" : "bg-gray-600"
  let translateClass = isOn ? "translate-x-5" : "translate-x-0"

  div(
    list{Attrs.class_("flex items-center justify-between py-2 px-3 hover:bg-gray-800/50 rounded")},
    list{
      // Label + description
      div(
        list{Attrs.class_("flex-1 mr-4")},
        list{
          div(list{Attrs.class_("text-sm text-gray-200 font-medium")}, list{text(setting.label)}),
          div(list{Attrs.class_("text-xs text-gray-500 mt-0.5")}, list{text(setting.description)}),
        },
      ),
      // Toggle switch
      button(
        list{
          Attrs.class_(
            `relative inline-flex h-6 w-11 items-center rounded-full transition-colors cursor-pointer ${bgClass}`,
          ),
          Attrs.role("switch"),
          Attrs.ariaChecked(isOn),
          Attrs.ariaLabel(`Toggle ${setting.label}`),
          Events.onClick(CloudGuard(ToggleSetting(setting.id))),
        },
        list{
          span(
            list{
              Attrs.class_(
                `inline-block h-4 w-4 rounded-full bg-white transition-transform ${translateClass}`,
              ),
              Attrs.style("margin-left", "2px"),
            },
            list{},
          ),
        },
      ),
      // Modified indicator
      if setting.modified {
        span(
          list{
            Attrs.class_("w-2 h-2 rounded-full bg-orange-400 ml-2"),
            Attrs.title("Setting has been modified"),
          },
          list{},
        )
      } else {
        noNode
      },
    },
  )
}

/// Render a dropdown select for enum settings.
let renderSelect = (setting: cfSetting, options: array<string>): Tea_Vdom.t<msg> => {
  let currentValue = CloudGuardEngine.settingValueToString(setting.value)

  div(
    list{Attrs.class_("flex items-center justify-between py-2 px-3 hover:bg-gray-800/50 rounded")},
    list{
      // Label + description
      div(
        list{Attrs.class_("flex-1 mr-4")},
        list{
          div(list{Attrs.class_("text-sm text-gray-200 font-medium")}, list{text(setting.label)}),
          div(list{Attrs.class_("text-xs text-gray-500 mt-0.5")}, list{text(setting.description)}),
        },
      ),
      // Select dropdown
      select(
        list{
          Attrs.class_(
            "bg-gray-800 border border-gray-600 rounded px-2 py-1 text-sm text-gray-200 cursor-pointer focus:border-indigo-500 focus:outline-none",
          ),
          Attrs.value(currentValue),
          Attrs.ariaLabel(`Select ${setting.label}`),
          Events.onChange(value => CloudGuard(UpdateSettingValue(setting.id, value))),
        },
        options
        ->Array.map(opt => {
          option'(
            list{
              Attrs.value(opt),
              if opt === currentValue {
                Attrs.selected(true)
              } else {
                Attrs.noProp
              },
            },
            list{text(opt)},
          )
        })
        ->List.fromArray,
      ),
      // Modified indicator
      if setting.modified {
        span(
          list{
            Attrs.class_("w-2 h-2 rounded-full bg-orange-400 ml-2"),
            Attrs.title("Setting has been modified"),
          },
          list{},
        )
      } else {
        noNode
      },
    },
  )
}

/// Render a number input for numeric settings.
let renderNumberInput = (setting: cfSetting): Tea_Vdom.t<msg> => {
  let currentValue = CloudGuardEngine.settingValueToString(setting.value)

  div(
    list{Attrs.class_("flex items-center justify-between py-2 px-3 hover:bg-gray-800/50 rounded")},
    list{
      div(
        list{Attrs.class_("flex-1 mr-4")},
        list{
          div(list{Attrs.class_("text-sm text-gray-200 font-medium")}, list{text(setting.label)}),
          div(list{Attrs.class_("text-xs text-gray-500 mt-0.5")}, list{text(setting.description)}),
        },
      ),
      input(
        list{
          Attrs.class_(
            "bg-gray-800 border border-gray-600 rounded px-2 py-1 text-sm text-gray-200 w-24 focus:border-indigo-500 focus:outline-none",
          ),
          Attrs.type_("number"),
          Attrs.value(currentValue),
          Attrs.ariaLabel(`Set ${setting.label}`),
          Events.onInput(value => CloudGuard(UpdateSettingValue(setting.id, value))),
        },
        list{},
      ),
    },
  )
}

/// Render an exception indicator badge showing that this setting has a
/// per-domain override. Displays the override reason on hover via title attr.
let renderExceptionBadge = (domainExc: domainException): Tea_Vdom.t<msg> => {
  span(
    list{
      Attrs.class_(
        "text-xs text-yellow-400 font-medium px-1.5 py-0.5 border border-yellow-500/30 rounded ml-2",
      ),
      Attrs.title(`Exception: ${domainExc.reason}`),
    },
    list{text("EXC")},
  )
}

/// Render a single setting row, choosing the appropriate input type.
/// Unavailable settings are rendered greyed-out with a plan badge.
/// If an exception exists for the current domain, shows a yellow "EXC" badge.
let renderSettingRow = (setting: cfSetting, domainExc: option<domainException>): Tea_Vdom.t<
  msg,
> => {
  // Check availability from catalog
  let catalogEntry = CloudGuardCatalog.findById(setting.id)

  // The core row content depends on availability and value type
  let rowContent = switch catalogEntry {
  | None => renderToggle(setting) // Fallback to toggle for unknown settings
  | Some(entry) =>
    switch entry.availability {
    | Unavailable(tier) =>
      // Greyed-out setting with plan badge
      div(
        list{
          Attrs.class_("flex items-center justify-between py-2 px-3 opacity-40 cursor-not-allowed"),
        },
        list{
          div(
            list{Attrs.class_("flex-1 mr-4")},
            list{
              div(
                list{Attrs.class_("text-sm text-gray-400 font-medium")},
                list{text(setting.label)},
              ),
              div(
                list{Attrs.class_("text-xs text-gray-600 mt-0.5")},
                list{text(setting.description)},
              ),
            },
          ),
          span(
            list{
              Attrs.class_(
                "text-xs text-amber-500/60 font-medium px-2 py-0.5 border border-amber-500/30 rounded",
              ),
            },
            list{text(`Requires ${CloudGuardCatalog.planLabel(tier)}`)},
          ),
        },
      )
    | Available | Limited(_) =>
      switch entry.valueType {
      | "toggle" => renderToggle(setting)
      | "select" =>
        switch entry.options {
        | Some(opts) => renderSelect(setting, opts)
        | None => renderToggle(setting)
        }
      | "number" => renderNumberInput(setting)
      | _ => renderToggle(setting) // Fallback
      }
    }
  }

  // Wrap with exception badge if this setting has a per-domain override
  switch domainExc {
  | None => rowContent
  | Some(exc) => div(list{Attrs.class_("relative")}, list{rowContent, renderExceptionBadge(exc)})
  }
}

/// Render the settings grid for a given category.
/// Shows all settings in the category, filtered by search text.
/// Exceptions are used to show per-domain override indicators on individual rows.
let view = (
  settings: array<cfSetting>,
  activeCategory: settingCategory,
  settingFilter: string,
  exceptions: array<domainException>,
  currentDomain: option<string>,
): Tea_Vdom.t<msg> => {
  // Filter settings to the active category
  let categorySettings = settings->Array.filter(s => s.category === activeCategory)

  // Apply text filter
  let filteredSettings = if String.length(settingFilter) > 0 {
    let lower = String.toLowerCase(settingFilter)
    categorySettings->Array.filter(s =>
      String.includes(String.toLowerCase(s.label), lower) ||
      String.includes(String.toLowerCase(s.id), lower)
    )
  } else {
    categorySettings
  }

  div(
    list{
      Attrs.class_("flex-1 overflow-y-auto"),
      Attrs.role("list"),
      Attrs.ariaLabel(`${CloudGuardCatalog.categoryLabel(activeCategory)} settings`),
    },
    list{
      if Array.length(filteredSettings) === 0 {
        div(
          list{Attrs.class_("text-gray-600 text-sm italic py-4 px-3")},
          list{text(`No ${CloudGuardCatalog.categoryLabel(activeCategory)} settings found`)},
        )
      } else {
        div(
          list{Attrs.class_("divide-y divide-gray-800/50")},
          filteredSettings
          ->Array.map(setting => {
            // Look up per-domain exception for this setting
            let domainExc = switch currentDomain {
            | Some(domain) => CloudGuardEngine.findException(exceptions, domain, setting.id)
            | None => None
            }
            renderSettingRow(setting, domainExc)
          })
          ->List.fromArray,
        )
      },
    },
  )
}
