// SPDX-License-Identifier: PMPL-1.0-or-later
open Model
open Msg
open WizardCmd
open WizardTest
open WizardMinter

/// Client-side validation rules for immediate feedback
let validateCapabilitySelection = (capId: string, selectedCaps: array<string>): option<string> => {
  // Define capability conflicts
  let conflicts: dict<string, array<string>> = Dict.fromArray(list{
    ("groove_hard", ["groove_soft"]), // Hard groove conflicts with soft groove
    ("groove_soft", ["groove_hard"]),
    ("contractile_strict", ["contractile_permissive"]),
    ("contractile_permissive", ["contractile_strict"]),
  })
  
  switch Dict.get(conflicts, capId) {
  | Some(conflictingCaps) => {
      // Check if any conflicting capabilities are already selected
      let hasConflict = conflictingCaps->Array.exists(conflictCap => 
        selectedCaps->Array.exists(selected => selected === conflictCap)
      )
      if hasConflict {
        Some(`Cannot select ${capId}: conflicts with ${conflictingCaps->Array.join(", ")}`)
      } else {
        None
      }
    }
  | None => None
  }
}

let validateDependency = (pluginId: string, version: string, dependencies: array<pluginDependency>): option<string> => {
  // Check for duplicate dependencies
  let hasDuplicate = dependencies->Array.exists(dep => dep.pluginId === pluginId)
  if hasDuplicate {
    Some(`Dependency ${pluginId} already added`)
  } else if String.length(pluginId) === 0 {
    Some("Plugin ID cannot be empty")
  } else if String.length(version) === 0 {
    Some("Version cannot be empty")
  } else {
    None
  }
}

let validateSecurityConfig = (config: securityConfig): option<string> => {
  // Check for high trust tier with dangerous permissions
  if config.trustTier === Ayo && (config.networkAccess || config.filesystemAccess) {
    Some("High trust tier (Ayo) should not have network/filesystem access")
  } else {
    None
  }
}

