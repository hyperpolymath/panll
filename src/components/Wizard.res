// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Wizard Component — Guided plugin/panel creation wizard.

open Model
open Msg
open Tea.Html

/// Render the wizard component
let renderWizard = (state: model): Tea_Vdom.t<msg> => {
  let wizardState = state.wizard
  
  div(
    list{
      Attrs.class_("wizard-container p-6 bg-gray-900 rounded-lg max-w-2xl mx-auto"),
    },
    list{
      // Header
      div(list{Attrs.class_("flex justify-between items-center mb-6")}, list{
        h2(list{Attrs.class_("text-2xl font-bold text-gray-200")}, list{text("Plugin/Panel Creation Wizard")}),
        button(
          list{
            Attrs.class_("px-4 py-2 bg-gray-700 text-white rounded hover:bg-gray-600 transition"),
            Events.onClick(Wizard(ResetWizard)),
          },
          list{text("Reset")}
        ),
      }),
      
      // Step indicator
      div(list{Attrs.class_("flex gap-4 mb-6")}, list{
        [
          WizardModel.SelectType,
          WizardModel.ChooseCapabilities,
          WizardModel.ConfigureDependencies,
          WizardModel.SetupSecurity,
          WizardModel.ReviewAndGenerate,
        ]->Array.map(step => {
          let isCurrent = wizardState.currentStep === step
          let isCompleted = WizardModel.stepIndex(step) < WizardModel.stepIndex(wizardState.currentStep)
          
          div(
            list{
              Attrs.class_(
                `flex items-center gap-2 ${isCurrent ? "text-indigo-400" : isCompleted ? "text-green-400" : "text-gray-500"}`
              ),
            },
            list{
              div(list{Attrs.class_("w-6 h-6 rounded-full border-2 flex items-center justify-center text-xs")}, list{
                text(isCompleted ? "✓" : String.from_int(WizardModel.stepIndex(step) + 1))
              }),
              text(WizardModel.stepLabel(step)),
            }
          )
        })->List.fromArray,
      }),
      
      // Step content
      div(list{Attrs.class_("border-t border-gray-700 pt-6")}, list{
        renderStepContent(wizardState)
      }),
      
      // Navigation
      div(list{Attrs.class_("flex justify-between mt-8")}, list{
        button(
          list{
            Attrs.class_("px-4 py-2 bg-gray-700 text-white rounded hover:bg-gray-600 transition disabled:opacity-50 disabled:cursor-not-allowed"),
            Attrs.disabled(wizardState.currentStep === WizardModel.SelectType),
            Events.onClick(Wizard(PreviousStep)),
          },
          list{text("Back")}
        ),
        button(
          list{
            Attrs.class_("px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700 transition disabled:opacity-50 disabled:cursor-not-allowed"),
            Attrs.disabled(!WizardModel.canProceed(wizardState)),
            Events.onClick(Wizard(NextStep)),
          },
          list{text(WizardModel.isLastStep(wizardState.currentStep) ? "Finish" : "Next")}
        ),
      }),
    }
  )
}

/// Render step-specific content
let renderStepContent = (state: WizardModel.wizardState): Tea_Vdom.t<msg> => {
  switch state.currentStep {
  | SelectType => renderSelectType(state)
  | ChooseCapabilities => renderChooseCapabilities(state)
  | ConfigureDependencies => renderConfigureDependencies(state)
  | SetupSecurity => renderSetupSecurity(state)
  | ReviewAndGenerate => renderReviewAndGenerate(state)
  }
}

