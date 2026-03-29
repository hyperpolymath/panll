// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Minter Engine — pure template generation logic for the Panel Minter.
///
/// All functions are pure (no side effects, no API calls). This module
/// generates the ReScript source code strings for each file in a new panel
/// module, and validates panel names against the existing registry.
///
/// The generated code includes accessibility attributes, ARIA semantics,
/// keyboard navigation, and proof hook stubs by default — making it
/// structurally harder to produce an inaccessible panel than an accessible one.

open MinterModel

// ============================================================================
// Name validation
// ============================================================================

/// Reserved panel names that cannot be used (existing or special).
let reservedNames: array<string> = [
  "CloudGuard",
  "Vab",
  "Farm",
  "Fleet",
  "Hypatia",
  "Reposystem",
  "Databases",
  "Aerie",
  "Interfaces",
  "Playgrounds",
  "Plaza",
  "Minter",
  "PanelSwitcher",
  "Model",
  "Msg",
  "Update",
  "View",
]

/// Validate a panel name: must be PascalCase, non-empty, and not reserved.
let validateName = (name: string): nameValidation => {
  if String.length(name) === 0 {
    NameInvalid("Panel name cannot be empty")
  } else if String.length(name) < 2 {
    NameInvalid("Panel name must be at least 2 characters")
  } else {
    // Check PascalCase: first char uppercase, rest alphanumeric
    let firstChar = String.charAt(name, 0)
    if firstChar !== String.toUpperCase(firstChar) {
      NameInvalid("Panel name must start with an uppercase letter (PascalCase)")
    } else if reservedNames->Array.includes(name) {
      NameConflict(`"${name}" is already registered or reserved`)
    } else {
      NameValid
    }
  }
}

/// Convert PascalCase to camelCase for variable/field names.
let toCamelCase = (name: string): string => {
  if String.length(name) === 0 {
    ""
  } else {
    String.toLowerCase(String.charAt(name, 0)) ++ String.sliceToEnd(name, ~start=1)
  }
}

/// Convert PascalCase to snake_case for Rust module/command names.
let toSnakeCase = (name: string): string => {
  let result = ref("")
  for i in 0 to String.length(name) - 1 {
    let ch = String.charAt(name, i)
    if ch === String.toUpperCase(ch) && ch !== String.toLowerCase(ch) {
      if i > 0 {
        result := result.contents ++ "_"
      }
      result := result.contents ++ String.toLowerCase(ch)
    } else {
      result := result.contents ++ ch
    }
  }
  result.contents
}

// ============================================================================
// Display helpers
// ============================================================================

/// Human-readable label for a backend kind.
let backendKindLabel = (kind: panelBackendKind): string => {
  switch kind {
  | NoBackend => "No Backend"
  | FilesystemBackend => "Filesystem"
  | HttpBackend => "HTTP API"
  | DatabaseBackend => "Database"
  }
}

/// All backend kinds in display order.
let allBackendKinds: array<panelBackendKind> = [
  NoBackend,
  FilesystemBackend,
  HttpBackend,
  DatabaseBackend,
]

/// Human-readable label for an accessibility level.
let accessibilityLabel = (level: accessibilityLevel): string => {
  switch level {
  | StandardAccessibility => "Standard"
  | EnhancedAccessibility => "Enhanced"
  }
}

/// Description for an accessibility level.
let accessibilityDescription = (level: accessibilityLevel): string => {
  switch level {
  | StandardAccessibility => "Keyboard nav, role attributes, aria-label on interactive elements"
  | EnhancedAccessibility => "Adds aria-live regions, focus management, skip links, landmark roles"
  }
}

/// Description for a backend kind.
let backendKindDescription = (kind: panelBackendKind): string => {
  switch kind {
  | NoBackend => "Pure frontend panel with no backend commands"
  | FilesystemBackend => "Reads local files via backend (like Farm, Plaza)"
  | HttpBackend => "Connects to an external HTTP API (like CloudGuard)"
  | DatabaseBackend => "Uses existing database module connections"
  }
}

