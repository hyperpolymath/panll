// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Minter Component — Panel creation wizard.
///
/// A multi-step wizard for minting new panel modules. Every generated panel
/// includes accessibility, ARIA semantics, and keyboard navigation by default.
/// The wizard itself follows the same accessibility standards.
///
/// Steps:
///   0. Name & Identity — panel name, short name, description, icon
///   1. Backend & Config — backend type, endpoint, accessibility level
///   2. Capabilities — declare what the panel can do
///   3. Review & Mint — preview generated files, confirm, generate

open Model
open Msg
open Tea.Html

// ============================================================================
// Step 0: Name & Identity
// ============================================================================

/// Render the name and identity step.
let renderStep0 = (form: minterForm): Tea_Vdom.t<msg> => {
  let validationClass = switch form.nameValidation {
  | NameValid => "text-green-400"
  | NameConflict(_) => "text-red-400"
  | NameInvalid(_) => "text-amber-400"
  }
  let validationText = switch form.nameValidation {
  | NameValid => "Name is available"
  | NameConflict(msg) => msg
  | NameInvalid(msg) => msg
  }

  div(
    list{Attrs.class_("space-y-6")},
    list{
      // Panel name
      div(
        list{},
        list{
          label(
            list{Attrs.class_("block text-sm text-gray-400 mb-1")},
            list{text("Panel Name (PascalCase)")},
          ),
          input(
            list{
              Attrs.class_("w-full bg-gray-800 border border-gray-700 rounded px-3 py-2 text-gray-200 focus:border-indigo-500 focus:outline-none"),
              Attrs.value(form.panelName),
              Attrs.placeholder("e.g. Wharf, Statistease, Fleet"),
              Attrs.ariaLabel("Panel name in PascalCase"),
              Events.onInput(v => Minter(SetPanelName(v))),
            },
            list{},
          ),
          div(
            list{Attrs.class_(`text-xs mt-1 ${validationClass}`)},
            list{text(validationText)},
          ),
        },
      ),
      // Short name
      div(
        list{},
        list{
          label(
            list{Attrs.class_("block text-sm text-gray-400 mb-1")},
            list{text("Short Name (for panel bar)")},
          ),
          input(
            list{
              Attrs.class_("w-full bg-gray-800 border border-gray-700 rounded px-3 py-2 text-gray-200 focus:border-indigo-500 focus:outline-none"),
              Attrs.value(form.shortName),
              Attrs.placeholder("e.g. Wharf, Stats"),
              Attrs.ariaLabel("Short name for panel bar"),
              Events.onInput(v => Minter(SetShortName(v))),
            },
            list{},
          ),
        },
      ),
      // Description
      div(
        list{},
        list{
          label(
            list{Attrs.class_("block text-sm text-gray-400 mb-1")},
            list{text("Description")},
          ),
          input(
            list{
              Attrs.class_("w-full bg-gray-800 border border-gray-700 rounded px-3 py-2 text-gray-200 focus:border-indigo-500 focus:outline-none"),
              Attrs.value(form.description),
              Attrs.placeholder("One-line description of what this panel does"),
              Attrs.ariaLabel("Panel description"),
              Events.onInput(v => Minter(SetDescription(v))),
            },
            list{},
          ),
        },
      ),
      // Icon
      div(
        list{},
        list{
          label(
            list{Attrs.class_("block text-sm text-gray-400 mb-1")},
            list{text("Icon identifier")},
          ),
          input(
            list{
              Attrs.class_("w-full bg-gray-800 border border-gray-700 rounded px-3 py-2 text-gray-200 focus:border-indigo-500 focus:outline-none"),
              Attrs.value(form.icon),
              Attrs.placeholder("e.g. shield, barn, database, globe"),
              Attrs.ariaLabel("Icon identifier"),
              Events.onInput(v => Minter(SetIcon(v))),
            },
            list{},
          ),
        },
      ),
    },
  )
}

// ============================================================================
// Step 1: Backend & Config
// ============================================================================

/// Render a backend kind option as a selectable card.
let renderBackendOption = (
  kind: panelBackendKind,
  isSelected: bool,
): Tea_Vdom.t<msg> => {
  let selectedClass = isSelected
    ? "border-indigo-500 bg-indigo-950/30"
    : "border-gray-700 hover:border-gray-600"
  button(
    list{
      Attrs.class_(`w-full text-left p-3 rounded border ${selectedClass} cursor-pointer transition-colors`),
      Attrs.role("radio"),
      Attrs.ariaChecked(isSelected),
      Events.onClick(Minter(SetBackendKind(kind))),
    },
    list{
      div(
        list{Attrs.class_("text-sm text-gray-200 font-medium")},
        list{text(MinterEngine.backendKindLabel(kind))},
      ),
      div(
        list{Attrs.class_("text-xs text-gray-500 mt-0.5")},
        list{text(MinterEngine.backendKindDescription(kind))},
      ),
    },
  )
}