/// Render type selection step
let renderSelectType = (state: WizardModel.wizardState): Tea_Vdom.t<msg> => {
  div(list{}, list{
    h3(list{Attrs.class_("text-xl font-semibold mb-4 text-gray-200")}, list{text("What would you like to create?")}),
    p(list{Attrs.class_("text-gray-400 mb-6")}, list{text("Choose whether to create a panel or a plugin")}),
    
    div(list{Attrs.class_("grid grid-cols-2 gap-4")}, list{
      // Panel option
      button(
        list{
          Attrs.class_(`
            p-6 border-2 rounded-lg transition-all 
            ${state.creationType->Option.contains(WizardModel.CreatingPanel) ? "border-indigo-500 bg-indigo-900" : "border-gray-700 hover:border-gray-600"}
          `),
          Events.onClick(Wizard(SetCreationType(WizardModel.CreatingPanel))),
        },
        list{
          h4(list{Attrs.class_("text-lg font-semibold mb-2")}, list{text("Panel")}),
          p(list{Attrs.class_("text-gray-400 text-sm")}, list{text("Create a new UI panel for PanLL")}),
        }
      ),
      
      // Plugin option
      button(
        list{
          Attrs.class_(`
            p-6 border-2 rounded-lg transition-all 
            ${state.creationType->Option.contains(WizardModel.CreatingPlugin) ? "border-indigo-500 bg-indigo-900" : "border-gray-700 hover:border-gray-600"}
          `),
          Events.onClick(Wizard(SetCreationType(WizardModel.CreatingPlugin))),
        },
        list{
          h4(list{Attrs.class_("text-lg font-semibold mb-2")}, list{text("Plugin")}),
          p(list{Attrs.class_("text-gray-400 text-sm")}, list{text("Create a new plugin cartridge")}),
        }
      ),
    }),
  })
}

/// Render capability selection step
let renderChooseCapabilities = (state: WizardModel.wizardState): Tea_Vdom.t<msg> => {
  // Get capabilities by category
  let categories = WizardModel.getCapabilityCategories()
  let requiredDeps = WizardModel.getRequiredDependencies(state)
  
  div(list{Attrs.class_("space-y-6")}, list{
    // Step header
    h3(list{Attrs.class_("text-xl font-semibold text-gray-200")}, list{text("Select Capabilities")}),
    p(list{Attrs.class_("text-gray-400")}, list{text("Choose what your component can do")}),
    
    // Required dependencies warning
    if (requiredDeps->Array.length > 0) {
      div(list{Attrs.class_("p-3 bg-yellow-900/30 rounded-lg")}, list{
        h4(list{Attrs.class_("font-semibold text-yellow-300 mb-2")}, list{text("Required Dependencies")}),
        p(list{Attrs.class_("text-yellow-200 text-sm")}, list{
          text("The following capabilities require additional dependencies:"),
        }),
        ul(list{Attrs.class_("list-disc list-inside mt-2 text-yellow-100 text-sm")}, list{
          requiredDeps->Array.map(depId => {
            li(list{}, list{text(depId)})
          })->List.fromArray
        })
      })
    },
    
    // Capability categories
    categories->Array.map(category => {
      let categoryCaps = WizardModel.getCapabilitiesByCategory(category)
      
      div(list{Attrs.class_("border border-gray-700 rounded-lg p-4")}, list{
        h4(list{Attrs.class_("text-lg font-semibold mb-3 text-gray-200")}, list{text(category)}),
        
        div(list{Attrs.class_("grid grid-cols-1 md:grid-cols-2 gap-3")}, list{
          categoryCaps->Array.map(cap => {
            let isSelected = WizardModel.isCapabilitySelected(cap.id, state)
            let hasDeps = cap.requiredDependencies->Array.length > 0
            
            button(
              list{
                Attrs.class_(`
                  p-3 border rounded transition-all flex flex-col 
                  ${isSelected 
                    ? "border-indigo-500 bg-indigo-900/30"
                    : "border-gray-600 hover:border-gray-500"}
                `),
                Attrs.onClick(_ => Wizard(ToggleCapability(cap.id))),
                Attrs.role("checkbox"),
                Attrs.ariaChecked(isSelected),
                Attrs.ariaLabel(`${cap.name} - ${cap.description}`),
              },
              list{
                div(list{Attrs.class_("flex justify-between items-start")}, list{
                  div(list{}, list{
                    h5(list{Attrs.class_("font-medium text-gray-200")}, list{text(cap.name)}),
                    p(list{Attrs.class_("text-xs text-gray-400 mt-1")}, list{text(cap.description)}),
                  }),
                  if (hasDeps) {
                    span(list{
                      Attrs.class_("text-xs bg-yellow-600 text-yellow-100 px-2 py-1 rounded-full ml-2")
                    }, list{text(`${cap.requiredDependencies->Array.length} deps`)})
                  } else {
                    react.null
                  }
                }),
                if (isSelected) {
                  div(list{Attrs.class_("text-xs text-green-400 mt-2 self-end")}, list{text("✓ Selected")})
                } else {
                  react.null
                }
              }
            )
          })->List.fromArray
        })
      })
    })
  })
}