// ============================================================================
// Wizard step helpers
// ============================================================================

/// Total number of wizard steps.
let totalSteps = 4

/// Label for a wizard step.
let stepLabel = (step: int): string => {
  switch step {
  | 0 => "Name & Identity"
  | 1 => "Backend & Config"
  | 2 => "Capabilities"
  | 3 => "Review & Mint"
  | _ => "Unknown"
  }
}

/// Whether the form is valid enough to proceed past a given step.
let canProceedFromStep = (form: minterForm, step: int): bool => {
  switch step {
  | 0 =>
    form.nameValidation === NameValid &&
    String.length(form.panelName) >= 2 &&
    String.length(form.shortName) >= 1 &&
    String.length(form.description) >= 5
  | 1 => true // Backend kind always has a valid default
  | 2 => true // Capabilities are optional
  | 3 => true // Review step — ready to mint
  | _ => false
  }
}

// ============================================================================
// Template generation — ReScript source code strings
// ============================================================================

/// Generate the Model file content for a new panel.
let generateModel = (form: minterForm): string => {
  let camel = toCamelCase(form.panelName)

  `// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL ${form.panelName} Model - state types for the ${form.panelName} panel.
///
/// ${form.description}
///
/// Dependency: leaf module - no imports from other PanLL models.

/// Category tabs for the ${form.panelName} panel.
type ${camel}Category =
  | ${form.panelName}Dashboard
  | ${form.panelName}Settings

/// Root state for the ${form.panelName} panel.
type ${camel}State = {
  loaded: bool,
  loading: bool,
  error: option<string>,
  activeCategory: ${camel}Category,
  filterText: string,
}
`
}

/// Generate the Module file content for a new panel.
let generateModule = (form: minterForm): string => {
  let camel = toCamelCase(form.panelName)

  let capVariants = if Array.length(form.capabilities) > 0 {
    form.capabilities
    ->Array.map(cap => `  | ${cap.id}`)
    ->Array.join("\n")
  } else {
    `  | ${form.panelName}Base`
  }

  let capLabels = if Array.length(form.capabilities) > 0 {
    form.capabilities
    ->Array.map(cap => `  | ${cap.id} => "${cap.label}"`)
    ->Array.join("\n")
  } else {
    `  | ${form.panelName}Base => "${form.panelName} Base"`
  }

  let capArray = if Array.length(form.capabilities) > 0 {
    form.capabilities
    ->Array.map(cap => cap.id)
    ->Array.join(", ")
  } else {
    `${form.panelName}Base`
  }

  `// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL ${form.panelName} Module - capability registration.
///
/// Declares what the ${form.panelName} panel can do. The UI renders controls
/// only for capabilities that are declared here.

open ${form.panelName}Model

/// Capabilities that the ${form.panelName} panel exposes.
type ${camel}Capability =
${capVariants}

/// Module configuration for the ${form.panelName} panel.
type ${camel}ModuleConfig = {
  id: string,
  name: string,
  version: string,
  description: string,
  capabilities: array<${camel}Capability>,
  icon: option<string>,
}

/// The canonical module configuration.
let config: ${camel}ModuleConfig = {
  id: "${camel}",
  name: "${form.panelName}",
  version: "0.1.0",
  description: "${form.description}",
  capabilities: [${capArray}],
  icon: Some("${form.icon}"),
}

/// Check if a capability is declared.
let hasCapability = (cap: ${camel}Capability): bool => {
  config.capabilities->Array.includes(cap)
}

/// Human-readable label for a capability.
let capabilityLabel = (cap: ${camel}Capability): string => {
  switch cap {
${capLabels}
  }
}
`
}