/// Convert wizard state to JSON strings for backend communication
let serializeWizardConfig = (wizard: wizardState) => {
  let creationTypeStr = switch wizard.creationType {
    | Some(CreatingPanel) => "panel"
    | Some(CreatingPlugin) => "plugin"
    | None => "unknown"
  }
  
  let capabilitiesJson = 
    wizard.selectedCapabilities
    ->Array.map(cap => `"${cap}"`)
    ->Array.join(",")
    ->str => `[${str}]`
  
  let dependenciesJson = 
    wizard.dependencies
    ->Array.map(dep => `{"id":"${dep.pluginId}","version":"${dep.version}"}`)
    ->Array.join(",")
    ->str => `[${str}]`
  
  let securityJson = `{
    "trustTier":"${wizard.securityConfig.trustTier->pluginTrustTierToString}",
    "sandboxPolicy":"${wizard.securityConfig.sandboxPolicy->sandboxPolicyToString}",
    "networkAccess":${Belt.Bool.toString(wizard.securityConfig.networkAccess)},
    "filesystemAccess":${Belt.Bool.toString(wizard.securityConfig.filesystemAccess)}
  }`
  
  {
    creationType: creationTypeStr,
    capabilities: capabilitiesJson,
    dependencies: dependenciesJson,
    securityConfig: securityJson,
  }
  let creationTypeStr = switch wizard.creationType {
    | Some(CreatingPanel) => "panel"
    | Some(CreatingPlugin) => "plugin"
    | None => "unknown"
  }
  
  let capabilitiesJson = 
    wizard.selectedCapabilities
    ->Array.map(cap => `"${cap}"`)
    ->Array.join(",")
    ->str => `[${str}]`
  
  let dependenciesJson = 
    wizard.dependencies
    ->Array.map(dep => `{"id":"${dep.pluginId}","version":"${dep.version}"}`)
    ->Array.join(",")
    ->str => `[${str}]`
  
  let securityJson = `{
    "trustTier":"${wizard.securityConfig.trustTier->pluginTrustTierToString}",
    "sandboxPolicy":"${wizard.securityConfig.sandboxPolicy->sandboxPolicyToString}",
    "networkAccess":${Belt.Bool.toString(wizard.securityConfig.networkAccess)},
    "filesystemAccess":${Belt.Bool.toString(wizard.securityConfig.filesystemAccess)}
  }`
  
  {
    creationType: creationTypeStr,
    capabilities: capabilitiesJson,
    dependencies: dependenciesJson,
    securityConfig: securityJson,
  }

module UpdateWizard = {
  let update = (model: model, msg: wizardMsg): (model, Tea_Cmd.t<msg>) => {
    switch msg {
    | SetCreationType(creationType) =>
        let newWizardState = {...model.wizard, creationType: Some(creationType)}
        ({...model, wizard: newWizardState}, Tea_Cmd.none)

    | ApplyTemplate(templateName) => {
        switch WizardModel.getTemplateByName(templateName) {
        | Some(template) =>
            let newWizardState = WizardModel.applyTemplate(template, model.wizard)
            ({...model, wizard: newWizardState}, Tea_Cmd.none)
        | None =>
            // Template not found, show error
            let newWizardState = {
              ...model.wizard,
              validationErrors: Some(`Template "${templateName}" not found`)
            }
            ({...model, wizard: newWizardState}, Tea_Cmd.none)
        }
      }

    | ToggleCapability(capId) => {
        // Validate capability selection before updating state
        let validationError = validateCapabilitySelection(capId, model.wizard.selectedCapabilities)
        
        switch validationError {
        | Some(errorMsg) =>
            // Show validation error but don't change selection
            let newWizardState = {
              ...model.wizard,
              validationErrors: Some(errorMsg)
            }
            ({...model, wizard: newWizardState}, Tea_Cmd.none)
        | None =>
            // Selection is valid, proceed with toggle
            let newWizardState = WizardModel.toggleCapability(capId, model.wizard)
            ({...model, wizard: {...newWizardState, validationErrors: None}}, Tea_Cmd.none)
        }
      }

    | AddDependency(pluginId, version) => {
        // Validate dependency before adding
        let validationError = validateDependency(pluginId, version, model.wizard.dependencies)
        
        switch validationError {
        | Some(errorMsg) =>
            // Show validation error but don't add dependency
            let newWizardState = {
              ...model.wizard,
              validationErrors: Some(errorMsg)
            }
            ({...model, wizard: newWizardState}, Tea_Cmd.none)
        | None =>
            // Dependency is valid, proceed with addition
            let newWizardState = WizardModel.addDependency(pluginId, version, model.wizard)
            ({...model, wizard: {...newWizardState, validationErrors: None}}, Tea_Cmd.none)
        }
      }

    | RemoveDependency(pluginId) =>
        let newWizardState = {
          ...model.wizard,
          dependencies: model.wizard.dependencies->Array.filter(dep => dep.pluginId !== pluginId)
        }
        ({...model, wizard: newWizardState}, Tea_Cmd.none)

    | SetTrustTier(tier) =>
        let newSecurityConfig = {...model.wizard.securityConfig, trustTier: tier}
        let newWizardState = {...model.wizard, securityConfig: newSecurityConfig}
        ({...model, wizard: newWizardState}, Tea_Cmd.none)

    | ToggleNetworkAccess(enabled) => {
        let newSecurityConfig = {...model.wizard.securityConfig, networkAccess: enabled}
        let newWizardState = {...model.wizard, securityConfig: newSecurityConfig}
        
        // Validate security configuration after change
        let validationError = validateSecurityConfig(newSecurityConfig)
        
        switch validationError {
        | Some(errorMsg) =>
            ({...model, wizard: {...newWizardState, validationErrors: Some(errorMsg)}}, Tea_Cmd.none)
        | None =>
            ({...model, wizard: {...newWizardState, validationErrors: None}}, Tea_Cmd.none)
        }
      }

    | ToggleFilesystemAccess(enabled) => {
        let newSecurityConfig = {...model.wizard.securityConfig, filesystemAccess: enabled}
        let newWizardState = {...model.wizard, securityConfig: newSecurityConfig}
        
        // Validate security configuration after change
        let validationError = validateSecurityConfig(newSecurityConfig)
        
        switch validationError {
        | Some(errorMsg) =>
            ({...model, wizard: {...newWizardState, validationErrors: Some(errorMsg)}}, Tea_Cmd.none)
        | None =>
            ({...model, wizard: {...newWizardState, validationErrors: None}}, Tea_Cmd.none)
        }
      }

    | NextStep => {
        let nextStep = WizardModel.getNextStep(model.wizard.currentStep)
        // Clear validation errors when moving to next step
        let newWizardState = {
          ...model.wizard,
          currentStep: nextStep,
          validationErrors: None
        }
        ({...model, wizard: newWizardState}, Tea_Cmd.none)
      }

    | PreviousStep => {
        let prevStep = WizardModel.getPreviousStep(model.wizard.currentStep)
        // Clear validation errors when moving to previous step
        let newWizardState = {
          ...model.wizard,
          currentStep: prevStep,
          validationErrors: None
        }
        ({...model, wizard: newWizardState}, Tea_Cmd.none)
      }

    | StartGeneration =>
        // Validate configuration before generation
        let config = serializeWizardConfig(model.wizard)
        (
          {
            ...model,
            wizard: {
              ...model.wizard,
              generating: true,
              validationErrors: None,
              generationResult: None,
            },
          },
          Tea_Cmd.batch(list{
            WizardCmd.validateConfig(
              config.creationType,
              config.capabilities,
              config.dependencies,
              result => Wizard(ValidationResult(result)),
            ),
            // Start actual generation after validation
            WizardCmd.generate(
              config.creationType,
              config.capabilities,
              config.dependencies,
              config.securityConfig,
              result => Wizard(GenerationResult(result)),
            ),
          }),
        )

    | ValidationResult(result) =>
        switch result {
        | Ok(_validationJson) =>
            // Validation passed, continue with generation
            ({...model, wizard: {...model.wizard, validationErrors: None}}, Tea_Cmd.none)
        | Error(errorMsg) =>
            // Validation failed, stop generation
            let newWizardState = {
              ...model.wizard,
              generating: false,
              validationErrors: Some(errorMsg),
            }
            ({...model, wizard: newWizardState}, Tea_Cmd.none)
        }

    | GenerationResult(result) =>
        switch result {
        | Ok(generationJson) =>
            let newWizardState = {
              ...model.wizard,
              generating: false,
              generationResult: Some(Ok(generationJson)),
            }
            ({...model, wizard: newWizardState}, Tea_Cmd.none)
        | Error(errorMsg) =>
            let newWizardState = {
              ...model.wizard,
              generating: false,
              generationResult: Some(Error(errorMsg)),
            }
            ({...model, wizard: newWizardState}, Tea_Cmd.none)
        }

    | ResetWizard =>
        ({...model, wizard: WizardModel.defaultWizardState}, Tea_Cmd.none)
    
    | RunWizardTests => {
        let cmd = WizardTest.runTests(result => Wizard(TestResults(result)))
        (model, cmd)
      }
    
    | TestResults(report) => {
        let newWizardState = {
          ...model.wizard,
          testResults: Some({
            report,
            timestamp: Date.now(),
          })
        }
        ({...model, wizard: newWizardState}, Tea_Cmd.none)
      }
    }
  }
}