/// Render dependency configuration step
let renderConfigureDependencies = (state: WizardModel.wizardState): Tea_Vdom.t<msg> => {
  let requiredDeps = WizardModel.getRequiredDependencies(state)
  let satisfiedDeps = state.dependencies->Array.map(dep => dep.pluginId)
  
  div(list{Attrs.class_("space-y-6")}, list{
    // Step header
    h3(list{Attrs.class_("text-xl font-semibold text-gray-200")}, list{text("Configure Dependencies")}),
    p(list{Attrs.class_("text-gray-400")}, list{text("Set up required dependencies for selected capabilities")}),
    
    // Dependency status
    div(list{Attrs.class_("flex gap-4")}, list{
      div(list{Attrs.class_("flex-1")}, list{
        div(list{Attrs.class_("p-4 border border-gray-700 rounded-lg")}, list{
          h4(list{Attrs.class_("font-semibold text-gray-200 mb-2")}, list{text("Required Dependencies")}),
          p(list{Attrs.class_("text-xs text-gray-400 mb-3")}, list{
            text(`${requiredDeps->Array.length} dependencies needed`)
          }),
          if (requiredDeps->Array.length > 0) {
            ul(list{Attrs.class_("space-y-2 text-sm")}, list{
              requiredDeps->Array.map(depId => {
                let isSatisfied = satisfiedDeps->Array.includes(depId)
                li(list{
                  Attrs.class_(`flex items-center ${isSatisfied ? "text-green-400" : "text-red-400"}`)
                }, list{
                  if (isSatisfied) {
                    span(list{Attrs.class_("mr-2")}, list{text("✓")})
                  } else {
                    span(list{Attrs.class_("mr-2")}, list{text("✗")})
                  },
                  text(depId)
                })
              })->List.fromArray
            })
          } else {
            p(list{Attrs.class_("text-green-400 text-sm")}, list{text("No dependencies required")})
          }
        })
      }),
      div(list{Attrs.class_("flex-1")}, list{
        div(list{Attrs.class_("p-4 border border-gray-700 rounded-lg")}, list{
          h4(list{Attrs.class_("font-semibold text-gray-200 mb-2")}, list{text("Configured Dependencies")}),
          p(list{Attrs.class_("text-xs text-gray-400 mb-3")}, list{
            text(`${state.dependencies->Array.length} dependencies configured`)
          }),
          if (state.dependencies->Array.length > 0) {
            table(list{Attrs.class_("w-full text-sm")}, list{
              thead(list{}, list{
                tr(list{}, list{
                  th(list{Attrs.class_("text-left text-gray-400 pb-2")}, list{text("Plugin")}),
                  th(list{Attrs.class_("text-left text-gray-400 pb-2")}, list{text("Version")}),
                  th(list{Attrs.class_("text-left text-gray-400 pb-2")}, list{text("Tier")}),
                })
              }),
              tbody(list{}, list{
                state.dependencies->Array.map(dep => {
                  tr(list{Attrs.class_("border-t border-gray-800")}, list{
                    td(list{Attrs.class_("py-2 text-gray-200")}, list{text(dep.pluginId)}),
                    td(list{Attrs.class_("py-2")}, list{
                      input_(
                        list{
                          Attrs.class_("w-24 px-2 py-1 bg-gray-800 border border-gray-600 rounded text-sm"),
                          Attrs.value(dep.version),
                          Attrs.onChange(ev => {
                            let newVersion = ReactEvent.Form.target(ev)["value"]
                            Wizard(AddDependency(dep.pluginId, newVersion))
                          })
                        }
                      )
                    }),
                    td(list{Attrs.class_("py-2")}, list{
                      select(
                        list{
                          Attrs.class_("px-2 py-1 bg-gray-800 border border-gray-600 rounded text-sm"),
                          Attrs.value(dep.tier),
                          Attrs.onChange(ev => {
                            let newTier = ReactEvent.Form.target(ev)["value"]
                            // Would need to update dependency tier
                          })
                        },
                        list{
                          option(list{Attrs.value("Teranga")}, list{text("Teranga")}),
                          option(list{Attrs.value("Shield")}, list{text("Shield")}),
                          option(list{Attrs.value("Ayo")}, list{text("Ayo")})
                        }
                      )
                    })
                  })
                })->List.fromArray
              })
            })
          } else {
            p(list{Attrs.class_("text-gray-400 text-sm")}, list{text("No dependencies configured")})
          }
        })
      })
    }),
    
    // Add dependency form
    if (requiredDeps->Array.length > 0 && !WizardModel.areDependenciesSatisfied(state)) {
      div(list{Attrs.class_("border border-gray-700 rounded-lg p-4")}, list{
        h4(list{Attrs.class_("font-semibold text-gray-200 mb-3")}, list{text("Add Missing Dependency")}),
        
        div(list{Attrs.class_("space-y-3")}, list{
          // Plugin selection
          div(list{}, list{
            label(list{Attrs.class_("block text-sm text-gray-400 mb-1")}, list{text("Plugin")}),
            select(
              list{
                Attrs.class_("w-full px-3 py-2 bg-gray-800 border border-gray-600 rounded text-sm"),
                Attrs.onChange(ev => {
                  let pluginId = ReactEvent.Form.target(ev)["value"]
                  // Would need state to track new dependency
                })
              },
              list{
                option(list{Attrs.value("")}, list{text("Select plugin...")}),
                requiredDeps->Array.map(depId => {
                  option(list{Attrs.value(depId)}, list{text(depId)})
                })->List.fromArray
              }
            )
          }),
          
          // Version selection
          div(list{}, list{
            label(list{Attrs.class_("block text-sm text-gray-400 mb-1")}, list{text("Version")}),
            input_(
              list{
                Attrs.class_("w-full px-3 py-2 bg-gray-800 border border-gray-600 rounded text-sm"),
                Attrs.placeholder("1.0.0")
              }
            )
          }),
          
          // Trust tier
          div(list{}, list{
            label(list{Attrs.class_("block text-sm text-gray-400 mb-1")}, list{text("Trust Tier")}),
            select(
              list{
                Attrs.class_("w-full px-3 py-2 bg-gray-800 border border-gray-600 rounded text-sm")
              },
              list{
                option(list{Attrs.value("Ayo")}, list{text("Ayo (Community)")}),
                option(list{Attrs.value("Shield")}, list{text("Shield (Security)")}),
                option(list{Attrs.value("Teranga")}, list{text("Teranga (Core)")})
              }
            )
          }),
          
          button(
            list{
              Attrs.class_("mt-3 px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700 transition"),
              Attrs.disabled(!WizardModel.canProceed(state))
            },
            list{text("Add Dependency")}
          )
        })
      })
    }
  })
}