/// Render the backend and configuration step.
let renderStep1 = (form: minterForm): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-6")},
    list{
      // Backend kind
      div(
        list{},
        list{
          div(
            list{Attrs.class_("text-sm text-gray-400 mb-2")},
            list{text("Backend Type")},
          ),
          div(
            list{
              Attrs.class_("space-y-2"),
              Attrs.role("radiogroup"),
              Attrs.ariaLabel("Backend type selection"),
            },
            MinterEngine.allBackendKinds
            ->Array.map(kind => renderBackendOption(kind, kind === form.backendKind))
            ->List.fromArray,
          ),
        },
      ),
      // Accessibility level
      div(
        list{},
        list{
          div(
            list{Attrs.class_("text-sm text-gray-400 mb-2")},
            list{text("Accessibility Level")},
          ),
          div(
            list{Attrs.class_("space-y-2")},
            list{
              button(
                list{
                  Attrs.class_(
                    `w-full text-left p-3 rounded border cursor-pointer transition-colors ${
                      form.accessibility === StandardAccessibility
                        ? "border-indigo-500 bg-indigo-950/30"
                        : "border-gray-700 hover:border-gray-600"
                    }`,
                  ),
                  Events.onClick(Minter(SetAccessibility(StandardAccessibility))),
                },
                list{
                  div(
                    list{Attrs.class_("text-sm text-gray-200 font-medium")},
                    list{text("Standard")},
                  ),
                  div(
                    list{Attrs.class_("text-xs text-gray-500 mt-0.5")},
                    list{text(MinterEngine.accessibilityDescription(StandardAccessibility))},
                  ),
                },
              ),
              button(
                list{
                  Attrs.class_(
                    `w-full text-left p-3 rounded border cursor-pointer transition-colors ${
                      form.accessibility === EnhancedAccessibility
                        ? "border-indigo-500 bg-indigo-950/30"
                        : "border-gray-700 hover:border-gray-600"
                    }`,
                  ),
                  Events.onClick(Minter(SetAccessibility(EnhancedAccessibility))),
                },
                list{
                  div(
                    list{Attrs.class_("flex items-center gap-2")},
                    list{
                      div(
                        list{Attrs.class_("text-sm text-gray-200 font-medium")},
                        list{text("Enhanced (Recommended)")},
                      ),
                    },
                  ),
                  div(
                    list{Attrs.class_("text-xs text-gray-500 mt-0.5")},
                    list{text(MinterEngine.accessibilityDescription(EnhancedAccessibility))},
                  ),
                },
              ),
            },
          ),
        },
      ),
      // Endpoint (if HTTP backend)
      if form.backendKind === HttpBackend {
        div(
          list{},
          list{
            label(
              list{Attrs.class_("block text-sm text-gray-400 mb-1")},
              list{text("API Endpoint")},
            ),
            input(
              list{
                Attrs.class_("w-full bg-gray-800 border border-gray-700 rounded px-3 py-2 text-gray-200 focus:border-indigo-500 focus:outline-none"),
                Attrs.value(form.endpoint),
                Attrs.placeholder("e.g. http://localhost:4000/api/v1"),
                Attrs.ariaLabel("API endpoint URL"),
                Events.onInput(v => Minter(SetEndpoint(v))),
              },
              list{},
            ),
          },
        )
      } else {
        noNode
      },
    },
  )
}

// ============================================================================
// Step 2: Capabilities
// ============================================================================

/// Render the capabilities step.
let renderStep2 = (form: minterForm): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-4")},
    list{
      div(
        list{Attrs.class_("text-sm text-gray-400")},
        list{text("Declare what your panel can do. Capabilities control which UI elements are rendered.")},
      ),
      // Existing capabilities
      div(
        list{Attrs.class_("space-y-2")},
        form.capabilities
        ->Array.mapWithIndex((cap, i) =>
          div(
            list{Attrs.class_("flex items-center gap-2 p-2 bg-gray-800/50 rounded")},
            list{
              div(
                list{Attrs.class_("flex-1")},
                list{
                  div(
                    list{Attrs.class_("text-sm text-gray-200 font-mono")},
                    list{text(cap.id)},
                  ),
                  div(
                    list{Attrs.class_("text-xs text-gray-500")},
                    list{text(cap.label)},
                  ),
                },
              ),
              button(
                list{
                  Attrs.class_("text-xs text-red-400 hover:text-red-300 px-2 py-1"),
                  Attrs.ariaLabel(`Remove capability ${cap.id}`),
                  Events.onClick(Minter(RemoveCapability(i))),
                },
                list{text("Remove")},
              ),
            },
          )
        )
        ->List.fromArray,
      ),
      // Add capability button
      button(
        list{
          Attrs.class_("px-3 py-2 text-sm bg-gray-800 text-gray-300 rounded hover:bg-gray-700 transition-colors"),
          Attrs.ariaLabel("Add a new capability"),
          Events.onClick(Minter(AddCapability)),
        },
        list{text("+ Add Capability")},
      ),
      if Array.length(form.capabilities) === 0 {
        div(
          list{Attrs.class_("text-xs text-gray-600 italic")},
          list{text("No capabilities declared yet. A default base capability will be generated.")},
        )
      } else {
        noNode
      },
    },
  )
}

