// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL Security Commands — Tauri IPC wrappers for redaction, vault,
/// 2FA, and Trustfile operations (DD-026, DD-027).
///
/// Each function returns a Tea_Cmd that dispatches a result message
/// back into the update loop via `callbacks.enqueue`.

open Msg

/// External binding to Tauri's invoke function.
@module("@tauri-apps/api/core")
external invoke: (string, 'a) => promise<string> = "invoke"

/// Redact secrets from text using backend regex patterns.
let redactText = (text: string, panelId: string, patternsJson: string): Tea_Cmd.t<msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("redact_text", {
      "text": text,
      "panelId": panelId,
      "patternsJson": patternsJson,
    })
    ->Promise.then(result => {
      callbacks.enqueue(Security(RedactionResult(Ok(result))))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(Security(RedactionResult(Error("Failed to redact text"))))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Store a secret in the vault.
let vaultStore = (key: string, value: string): Tea_Cmd.t<msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("vault_store", {
      "key": key,
      "value": value,
    })
    ->Promise.then(result => {
      callbacks.enqueue(Security(VaultStoreResult(Ok(result))))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(Security(VaultStoreResult(Error("Failed to store in vault"))))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Retrieve a secret from the vault.
let vaultRetrieve = (key: string): Tea_Cmd.t<msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("vault_retrieve", {"key": key})
    ->Promise.then(result => {
      callbacks.enqueue(Security(VaultRetrieveResult(Ok(result))))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(Security(VaultRetrieveResult(Error("Failed to retrieve from vault"))))
      Promise.resolve()
    })
    ->ignore
  })
}

/// List all keys in the vault.
let vaultList = (): Tea_Cmd.t<msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("vault_list", ())
    ->Promise.then(result => {
      callbacks.enqueue(Security(VaultListResult(Ok(result))))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(Security(VaultListResult(Error("Failed to list vault keys"))))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Load and parse a Trustfile from the given repo path.
let loadTrustfile = (repoPath: string): Tea_Cmd.t<msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("load_trustfile", {"repoPath": repoPath})
    ->Promise.then(result => {
      callbacks.enqueue(Security(TrustfileLoaded(Ok(result))))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(Security(TrustfileLoaded(Error("Failed to load Trustfile"))))
      Promise.resolve()
    })
    ->ignore
  })
}