/// Render security setup step
let renderSetupSecurity = (state: WizardModel.wizardState): Tea_Vdom.t<msg> => {
  div(list{Attrs.class_("space-y-6")}, list{
    // Step header
    h3(list{Attrs.class_("text-xl font-semibold text-gray-200")}, list{text("Setup Security")}),
    p(list{Attrs.class_("text-gray-400")}, list{text("Configure security and sandboxing for your component")}),
    
    // Trust tier selection
    div(list{Attrs.class_("border border-gray-700 rounded-lg p-4")}, list{
      h4(list{Attrs.class_("font-semibold text-gray-200 mb-3")}, list{text("Trust Tier")}),
      p(list{Attrs.class_("text-xs text-gray-400 mb-3")}, list{
        text("Select the appropriate trust level for your component")
      }),
      
      div(list{Attrs.class_("space-y-3")}, list{
        // Teranga (Core)
        button(
          list{
            Attrs.class_(`
              w-full p-4 border-2 rounded-lg text-left transition-all 
              ${state.securityConfig.trustTier === "Teranga" 
                ? "border-yellow-500 bg-yellow-900/30"
                : "border-gray-600 hover:border-gray-500"}
            `),
            Attrs.onClick(_ => Wizard(SetTrustTier("Teranga"))),
            Attrs.role("radio"),
            Attrs.ariaChecked(state.securityConfig.trustTier === "Teranga"),
          },
          list{
            div(list{Attrs.class_("flex justify-between items-center")}, list{
              div(list{}, list{
                h5(list{Attrs.class_("font-medium text-gray-200")}, list{text("Teranga - Core")}),
                p(list{Attrs.class_("text-xs text-gray-400 mt-1")}, list{
                  text("Core plugins, always available, high trust")
                }),
              }),
              if (state.securityConfig.trustTier === "Teranga") {
                span(list{Attrs.class_("text-green-400")}, list{text("✓")})
              } else {
                react.null
              }
            })
          }
        ),
        
        // Shield (Security)
        button(
          list{
            Attrs.class_(`
              w-full p-4 border-2 rounded-lg text-left transition-all 
              ${state.securityConfig.trustTier === "Shield" 
                ? "border-red-500 bg-red-900/30"
                : "border-gray-600 hover:border-gray-500"}
            `),
            Attrs.onClick(_ => Wizard(SetTrustTier("Shield"))),
            Attrs.role("radio"),
            Attrs.ariaChecked(state.securityConfig.trustTier === "Shield"),
          },
          list{
            div(list{Attrs.class_("flex justify-between items-center")}, list{
              div(list{}, list{
                h5(list{Attrs.class_("font-medium text-gray-200")}, list{text("Shield - Security")}),
                p(list{Attrs.class_("text-xs text-gray-400 mt-1")}, list{
                  text("Security-critical plugins, elevated trust")
                }),
              }),
              if (state.securityConfig.trustTier === "Shield") {
                span(list{Attrs.class_("text-green-400")}, list{text("✓")})
              } else {
                react.null
              }
            })
          }
        ),
        
        // Ayo (Community)
        button(
          list{
            Attrs.class_(`
              w-full p-4 border-2 rounded-lg text-left transition-all 
              ${state.securityConfig.trustTier === "Ayo" 
                ? "border-blue-500 bg-blue-900/30"
                : "border-gray-600 hover:border-gray-500"}
            `),
            Attrs.onClick(_ => Wizard(SetTrustTier("Ayo"))),
            Attrs.role("radio"),
            Attrs.ariaChecked(state.securityConfig.trustTier === "Ayo"),
          },
          list{
            div(list{Attrs.class_("flex justify-between items-center")}, list{
              div(list{}, list{
                h5(list{Attrs.class_("font-medium text-gray-200")}, list{text("Ayo - Community")}),
                p(list{Attrs.class_("text-xs text-gray-400 mt-1")}, list{
                  text("Community plugins, standard trust")
                }),
              }),
              if (state.securityConfig.trustTier === "Ayo") {
                span(list{Attrs.class_("text-green-400")}, list{text("✓")})
              } else {
                react.null
              }
            })
          }
        )
      })
    }),
    
    // Sandbox policy
    div(list{Attrs.class_("border border-gray-700 rounded-lg p-4")}, list{
      h4(list{Attrs.class_("font-semibold text-gray-200 mb-3")}, list{text("Sandbox Policy")}),
      p(list{Attrs.class_("text-xs text-gray-400 mb-3")}, list{
        text("Configure resource access permissions")
      }),
      
      div(list{Attrs.class_("space-y-4")}, list{
        // Network access
        div(list{Attrs.class_("flex items-center justify-between p-3 border border-gray-700 rounded")}, list{
          div(list{}, list{
            h5(list{Attrs.class_("font-medium text-gray-200")}, list{text("Network Access")}),
            p(list{Attrs.class_("text-xs text-gray-400")}, list{
              text("Allow outgoing network requests")
            }),
          }),
          label(list{Attrs.class_("relative inline-flex items-center cursor-pointer")}, list{
            input_(
              list{
                Attrs.type_("checkbox"),
                Attrs.class_("sr-only peer"),
                Attrs.checked(state.securityConfig.networkAccess),
                Attrs.onChange(_ => Wizard(ToggleNetworkAccess(!state.securityConfig.networkAccess)))
              }
            ),
            div(list{Attrs.class_("w-11 h-6 bg-gray-600 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-600")})
          })
        }),
        
        // Filesystem access
        div(list{Attrs.class_("flex items-center justify-between p-3 border border-gray-700 rounded")}, list{
          div(list{}, list{
            h5(list{Attrs.class_("font-medium text-gray-200")}, list{text("Filesystem Access")}),
            p(list{Attrs.class_("text-xs text-gray-400")}, list{
              text("Allow filesystem read/write operations")
            }),
          }),
          label(list{Attrs.class_("relative inline-flex items-center cursor-pointer")}, list{
            input_(
              list{
                Attrs.type_("checkbox"),
                Attrs.class_("sr-only peer"),
                Attrs.checked(state.securityConfig.filesystemAccess),
                Attrs.onChange(_ => Wizard(ToggleFilesystemAccess(!state.securityConfig.filesystemAccess)))
              }
            ),
            div(list{Attrs.class_("w-11 h-6 bg-gray-600 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-0.5 after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-600")})
          })
        })
      })
    }),
    
    // Capability restrictions
    div(list{Attrs.class_("border border-gray-700 rounded-lg p-4")}, list{
      h4(list{Attrs.class_("font-semibold text-gray-200 mb-3")}, list{text("Allowed Capabilities")}),
      p(list{Attrs.class_("text-xs text-gray-400 mb-3")}, list{
        text("Specify which capabilities this component can use")
      }),
      
      div(list{Attrs.class_("space-y-2 max-h-48 overflow-y-auto")}, list{
        // Would implement capability selection here
        p(list{Attrs.class_("text-gray-500 text-sm")}, list{
          text("Capability restriction UI will be implemented here")
        })
      })
    })
  })
}

