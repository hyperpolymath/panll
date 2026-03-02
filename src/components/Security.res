// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Security Panel — redaction, vault, 2FA, Trustfile, shoulder-safe (DD-026/027).
///
/// This is the security command centre. It shows detected secrets, vault status,
/// 2FA state, and Trustfile compliance. The shoulder-safe mode blurs secrets
/// in real-time for when someone's looking over your shoulder.

open Model
open Msg
open Tea.Html

/// Render a status indicator (coloured dot + label).
let renderStatus = (label: string, ok: bool, tooltip: string): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("flex items-center gap-2"),
      Attrs.title(tooltip),
    },
    list{
      div(
        list{Attrs.class_(`w-2 h-2 rounded-full ${ok ? "bg-green-500" : "bg-red-500"}`)},
        list{},
      ),
      div(list{Attrs.class_("text-xs text-gray-400")}, list{text(label)}),
    },
  )
}

/// Render the redaction patterns section.
let renderPatterns = (security: securityState): Tea_Vdom.t<msg> => {
  div(
    list{Attrs.class_("space-y-2")},
    Array.map(security.patterns, pattern =>
      div(
        list{
          Attrs.class_(`flex items-center justify-between p-2 rounded ${
            pattern.enabled ? "bg-gray-800" : "bg-gray-900"
          } hover:bg-gray-700/50 transition-colors cursor-pointer`),
          Events.onClick(Security(TogglePattern(pattern.id))),
          Attrs.title(`Regex: ${pattern.pattern}`),
        },
        list{
          div(
            list{Attrs.class_("flex items-center gap-2")},
            list{
              div(
                list{Attrs.class_(`w-2 h-2 rounded-full ${pattern.enabled ? "bg-green-500" : "bg-gray-600"}`)},
                list{},
              ),
              div(list{Attrs.class_("text-xs text-gray-300")}, list{text(pattern.label)}),
              if pattern.builtIn {
                div(list{Attrs.class_("text-xs text-gray-600")}, list{text("built-in")})
              } else {
                div(list{Attrs.class_("text-xs text-blue-600")}, list{text("custom")})
              },
            },
          ),
        },
      )
    )->List.fromArray,
  )
}

/// Render the vault section.
let renderVault = (security: securityState): Tea_Vdom.t<msg> => {
  let statusLabel = switch security.vaultStatus {
  | VaultLocked => "Locked"
  | VaultUnlocked => "Unlocked"
  | VaultUnavailable => "Unavailable"
  | VaultError(e) => "Error: " ++ e
  }
  let isOk = switch security.vaultStatus {
  | VaultUnlocked => true
  | _ => false
  }
  div(
    list{Attrs.class_("space-y-3")},
    list{
      renderStatus("Vault: " ++ statusLabel, isOk, "reasonably-good-tool vault integration"),
      div(
        list{Attrs.class_("text-xs text-gray-500")},
        list{text(Int.toString(Array.length(security.vaultKeys)) ++ " keys stored")},
      ),
      button(
        list{
          Attrs.class_("px-3 py-1 bg-gray-800 text-gray-400 rounded text-xs hover:bg-gray-700 transition-colors"),
          Events.onClick(Security(VaultList)),
          Attrs.title("List all keys in the vault (names only, never values)"),
        },
        list{text("List Keys")},
      ),
    },
  )
}

/// Render the 2FA section.
let render2FA = (security: securityState): Tea_Vdom.t<msg> => {
  let statusLabel = switch security.twoFactorStatus {
  | TwoFactorNotConfigured => "Not configured"
  | TwoFactorConfigured => "Configured (not authenticated)"
  | TwoFactorAuthenticated(_) => "Authenticated"
  | TwoFactorExpired => "Session expired"
  }
  let isOk = switch security.twoFactorStatus {
  | TwoFactorAuthenticated(_) => true
  | _ => false
  }
  div(
    list{Attrs.class_("space-y-3")},
    list{
      renderStatus("2FA: " ++ statusLabel, isOk, "TOTP-based two-factor authentication (RFC 6238)"),
      div(
        list{Attrs.class_("flex gap-2")},
        list{
          input(
            list{
              Attrs.class_("flex-1 bg-gray-800 text-gray-200 text-sm p-2 rounded border border-gray-700 focus:border-blue-600 focus:outline-none"),
              Attrs.placeholder("Enter 6-digit TOTP code"),
              Attrs.value(security.totpInput),
              Events.onInput(v => Security(SetTotpInput(v))),
            },
            list{},
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 bg-blue-700 text-white rounded text-sm hover:bg-blue-600 transition-colors"),
              Events.onClick(Security(SubmitTotp(security.totpInput))),
            },
            list{text("Verify")},
          ),
        },
      ),
    },
  )
}

