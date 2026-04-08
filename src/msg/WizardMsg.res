// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Wizard Messages — User actions for the plugin/panel creation wizard.

open Model

type wizardMsg =
  /// Set creation type (panel or plugin)
  | SetCreationType(creationType)
  /// Apply template to wizard
  | ApplyTemplate(string)
  /// Toggle capability selection
  | ToggleCapability(string)
  /// Add dependency
  | AddDependency(string, string)
  /// Remove dependency
  | RemoveDependency(string)
  /// Set trust tier
  | SetTrustTier(pluginTrustTier)
  /// Toggle network access
  | ToggleNetworkAccess(bool)
  /// Toggle filesystem access
  | ToggleFilesystemAccess(bool)
  /// Proceed to next step
  | NextStep
  /// Go back to previous step
  | PreviousStep
  /// Start generation
  | StartGeneration
  /// Generation result
  | GenerationResult(result<string, string>)
  /// Validation result
  | ValidationResult(result<string, string>)
  /// Reset wizard
  | ResetWizard
  
  /// Test messages
  | RunWizardTests
  | TestResults(string)