/// Render review and generate step
let renderReviewAndGenerate = (state: WizardModel.wizardState): Tea_Vdom.t<msg> => {
  // Calculate summary
  let capabilityCount = state.selectedCapabilities->Array.length
  let dependencyCount = state.dependencies->Array.length
  let isPanel = state.creationType->Option.contains(WizardModel.CreatingPanel)
  
  div(list{Attrs.class_("space-y-6")}, list{
    // Step header
    h3(list{Attrs.class_("text-xl font-semibold text-gray-200")}, list{text("Review & Generate")}),
    p(list{Attrs.class_("text-gray-400")}, list{
      text(`Review your ${isPanel ? "panel" : "plugin"} configuration before generation`)
    }),
    
    // Summary cards
    div(list{Attrs.class_("grid grid-cols-1 md:grid-cols-3 gap-4")}, list{
      // Type card
      div(list{Attrs.class_("border border-gray-700 rounded-lg p-4")}, list{
        h4(list{Attrs.class_("font-semibold text-gray-200 mb-2")}, list{text("Type")}),
        p(list{Attrs.class_("text-xs text-gray-400 mb-2")}, list{
          text(isPanel ? "Panel" : "Plugin")
        }),
        p(list{Attrs.class_("text-xs text-gray-500")}, list{
          text(isPanel ? "UI component" : "Backend cartridge")
        })
      }),
      
      // Capabilities card
      div(list{Attrs.class_("border border-gray-700 rounded-lg p-4")}, list{
        h4(list{Attrs.class_("font-semibold text-gray-200 mb-2")}, list{text("Capabilities")}),
        p(list{Attrs.class_("text-xs text-gray-400 mb-2")}, list{
          text(`${capabilityCount} capabilities selected`)
        }),
        if (capabilityCount > 0) {
          ul(list{Attrs.class_("text-xs text-gray-500 mt-2 space-y-1 list-disc list-inside")}, list{
            state.selectedCapabilities
            ->Array.take(3)
            ->Array.map(capId => {
              let cap = WizardModel.capabilityRegistry->Array.find(c => c.id === capId)->Option.getExn
              li(list{}, list{text(cap.name)})
            })
            ->List.fromArray
          })
          if (capabilityCount > 3) {
            li(list{}, list{text(`... and ${capabilityCount - 3} more`)})
          } else {
            react.null
          }
        } else {
          p(list{Attrs.class_("text-xs text-gray-500 mt-2")}, list{text("No capabilities selected")})
        }
      }),
      
      // Dependencies card
      div(list{Attrs.class_("border border-gray-700 rounded-lg p-4")}, list{
        h4(list{Attrs.class_("font-semibold text-gray-200 mb-2")}, list{text("Dependencies")}),
        p(list{Attrs.class_("text-xs text-gray-400 mb-2")}, list{
          text(`${dependencyCount} dependencies configured`)
        }),
        if (dependencyCount > 0) {
          ul(list{Attrs.class_("text-xs text-gray-500 mt-2 space-y-1 list-disc list-inside")}, list{
            state.dependencies
            ->Array.take(3)
            ->Array.map(dep => {
              li(list{}, list{text(`${dep.pluginId} v${dep.version}`)})
            })
            ->List.fromArray
          })
          if (dependencyCount > 3) {
            li(list{}, list{text(`... and ${dependencyCount - 3} more`)})
          } else {
            react.null
          }
        } else {
          p(list{Attrs.class_("text-xs text-green-400 mt-2")}, list{text("No dependencies required")})
        }
      })
    }),
    
    // Security card
    div(list{Attrs.class_("border border-gray-700 rounded-lg p-4")}, list{
      h4(list{Attrs.class_("font-semibold text-gray-200 mb-2")}, list{text("Security")}),
      
      div(list{Attrs.class_("space-y-3")}, list{
        div(list{}, list{
          p(list{Attrs.class_("text-xs text-gray-400")}, list{text("Trust Tier")}),
          p(list{Attrs.class_("font-medium text-gray-200")}, list{
            text(WizardModel.trustTierLabel(state.securityConfig.trustTier))
          })
        }),
        
        div(list{}, list{
          p(list{Attrs.class_("text-xs text-gray-400")}, list{text("Network Access")}),
          p(list{Attrs.class_("font-medium text-gray-200")}, list{
            text(state.securityConfig.networkAccess ? "Enabled" : "Disabled")
          })
        }),
        
        div(list{}, list{
          p(list{Attrs.class_("text-xs text-gray-400")}, list{text("Filesystem Access")}),
          p(list{Attrs.class_("font-medium text-gray-200")}, list{
            text(state.securityConfig.filesystemAccess ? "Enabled" : "Disabled")
          })
        })
      })
    })
    
    // Validation status
    let validationErrors = WizardModel.validateWizardConfig(state)
    div(list{Attrs.class_("border border-gray-700 rounded-lg p-4")}, list{
      h4(list{Attrs.class_("font-semibold text-gray-200 mb-3")}, list{text("Validation")}),
      
      if (validationErrors->Array.length === 0) {
        div(list{Attrs.class_("text-green-400")}, list{
          span(list{Attrs.class_("mr-2")}, list{text("✓")}),
          text("All checks passed - ready to generate!")
        })
      } else {
        div(list{Attrs.class_("text-red-400")}, list{
          span(list{Attrs.class_("mr-2")}, list{text("✗")}),
          text("Please fix the following issues:")
        })
        ul(list{Attrs.class_("text-red-300 text-sm mt-2 list-disc list-inside")}, list{
          validationErrors->Array.map(error => {
            li(list{}, list{text(error)})
          })->List.fromArray
        })
      }
    }),
    
    // Generate button
    button(
      list{
        Attrs.class_("mt-6 w-full px-6 py-3 bg-green-600 text-white rounded hover:bg-green-700 transition disabled:opacity-50 disabled:cursor-not-allowed"),
        Attrs.disabled(validationErrors->Array.length > 0 || state.generating),
        Events.onClick(_ => Wizard(StartGeneration)),
      },
      list{
        if (state.generating) {
          span(list{Attrs.class_("mr-2")}, list{text("Generating")})
          // Would add spinner here in real implementation
          text("...")
        } else {
          text("Generate Component")
        }
      }
    )
  })
}