// ============================================================================
// Step 3: Review & Mint
// ============================================================================

/// Render the review and mint step.
let renderStep3 = (form: minterForm, minting: bool, lastResult: option<mintResult>): Tea_Vdom.t<msg> => {
  let files = MinterEngine.fileSummary(form)

  div(
    list{Attrs.class_("space-y-6")},
    list{
      // Panel summary
      div(
        list{Attrs.class_("p-4 bg-gray-800/50 rounded-lg")},
        list{
          div(
            list{Attrs.class_("text-lg font-medium text-gray-200 mb-2")},
            list{text(form.panelName)},
          ),
          div(
            list{Attrs.class_("text-sm text-gray-400 mb-3")},
            list{text(form.description)},
          ),
          div(
            list{Attrs.class_("grid grid-cols-2 gap-2 text-xs")},
            list{
              div(list{Attrs.class_("text-gray-500")}, list{text("Backend:")}),
              div(list{Attrs.class_("text-gray-300")}, list{text(MinterEngine.backendKindLabel(form.backendKind))}),
              div(list{Attrs.class_("text-gray-500")}, list{text("Accessibility:")}),
              div(list{Attrs.class_("text-gray-300")}, list{text(MinterEngine.accessibilityLabel(form.accessibility))}),
              div(list{Attrs.class_("text-gray-500")}, list{text("Capabilities:")}),
              div(list{Attrs.class_("text-gray-300")}, list{text(Int.toString(Array.length(form.capabilities)))}),
            },
          ),
        },
      ),
      // File list
      div(
        list{},
        list{
          div(
            list{Attrs.class_("text-sm text-gray-400 mb-2")},
            list{text(`${Int.toString(Array.length(files))} files will be created or patched:`)},
          ),
          div(
            list{Attrs.class_("space-y-1 max-h-48 overflow-y-auto")},
            files
            ->Array.map(((path, desc)) =>
              div(
                list{Attrs.class_("flex items-center gap-2 text-xs")},
                list{
                  span(
                    list{Attrs.class_("text-indigo-400 font-mono flex-1")},
                    list{text(path)},
                  ),
                  span(
                    list{Attrs.class_("text-gray-600")},
                    list{text(desc)},
                  ),
                },
              )
            )
            ->List.fromArray,
          ),
        },
      ),
      // Mint button
      if minting {
        div(
          list{Attrs.class_("text-sm text-indigo-400 animate-pulse"), Attrs.ariaLive("polite")},
          list{text("Minting panel...")},
        )
      } else {
        button(
          list{
            Attrs.class_("w-full px-4 py-3 bg-indigo-600 text-white rounded-lg hover:bg-indigo-500 transition-colors font-medium"),
            Attrs.ariaLabel(`Mint the ${form.panelName} panel`),
            Events.onClick(Minter(ExecuteMint)),
          },
          list{text(`Mint ${form.panelName} Panel`)},
        )
      },
      // Result
      switch lastResult {
      | None => noNode
      | Some(result) =>
        div(
          list{
            Attrs.class_(if result.success { "p-3 bg-green-950/30 border border-green-800/50 rounded" } else { "p-3 bg-red-950/30 border border-red-800/50 rounded" }),
            Attrs.role("alert"),
          },
          list{
            if result.success {
              div(
                list{},
                list{
                  div(
                    list{Attrs.class_("text-sm text-green-400 font-medium mb-1")},
                    list{text("Panel minted successfully!")},
                  ),
                  div(
                    list{Attrs.class_("text-xs text-gray-500")},
                    list{text(`${Int.toString(Array.length(result.filesCreated))} files created, ${Int.toString(Array.length(result.filesPatched))} files patched`)},
                  ),
                },
              )
            } else {
              div(
                list{Attrs.class_("text-sm text-red-400")},
                list{text(switch result.error {
                | Some(err) => err
                | None => "Unknown error"
                })},
              )
            },
          },
        )
      },
    },
  )
}