/// Full Security panel view.
let view = (security: securityState): Tea_Vdom.t<msg> => {
  div(
    list{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 overflow-auto"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("Security panel"),
    },
    list{
      // Header
      div(
        list{Attrs.class_("sticky top-0 bg-gray-950 border-b border-gray-800 p-4 flex items-center justify-between z-10")},
        list{
          div(
            list{Attrs.class_("flex items-center gap-4")},
            list{
              div(list{Attrs.class_("text-lg font-light text-gray-300")}, list{text("Security")}),
              // Shoulder-safe toggle
              button(
                list{
                  Attrs.class_(`px-3 py-1 rounded text-xs font-medium ${
                    security.shoulderSafe ? "bg-red-700 text-white" : "bg-gray-800 text-gray-400"
                  } hover:opacity-80 transition-opacity`),
                  Events.onClick(Security(ToggleShoulderSafe)),
                  Attrs.title("Toggle shoulder-surfing safe mode — blurs detected secrets in real-time"),
                },
                list{text(security.shoulderSafe ? "Shoulder-Safe ON" : "Shoulder-Safe OFF")},
              ),
              div(
                list{Attrs.class_("text-xs text-gray-500")},
                list{text(Int.toString(Array.length(security.detectedSecrets)) ++ " secrets detected")},
              ),
            },
          ),
          button(
            list{
              Attrs.class_("px-3 py-1 bg-gray-800 text-gray-400 rounded hover:bg-gray-700 transition-colors text-sm"),
              Events.onClick(PanelSwitcher(ClosePanels)),
            },
            list{text("Close")},
          ),
        },
      ),

      // Body: three-column layout
      div(
        list{Attrs.class_("p-6 grid grid-cols-3 gap-6 max-w-6xl mx-auto")},
        list{
          // Column 1: Redaction patterns
          div(
            list{Attrs.class_("space-y-4")},
            list{
              div(
                list{Attrs.class_("text-sm font-medium text-gray-400 border-b border-gray-800 pb-1")},
                list{text("Redaction Patterns")},
              ),
              renderPatterns(security),
            },
          ),
          // Column 2: Vault
          div(
            list{Attrs.class_("space-y-4")},
            list{
              div(
                list{Attrs.class_("text-sm font-medium text-gray-400 border-b border-gray-800 pb-1")},
                list{text("Vault (reasonably-good-tool)")},
              ),
              renderVault(security),
            },
          ),
          // Column 3: 2FA + Trustfile
          div(
            list{Attrs.class_("space-y-4")},
            list{
              div(
                list{Attrs.class_("text-sm font-medium text-gray-400 border-b border-gray-800 pb-1")},
                list{text("Two-Factor Authentication")},
              ),
              render2FA(security),
              div(
                list{Attrs.class_("mt-6 text-sm font-medium text-gray-400 border-b border-gray-800 pb-1")},
                list{text("Trustfile Policy")},
              ),
              switch security.trustfile {
              | Some(policy) =>
                div(
                  list{Attrs.class_("space-y-1")},
                  list{
                    renderStatus("Trustfile loaded", policy.loaded, "Loaded from " ++ Option.getOr(policy.filePath, "unknown")),
                    div(list{Attrs.class_("text-xs text-gray-500")},
                      list{text("Security level: " ++ switch policy.securityLevel {
                      | SecurityLow => "Low"
                      | SecurityMedium => "Medium"
                      | SecurityHigh => "High"
                      | SecurityMaximum => "Maximum"
                      })},
                    ),
                  },
                )
              | None =>
                div(
                  list{
                    Attrs.class_("p-3 bg-gray-900/50 rounded border border-gray-800 text-xs text-gray-600"),
                    Attrs.title("Load a repo with a Trustfile.a2ml to enable policy enforcement"),
                  },
                  list{text("No Trustfile loaded — load a repo to enable policy enforcement")},
                )
              },
            },
          ),
        },
      ),
    },
  )
}
