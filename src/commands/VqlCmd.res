// SPDX-License-Identifier: MPL-2.0
// VCL-total Commands — backend command bridge for VCL panel I/O.
//
// All side effects (HTTP calls, file I/O, clipboard) route through here.
// The VCL panel's Engine layer is pure; this module handles the real world.
//
// Endpoints:
//   VeriSimDB  — http://localhost:8200 (octad query execution)
//   ECHIDNA    — http://localhost:8000 (cross-prover dispatch)
//   TypeLL     — http://localhost:7800 (type checking)
//   BoJ Server — http://localhost:7700 (cartridge routing)

open VqlModel

// ============================================================
// SECTION 1: Backend Command Bindings
// ============================================================

let invoke = RuntimeBridge.invoke

// ============================================================
// SECTION 2: VeriSimDB Commands
// ============================================================

/// Execute a VCL-total query against VeriSimDB.
let executeQuery = (
  query: string,
  target: executionTarget,
  level: typeSafetyLevel,
  _bojRouting: bool,
): promise<result<string, string>> => {
  let endpoint = switch target {
  | TargetVeriSimDB => "http://localhost:8200/api/v1/query"
  | TargetEchidna => "http://localhost:8000/api/v1/vcl"
  | TargetBoJ => "http://localhost:7700/echidna-llm/vcl"
  | TargetTypeLL => "http://localhost:7800/api/v1/vcl-total/check"
  | TargetDryRun => "http://localhost:8200/api/v1/explain"
  }
  let levelInt = VqlEngine.levelToInt(level)
  let body = `{"query": ${JSON.stringify(JSON.Encode.string(query))}, "level": ${Int.toString(
      levelInt,
    )}}`
  invoke("http_post", {"url": endpoint, "body": body})
  ->Promise.then(response => Promise.resolve(Ok(response)))
  ->Promise.catch(err => {
    let msg = switch err {
    | JsExn(e) =>
      switch JsExn.message(e) {
      | Some(m) => m
      | None => "Unknown error"
      }
    | _ => "Unknown error"
    }
    Promise.resolve(Error(msg))
  })
}

/// Fetch the VeriSimDB schema (tables, columns, modalities).
let fetchSchema = (): promise<result<string, string>> => {
  invoke("http_get", {"url": "http://localhost:8200/api/v1/schema"})
  ->Promise.then(r => Promise.resolve(Ok(r)))
  ->Promise.catch(err => {
    let msg = switch err {
    | JsExn(e) =>
      switch JsExn.message(e) {
      | Some(m) => m
      | None => "Schema fetch failed"
      }
    | _ => "Schema fetch failed"
    }
    Promise.resolve(Error(msg))
  })
}

/// Check VeriSimDB connection health.
let checkConnection = (): promise<result<string, string>> => {
  invoke("http_get", {"url": "http://localhost:8200/api/v1/health"})
  ->Promise.then(r => Promise.resolve(Ok(r)))
  ->Promise.catch(err => {
    let msg = switch err {
    | JsExn(e) =>
      switch JsExn.message(e) {
      | Some(m) => m
      | None => "Connection failed"
      }
    | _ => "Connection failed"
    }
    Promise.resolve(Error(msg))
  })
}

// ============================================================
// SECTION 3: TypeLL Type Checking Commands
// ============================================================

/// Send a VCL-total query to TypeLL for type checking.
let typeCheckQuery = (query: string, level: typeSafetyLevel): promise<result<string, string>> => {
  let levelInt = VqlEngine.levelToInt(level)
  let body = `{"query": ${JSON.stringify(JSON.Encode.string(query))}, "level": ${Int.toString(
      levelInt,
    )}, "mode": "vcl-total"}`
  invoke("http_post", {"url": "http://localhost:7800/api/v1/vcl-total/check", "body": body})
  ->Promise.then(r => Promise.resolve(Ok(r)))
  ->Promise.catch(err => {
    let msg = switch err {
    | JsExn(e) =>
      switch JsExn.message(e) {
      | Some(m) => m
      | None => "TypeLL check failed"
      }
    | _ => "TypeLL check failed"
    }
    Promise.resolve(Error(msg))
  })
}

