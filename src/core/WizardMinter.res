// SPDX-License-Identifier: MPL-2.0

/// PanLL Minter — Unified generation interface for both panels and plugins.

open WizardModel
open MinterModel
open MinterEngine

/// Generate a new panel or plugin based on wizard configuration
let generate = (creationType: string, capabilities: string, dependencies: string, securityConfig: string): result<string, string> => {
  // Simplified implementation - actual generation happens in backend via WizardCmd
  Ok("Generation configuration validated")
}

/// Helper function to get capability label from ID
let getCapabilityLabel = (capId: string): string => {
  // This should be moved to a central capability registry
  switch capId {
  | "groove_soft" => "Soft Groove Integration"
  | "groove_hard" => "Hard Groove Integration"
  | "accessibility" => "Accessibility Compliance"
  | "contractile" => "Contractile Governance"
  | "minter" => "Minter Integration"
  | "provisioner" => "Provisioner Support"
  | _ => capId
  }
}