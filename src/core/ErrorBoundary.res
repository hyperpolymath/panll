// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

/// ErrorBoundary — Standardized error handling for Gossamer command dispatch.
///
/// Wraps RuntimeBridge.invoke with structured error capture and TEA message
/// dispatch. When a command fails, the error is captured as a result type
/// and routed through the normal TEA update cycle rather than crashing.
///
/// New command modules (ServiceCmd, SettingsCmd, IdentityCmd) use this
/// pattern. Existing commands can adopt incrementally.
///
/// Part of Connected Workbench v0.2.0.

/// Extract a human-readable error message from a JavaScript exception.
///
/// Handles the common case where the caught value is an Error object
/// with a `.message` property, as well as plain string rejections.
let extractErrorMessage: exn => string = %raw(`
  function(err) {
    if (err && typeof err === 'object' && typeof err.message === 'string') {
      return err.message;
    }
    if (typeof err === 'string') {
      return err;
    }
    return 'Unknown error';
  }
`)

/// Invoke a Gossamer command with error boundary protection.
///
/// On success: calls tagger with `Ok(result)`.
/// On failure: calls tagger with `Error(contextMessage: detailMessage)`.
/// Never throws — all exceptions are caught and routed through the tagger.
///
/// @param cmd        The Gossamer command name (e.g. "verisimdb_health")
/// @param args       The command payload (any JSON-serializable value)
/// @param context    Human-readable context for error messages (e.g. "VeriSimDB health check")
/// @param tagger     TEA message constructor for the result
let invokeWithBoundary = (
  cmd: string,
  args: 'a,
  context: string,
  tagger: result<'b, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    RuntimeBridge.invoke(cmd, args)
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(err => {
      let detail = extractErrorMessage(err)
      callbacks.enqueue(tagger(Error(context ++ ": " ++ detail)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Fire-and-forget variant — logs errors to Console.warn, no TEA message.
///
/// Use for operations where failure is acceptable and does not need
/// to be reflected in the UI (e.g. background telemetry, cache warming).
///
/// @param cmd      The Gossamer command name
/// @param args     The command payload
/// @param context  Human-readable context for warning messages
let invokeFireAndForget = (cmd: string, args: 'a, context: string): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(_callbacks => {
    RuntimeBridge.invoke(cmd, args)
    ->Promise.catch(err => {
      let detail = extractErrorMessage(err)
      Console.warn(context ++ ": " ++ detail)
      Promise.resolve()
    })
    ->ignore
  })
}

/// Invoke with a timeout boundary.
///
/// Wraps a Gossamer command with a client-side timeout. If the command
/// does not respond within `timeoutMs` milliseconds, the tagger receives
/// an Error with a timeout message. The backend request may still complete
/// (this is a client-side optimistic abort, not a cancellation).
///
/// @param cmd        The Gossamer command name
/// @param args       The command payload
/// @param context    Human-readable context for error messages
/// @param timeoutMs  Maximum wait time in milliseconds
/// @param tagger     TEA message constructor for the result
let invokeWithTimeout = (
  cmd: string,
  args: 'a,
  context: string,
  timeoutMs: int,
  tagger: result<'b, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let resolved = ref(false)

    // Start the actual invoke
    RuntimeBridge.invoke(cmd, args)
    ->Promise.then(result => {
      if !resolved.contents {
        resolved := true
        callbacks.enqueue(tagger(Ok(result)))
      }
      Promise.resolve()
    })
    ->Promise.catch(err => {
      if !resolved.contents {
        resolved := true
        let detail = extractErrorMessage(err)
        callbacks.enqueue(tagger(Error(context ++ ": " ++ detail)))
      }
      Promise.resolve()
    })
    ->ignore

    // Timeout guard
    let _ = setTimeout(() => {
      if !resolved.contents {
        resolved := true
        callbacks.enqueue(tagger(Error(context ++ ": timed out after " ++ Int.toString(timeoutMs) ++ "ms")))
      }
    }, timeoutMs)
  })
}