// ============================================================
// SECTION 4: ECHIDNA Cross-Prover Commands
// ============================================================

/// Fetch available prover statuses from ECHIDNA.
let fetchProverStatus = (): promise<result<string, string>> => {
  invoke("http_get", {"url": "http://localhost:8000/api/v1/provers"})
  ->Promise.then(r => Promise.resolve(Ok(r)))
  ->Promise.catch(err => {
    let msg = switch err {
    | JsExn(e) =>
      switch JsExn.message(e) {
      | Some(m) => m
      | None => "Prover fetch failed"
      }
    | _ => "Prover fetch failed"
    }
    Promise.resolve(Error(msg))
  })
}

/// Get a query execution plan without executing.
let explainQuery = (query: string): promise<result<string, string>> => {
  let body = `{"query": ${JSON.stringify(JSON.Encode.string(query))}, "explain": true}`
  invoke("http_post", {"url": "http://localhost:8000/api/v1/vcl/explain", "body": body})
  ->Promise.then(r => Promise.resolve(Ok(r)))
  ->Promise.catch(err => {
    let msg = switch err {
    | JsExn(e) =>
      switch JsExn.message(e) {
      | Some(m) => m
      | None => "Explain failed"
      }
    | _ => "Explain failed"
    }
    Promise.resolve(Error(msg))
  })
}

// ============================================================
// SECTION 5: Export Commands
// ============================================================

/// Export query results to a file.
let exportResults = (data: string, format: string): promise<result<string, string>> => {
  invoke("save_file", {"content": data, "format": format, "defaultName": `vcl-results.${format}`})
  ->Promise.then(r => Promise.resolve(Ok(r)))
  ->Promise.catch(err => {
    let msg = switch err {
    | JsExn(e) =>
      switch JsExn.message(e) {
      | Some(m) => m
      | None => "Export failed"
      }
    | _ => "Export failed"
    }
    Promise.resolve(Error(msg))
  })
}

/// Copy text to clipboard.
let copyToClipboard = (text: string): promise<result<string, string>> => {
  invoke("clipboard_write", {"text": text})
  ->Promise.then(r => Promise.resolve(Ok(r)))
  ->Promise.catch(err => {
    let msg = switch err {
    | JsExn(e) =>
      switch JsExn.message(e) {
      | Some(m) => m
      | None => "Clipboard failed"
      }
    | _ => "Clipboard failed"
    }
    Promise.resolve(Error(msg))
  })
}

// ============================================================
// SECTION 6: History Persistence
// ============================================================

/// Save query history to local storage.
let saveHistory = (history: array<historyEntry>): promise<result<string, string>> => {
  let json = switch JSON.stringifyAny(history) {
  | Some(s) => s
  | None => "[]"
  }
  invoke("store_set", {"key": "vcl_history", "value": json})
  ->Promise.then(r => Promise.resolve(Ok(r)))
  ->Promise.catch(err => {
    let msg = switch err {
    | JsExn(e) =>
      switch JsExn.message(e) {
      | Some(m) => m
      | None => "Save failed"
      }
    | _ => "Save failed"
    }
    Promise.resolve(Error(msg))
  })
}

/// Load query history from local storage.
let loadHistory = (): promise<result<string, string>> => {
  invoke("store_get", {"key": "vcl_history"})
  ->Promise.then(r => Promise.resolve(Ok(r)))
  ->Promise.catch(err => {
    let msg = switch err {
    | JsExn(e) =>
      switch JsExn.message(e) {
      | Some(m) => m
      | None => "Load failed"
      }
    | _ => "Load failed"
    }
    Promise.resolve(Error(msg))
  })
}