// ============================================================================
// Wizard navigation
// ============================================================================

/// Render the wizard step indicators.
let renderStepIndicators = (currentStep: int): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("flex items-center gap-2 px-6 py-3 border-b border-gray-800"),
      Attrs.role("navigation"),
      Attrs.ariaLabel("Minting wizard steps"),
    },
    Array.make(~length=MinterEngine.totalSteps, 0)
    ->Array.mapWithIndex((_, i) => {
      let stepClass = if i === currentStep {
        "bg-indigo-600 text-white"
      } else if i < currentStep {
        "bg-green-900/50 text-green-400"
      } else {
        "bg-gray-800 text-gray-600"
      }
      div(
        list{Attrs.class_("flex items-center gap-2")},
        list{
          div(
            list{Attrs.class_(`w-6 h-6 rounded-full flex items-center justify-center text-xs ${stepClass}`)},
            list{text(Int.toString(i + 1))},
          ),
          div(
            list{Attrs.class_(if i === currentStep { "text-xs text-gray-300" } else { "text-xs text-gray-600" })},
            list{text(MinterEngine.stepLabel(i))},
          ),
          if i < MinterEngine.totalSteps - 1 {
            div(
              list{Attrs.class_("w-8 border-t border-gray-700")},
              list{},
            )
          } else {
            noNode
          },
        },
      )
    })
    ->List.fromArray,
  )
}

/// Render the wizard navigation buttons (Back / Next).
let renderNavigation = (form: minterForm, step: int): Tea_Vdom.t<msg> => {
  let canProceed = MinterEngine.canProceedFromStep(form, step)
  div(
    list{Attrs.class_("flex items-center justify-between px-6 py-3 border-t border-gray-800")},
    list{
      if step > 0 {
        button(
          list{
            Attrs.class_("px-4 py-2 text-sm text-gray-400 hover:text-gray-200 bg-gray-800 rounded hover:bg-gray-700 transition-colors"),
            Attrs.ariaLabel("Go to previous step"),
            Events.onClick(Minter(PrevStep)),
          },
          list{text("Back")},
        )
      } else {
        div(list{}, list{})
      },
      if step < MinterEngine.totalSteps - 1 {
        button(
          list{
            Attrs.class_(
              if canProceed {
                "px-4 py-2 text-sm bg-indigo-600 text-white rounded hover:bg-indigo-500 transition-colors"
              } else {
                "px-4 py-2 text-sm bg-gray-700 text-gray-500 rounded cursor-not-allowed"
              },
            ),
            Attrs.ariaLabel("Go to next step"),
            if canProceed {
              Events.onClick(Minter(NextStep))
            } else {
              Attrs.noProp
            },
          },
          list{text("Next")},
        )
      } else {
        div(list{}, list{})
      },
    },
  )
}

// ============================================================================
// Main view
// ============================================================================

/// Main view function for the Panel Minter.
let view = (state: minterState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("main"),
      Attrs.ariaLabel("Panel Minter wizard"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("flex items-center justify-between px-6 py-4 border-b border-gray-800")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-3")},
            list{
              h2(
                list{Attrs.class_("text-lg font-medium text-gray-200")},
                list{text("Panel Minter")},
              ),
              span(
                list{Attrs.class_("text-xs text-gray-600")},
                list{text("Create a new eNSAID-compliant panel module")},
              ),
            },
          ),
          button(
            list{
              Attrs.class_("px-3 py-1.5 text-sm text-gray-400 hover:text-gray-200 bg-gray-800 rounded hover:bg-gray-700 transition-colors"),
              Attrs.ariaLabel("Close Panel Minter"),
              Events.onClick(PanelSwitcher(ClosePanels)),
            },
            list{text("Close")},
          ),
        },
      ),
      // Step indicators
      renderStepIndicators(state.wizardStep),
      // Step content
      div(
        list{Attrs.class_("flex-1 overflow-y-auto p-6 max-w-2xl mx-auto w-full")},
        list{
          switch state.wizardStep {
          | 0 => renderStep0(state.form)
          | 1 => renderStep1(state.form)
          | 2 => renderStep2(state.form)
          | 3 => renderStep3(state.form, state.minting, state.lastResult)
          | _ => noNode
          },
        },
      ),
      // Navigation
      if state.wizardStep < MinterEngine.totalSteps - 1 || state.wizardStep === 0 {
        renderNavigation(state.form, state.wizardStep)
      } else {
        noNode
      },
    },
  )
}
