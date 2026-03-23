// SPDX-License-Identifier: PMPL-1.0-or-later

/// PanLL TypeLL Commands — Backend wrappers for the verification kernel.
///
/// TypeLL exposes a JSON-RPC-style API at TYPELL_URL (default http://localhost:7800/api/v1).
/// These bindings wrap the 7 backend commands defined in src-gossamer/src/typell/commands.rs.
///
/// In browser-only mode (no desktop runtime), commands fall back to direct
/// fetch() calls against the TypeLL server URL.
///
/// Unlike most panels which are self-contained, TypeLL commands are also called
/// by other panels through TypeLLService — making TypeLL a cross-cutting concern.


let hasDesktopRuntime = RuntimeBridge.hasDesktopRuntime

/// GET helper for TypeLL direct fetch (bypasses backend invoke).
let fetchGet: string => promise<string> = %raw(`
  function(path) {
    return fetch("http://localhost:7800/api/v1" + path)
      .then(function(r) {
        if (!r.ok) throw new Error("TypeLL returned " + r.status);
        return r.text();
      });
  }
`)

/// POST helper for TypeLL direct fetch (bypasses backend invoke).
let fetchPost: (string, string) => promise<string> = %raw(`
  function(path, body) {
    return fetch("http://localhost:7800/api/v1" + path, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: body
    }).then(function(r) {
      if (!r.ok) throw new Error("TypeLL returned " + r.status);
      return r.text();
    });
  }
`)

/// Check TypeLL server health.
let health = (tagger: result<string, string> => 'msg): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let p = if hasDesktopRuntime() {
      RuntimeBridge.invoke("typell_health", ())
    } else {
      fetchGet("/health")
    }
    p
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
  let ctx = context->Option.getOr("")
  Tea_Cmd.call(callbacks => {
    let p = if hasDesktopRuntime() {
      RuntimeBridge.invoke("typell_check", {"expression": expression, "context": ctx})
    } else {
      fetchPost("/check", `{"expression":${JSON.stringifyAny(expression)->Option.getOr("\"\"")}, "context":${JSON.stringifyAny(ctx)->Option.getOr("{}")}}`)
    }
    p
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
    let p = if hasDesktopRuntime() {
      RuntimeBridge.invoke("typell_infer", {"expression": expression})
    } else {
      fetchPost("/infer", `{"expression":${JSON.stringifyAny(expression)->Option.getOr("\"\"")}}`)
    }
    p
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
  let cons = constraints->Option.getOr("")
  Tea_Cmd.call(callbacks => {
    let p = if hasDesktopRuntime() {
      RuntimeBridge.invoke("typell_refine", {"spec": spec, "constraints": cons})
    } else {
      fetchPost("/refine", `{"spec":${JSON.stringifyAny(spec)->Option.getOr("\"\"")}, "constraints":${JSON.stringifyAny(cons)->Option.getOr("[]")}}`)
    }
    p
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
    let p = if hasDesktopRuntime() {
      RuntimeBridge.invoke("typell_compute", {"term": term})
    } else {
      fetchPost("/compute", `{"term":${JSON.stringifyAny(term)->Option.getOr("\"\"")}}`)
    }
    p
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
    let p = if hasDesktopRuntime() {
      RuntimeBridge.invoke("typell_list_signatures", ())
    } else {
      fetchGet("/signatures")
    }
    p
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
    let p = if hasDesktopRuntime() {
      RuntimeBridge.invoke("typell_universes", ())
    } else {
      fetchGet("/universes")
    }
    p
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

// ============================================================================
// New Kernel Integration — localhost:7800 routed operations
// ============================================================================

/// Route a type check to the kernel with a specific language target.
/// POST /check — sends source + language to the kernel for type checking.
let checkType = (
  source: string,
  language: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let body = TypeLLEngine.buildCheckBody(source, language)
    let p = if hasDesktopRuntime() {
      RuntimeBridge.invoke("typell_check", {"expression": source, "context": language})
    } else {
      fetchPost("/check", body)
    }
    p
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Kernel type check failed for " ++ language)))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Infer usage quantifiers (linear/affine/unrestricted) for an expression.
/// POST /infer-usage — returns QTT quantifier annotations.
let inferUsage = (
  source: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let body = TypeLLEngine.buildInferUsageBody(source)
    let p = if hasDesktopRuntime() {
      RuntimeBridge.invoke("typell_infer", {"expression": source})
    } else {
      fetchPost("/infer-usage", body)
    }
    p
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Usage inference failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Infer effects for an expression.
/// POST /check-effects — returns effect list and purity status.
let checkEffects = (
  source: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let body = TypeLLEngine.buildCheckEffectsBody(source)
    let p = if hasDesktopRuntime() {
      RuntimeBridge.invoke("typell_compute", {"term": source})
    } else {
      fetchPost("/check-effects", body)
    }
    p
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Effect checking failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Check dimensional consistency (for Eclexia's dimensional type system).
/// POST /check-dimensional — validates unit/dimension annotations.
let checkDimensional = (
  source: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let body = TypeLLEngine.buildCheckDimensionalBody(source)
    let p = if hasDesktopRuntime() {
      RuntimeBridge.invoke("typell_compute", {"term": source})
    } else {
      fetchPost("/check-dimensional", body)
    }
    p
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Dimensional check failed")))
      Promise.resolve()
    })
    ->ignore
  })
}

/// Generate proof obligations from dependent types in the source.
/// POST /generate-obligations — extracts propositions that need proving.
let generateProofObligation = (
  source: string,
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {
  Tea_Cmd.call(callbacks => {
    let body = TypeLLEngine.buildGenerateProofObligationBody(source)
    let p = if hasDesktopRuntime() {
      RuntimeBridge.invoke("typell_compute", {"term": source})
    } else {
      fetchPost("/generate-obligations", body)
    }
    p
    ->Promise.then(result => {
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    })
    ->Promise.catch(_err => {
      callbacks.enqueue(tagger(Error("Proof obligation generation failed")))
      Promise.resolve()
    })
    ->ignore
  })
}
