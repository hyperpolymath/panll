// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL TypeLL Commands — Tauri wrappers for the verification kernel.
///
/// TypeLL exposes a JSON-RPC-style API at TYPELL_URL (default http://localhost:7800/api/v1).
/// These bindings wrap the 7 Tauri commands defined in src-tauri/src/typell/commands.rs.
///
/// Unlike most panels which are self-contained, TypeLL commands are also called
/// by other panels through TypeLLService — making TypeLL a cross-cutting concern.

@module("@tauri-apps/api/core")
external invoke: (string, 'a) => promise<'b> = "invoke"

/// Check TypeLL server health.
let health = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("typell_health", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("TypeLL server not reachable")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Type-check an expression with optional context.
/// POST /check — bidirectional type checking with full feature detection.
let check = (
  expression: string,
  context: option<string>,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  let args = switch context {
  | Some(ctx) => {"expression": expression, "context": ctx}
  | None => {"expression": expression, "context": ""}
  }
  Tea_Cmd.call(callbacks => {
    invoke("typell_check", args)
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Type checking failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Infer the type of an expression.
/// POST /infer — returns the most general type.
let infer = (expression: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("typell_infer", {"expression": expression})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Type inference failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Apply refinement types to a specification.
/// POST /refine — narrows a type with constraints.
let refine = (
  spec: string,
  constraints: option<string>,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  let args = switch constraints {
  | Some(c) => {"spec": spec, "constraints": c}
  | None => {"spec": spec, "constraints": ""}
  }
  Tea_Cmd.call(callbacks => {
    invoke("typell_refine", args)
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Refinement failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Evaluate a type-level computation.
/// POST /compute — evaluates normalisation, unification, etc.
let compute = (term: string, tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("typell_compute", {"term": term})
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Type computation failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// List available type signatures from the server.
/// GET /signatures — returns the signature catalogue.
let listSignatures = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("typell_list_signatures", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to list signatures")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Get the type universe hierarchy.
/// GET /universes — returns the hierarchy of type universes.
let universes = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    invoke("typell_universes", ())
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Failed to get universes")))
      Promise.resolve()
    })
    ->ignore
  })
}