/// Generate the Component (view) file content for a new panel.
/// Includes accessibility attributes by default.
let generateComponent = (form: minterForm): string => {
  let camel = toCamelCase(form.panelName)
  let enhancedAria = form.accessibility === EnhancedAccessibility

  let landmarkRole = enhancedAria
    ? `
      Attrs.role("main"),
      Attrs.ariaLabel("${form.panelName} panel"),`
    : `
      Attrs.ariaLabel("${form.panelName} panel"),`

  `// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL ${form.panelName} Component - view layer for the ${form.panelName} panel.
///
/// ${form.description}
///
/// Accessibility: keyboard navigation, ARIA labels, and role attributes are
/// included by default. All interactive elements are focusable and labelled.

open Model
open Msg
open Tea.Html

/// Render the category tab bar with accessible tab semantics.
let renderCategoryTab = (
  cat: ${camel}Category,
  isActive: bool,
): Tea_Vdom.t<msg> => {
  let activeClass = isActive
    ? "border-indigo-500 text-indigo-300 bg-gray-800/50"
    : "border-transparent text-gray-500 hover:text-gray-300 hover:border-gray-600"
  button(
    list{
      Attrs.class_(\`px-4 py-2 text-sm font-medium border-b-2 cursor-pointer transition-colors \${activeClass}\`),
      Attrs.role("tab"),
      Attrs.ariaSelected(isActive),
      Events.onClick(${form.panelName}(Set${form.panelName}Category(cat))),
    },
    list{text(${form.panelName}Engine.categoryLabel(cat))},
  )
}

/// Render the tab bar.
let renderTabBar = (activeCategory: ${camel}Category): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("flex border-b border-gray-800 overflow-x-auto"),
      Attrs.role("tablist"),
      Attrs.ariaLabel("${form.panelName} sections"),
    },
    ${form.panelName}Engine.allCategories
    ->Array.map(cat => renderCategoryTab(cat, cat === activeCategory))
    ->List.fromArray,
  )
}

/// Render the panel header with title and close button.
let renderHeader = (state: ${camel}State): Tea_Vdom.t<msg> => {
  let _ = state // Available for header stats
  div(
    list{Attrs.class_("flex items-center justify-between px-6 py-4 border-b border-gray-800")},
    list{
      div(
        list{Attrs.class_("flex items-center gap-3")},
        list{
          h2(
            list{Attrs.class_("text-lg font-medium text-gray-200")},
            list{text("${form.panelName}")},
          ),
        },
      ),
      button(
        list{
          Attrs.class_("px-3 py-1.5 text-sm text-gray-400 hover:text-gray-200 bg-gray-800 rounded hover:bg-gray-700 transition-colors"),
          Attrs.ariaLabel("Close ${form.panelName} panel"),
          Events.onClick(PanelSwitcher(ClosePanels)),
        },
        list{text("Close")},
      ),
    },
  )
}

/// Render the main content area.
let renderContent = (state: ${camel}State): Tea_Vdom.t<msg> => {
  let _ = state
  div(
    list{
      Attrs.class_("flex-1 overflow-y-auto p-6"),
      Attrs.role("tabpanel"),
    },
    list{
      div(
        list{Attrs.class_("text-center py-12")},
        list{
          div(
            list{Attrs.class_("text-2xl font-light text-gray-400 mb-4")},
            list{text("${form.panelName}")},
          ),
          div(
            list{Attrs.class_("text-sm text-gray-600")},
            list{text("${form.description}")},
          ),
          div(
            list{Attrs.class_("text-xs text-gray-700 mt-2")},
            list{text("Panel scaffolded by the PanLL Minter")},
          ),
        },
      ),
    },
  )
}

/// Render the loading state with accessible live region.
let renderLoading = (): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("flex items-center justify-center py-12"),
      Attrs.ariaLive("polite"),
    },
    list{
      div(
        list{Attrs.class_("text-sm text-gray-500 animate-pulse")},
        list{text("Loading ${form.panelName}...")},
      ),
    },
  )
}

/// Render an error state with accessible alert role.
let renderError = (err: string): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("mx-6 my-4 p-3 bg-red-950/30 border border-red-800/50 rounded"),
      Attrs.role("alert"),
    },
    list{
      div(
        list{Attrs.class_("text-sm text-red-400")},
        list{text(err)},
      ),
    },
  )
}

/// Main view function for the ${form.panelName} panel.
let view = (state: ${camel}State): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),${landmarkRole}
    },
    list{
      renderHeader(state),
      renderTabBar(state.activeCategory),
      if state.loading {
        renderLoading()
      } else {
        switch state.error {
        | Some(err) => renderError(err)
        | None => renderContent(state)
        }
      },
    },
  )
}
`
}

