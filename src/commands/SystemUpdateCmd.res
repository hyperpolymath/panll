// SPDX-License-Identifier: MPL-2.0

/// SystemUpdateCmd — TEA command wrappers for system update backend operations.
///
/// Each function wraps a backend command handler from
/// `src-gossamer/src/system_update/commands.rs`, using the `Tea_Cmd.call` pattern
/// to bridge async backend invocations into the TEA update loop.
///
/// Pattern:
///   1. Call `invoke("system_update_*", params)` → returns Promise
///   2. On success: `callbacks.enqueue(tagger(Ok(jsonString)))`
///   3. On failure: `callbacks.enqueue(tagger(Error(errorMessage)))`

/// Backend invoke binding via RuntimeBridge.
let invoke = RuntimeBridge.invoke

// ============================================================================
// Component listing
// ============================================================================

/// List all updatable components with current/latest versions.
/// Returns: JSON array of component objects.
let listComponents = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("system_update_list_components", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to list system components")))
      Promise.resolve()
    })
    ->ignore
  })
}

// ============================================================================
// Update checking
// ============================================================================

/// Check all components for available updates.
/// Returns: JSON with summary and components array.
let checkAll = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("system_update_check_all", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to check for updates")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Check a single component for updates by ID.
/// Returns: JSON component object.
let checkComponent = (componentId: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("system_update_check_component", {"component_id": componentId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to check component: " ++ componentId)))
      Promise.resolve()
    })
    ->ignore
  })
}

// ============================================================================
// Update application
// ============================================================================

/// Apply update to a single component by ID.
/// Returns: JSON with success/output fields.
let applyComponent = (componentId: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("system_update_apply_component", {"component_id": componentId})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to apply update: " ++ componentId)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Apply all available updates in sequence.
/// Returns: JSON with success/applied/failed/summary fields.
let applyAll = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("system_update_apply_all", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to apply all updates")))
      Promise.resolve()
    })
    ->ignore
  })
}

// ============================================================================
// asdf details
// ============================================================================

/// Get detailed asdf plugin status (all 33+ plugins).
/// Returns: JSON array of {plugin, installed, latest}.
let asdfStatus = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("system_update_asdf_status", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to get asdf status")))
      Promise.resolve()
    })
    ->ignore
  })
}

// ============================================================================
// Logs and summary
// ============================================================================

/// Get update log history.
/// Returns: JSON array of {timestamp, summary}.
let logs = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("system_update_logs", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to get update logs")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Get last update run summary.
/// Returns: JSON with summary text.
let lastSummary = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("system_update_last_summary", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to get last summary")))
      Promise.resolve()
    })
    ->ignore
  })
}