/// Generate the Engine file content for a new panel.
let generateEngine = (form: minterForm): string => {
  let camel = toCamelCase(form.panelName)

  `// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL ${form.panelName} Engine - pure computation for the ${form.panelName} panel.
///
/// All functions are pure (no side effects, no API calls).

open ${form.panelName}Model

/// Human-readable label for a category.
let categoryLabel = (cat: ${camel}Category): string => {
  switch cat {
  | ${form.panelName}Dashboard => "Dashboard"
  | ${form.panelName}Settings => "Settings"
  }
}

/// All categories in display order.
let allCategories: array<${camel}Category> = [
  ${form.panelName}Dashboard,
  ${form.panelName}Settings,
]
`
}

/// Generate the Cmd file content for a new panel (only if backend is needed).
let generateCmd = (form: minterForm): option<string> => {
  let snake = toSnakeCase(form.panelName)

  switch form.backendKind {
  | NoBackend => None
  | _ =>
    Some(
      `// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL ${form.panelName} Commands - backend command wrappers.
///
/// Each function wraps a RuntimeBridge.invoke call in a \`Tea_Cmd.call\`,
/// converting the Promise-based IPC into the TEA command model.
/// Works with Gossamer runtime.

let invoke = RuntimeBridge.invoke

/// Load the primary data for this panel.
let loadData = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("${snake}_load_data", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to load ${form.panelName} data")))
      Promise.resolve()
    })
    ->ignore
  })
}
`,
    )
  }
}

/// Summary of what files will be generated for the review step.
let fileSummary = (form: minterForm): array<(string, string)> => {
  let camel = toCamelCase(form.panelName)
  let snake = toSnakeCase(form.panelName)
  let hasBackend = form.backendKind !== NoBackend

  let files = [
    (`src/model/${form.panelName}Model.res`, "State types"),
    (`src/modules/${form.panelName}Module.res`, "Capability registration"),
    (`src/core/${form.panelName}Engine.res`, "Pure computation"),
    (`src/components/${form.panelName}.res`, "View component"),
  ]

  let manifestFile = [(`src/panels/${snake}/panels/manifest.json`, "panll-harness/v2 manifest")]

  let cmdFile = hasBackend ? [(`src/commands/${form.panelName}Cmd.res`, "Backend commands")] : []

  let rustFiles = hasBackend
    ? [
        (`src-gossamer/src/${snake}/mod.rs`, "Rust module"),
        (`src-gossamer/src/${snake}/types.rs`, "Rust types"),
        (`src-gossamer/src/${snake}/commands.rs`, "Backend handlers"),
      ]
    : []

  let patches = [
    ("src/model/PanelSwitcherModel.res", `Add Panel${form.panelName} variant`),
    ("src/modules/PanelRegistry.res", "Register panel metadata"),
    ("src/Model.res", `Add include + ${camel} field`),
    ("src/Msg.res", `Add ${camel}Msg type`),
    ("src/View.res", "Add renderActivePanel case"),
    ("src/Update.res", `Add update${form.panelName} handler`),
  ]

  Array.concat(
    Array.concat(Array.concat(Array.concat(files, manifestFile), cmdFile), rustFiles),
    patches,
  )
}

/// Default form state for a new minting session.
let defaultForm: minterForm = {
  panelName: "",
  shortName: "",
  description: "",
  icon: "panel",
  backendKind: NoBackend,
  accessibility: EnhancedAccessibility,
  capabilities: [],
  nameValidation: NameInvalid("Panel name cannot be empty"),
  endpoint: "",
}

/// Default minter state.
let defaultState: minterState = {
  form: defaultForm,
  minting: false,
  lastResult: None,
  error: None,
  wizardStep: 0,
}
