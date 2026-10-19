// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! IPC command table for the panel-backend modules.
//!
//! Each entry adapts one backend function to the Gossamer IPC handler shape,
//! `Fn(serde_json::Value) -> Result<serde_json::Value, String>`. The table is
//! GTK-free, so `cargo test --lib` checks every entry; `main.rs` registers it
//! with `App::command_async`, which runs each call on a worker thread instead
//! of the GTK main thread.
//!
//! Conventions shared by every entry:
//! - Arguments are read by parameter name: the snake_case key first, then its
//!   camelCase form. Tauri renamed camelCase keys to snake_case for us; the
//!   Gossamer bridge does not, and the old frontend sent both.
//! - A missing argument reads as JSON `null`. `Option` parameters get `None`;
//!   a required one fails with "missing argument `x`" before the handler runs.
//! - Responses use the envelope the rest of `main.rs` uses:
//!   `{"ok": true, "result": …}` or `{"ok": false, "error": "…"}`. A result
//!   string that is valid JSON is embedded as JSON, anything else as a string.
//! - `async fn` handlers run to completion on one shared Tokio runtime, so
//!   tasks they spawn (e.g. via `compat::spawn_async`) keep running after the
//!   call returns.

use serde::de::DeserializeOwned;
use serde_json::{json, Value};
use std::future::Future;
use std::sync::OnceLock;

/// A Gossamer IPC handler.
pub type Handler = Box<dyn Fn(Value) -> Result<Value, String> + Send + 'static>;

/// One IPC command.
pub struct Command {
    /// Command name, as the frontend passes it to `invoke`.
    pub name: &'static str,
    /// Arguments the handler cannot run without: every parameter that is not
    /// an `Option` and is not supplied by the backend itself.
    pub required: &'static [&'static str],
    /// The handler. It always returns `Ok`; failures are in the envelope.
    pub handler: Handler,
}

/// Every panel-backend command, grouped by module.
pub fn commands() -> Vec<Command> {
    let mut table = Table(Vec::new());
    coprocessor(&mut table);
    table.0
}

// ---------------------------------------------------------------------------
// Argument and response helpers
// ---------------------------------------------------------------------------

/// Read argument `name` from `payload`, trying `name` and then its camelCase
/// form. A missing key reads as `null`, so `Option<T>` yields `None`.
pub fn arg<T: DeserializeOwned>(payload: &Value, name: &str) -> Result<T, String> {
    let value = lookup(payload, name).cloned().unwrap_or(Value::Null);
    let missing = value.is_null();
    serde_json::from_value(value).map_err(|e| {
        if missing {
            format!("missing argument `{name}`")
        } else {
            format!("invalid argument `{name}`: {e}")
        }
    })
}

/// Read a struct argument: the value under `name` (or its camelCase form) if
/// present, otherwise the whole payload. The old frontend sent both shapes.
pub fn struct_arg<T: DeserializeOwned>(payload: &Value, name: &str) -> Result<T, String> {
    let value = lookup(payload, name).unwrap_or(payload).clone();
    serde_json::from_value(value).map_err(|e| format!("invalid argument `{name}`: {e}"))
}

/// Wrap a handler result in the IPC response envelope.
pub fn respond(result: Result<String, String>) -> Value {
    match result {
        Ok(text) => {
            let result = serde_json::from_str::<Value>(&text).unwrap_or(Value::String(text));
            json!({ "ok": true, "result": result })
        }
        Err(error) => json!({ "ok": false, "error": error }),
    }
}

/// Run an `async fn` handler to completion on the shared IPC runtime.
///
/// Must not be called from inside a Tokio runtime. Gossamer's worker threads
/// are plain threads, so `command_async` handlers can call it.
pub fn block_on<F>(future: F) -> Result<String, String>
where
    F: Future<Output = Result<String, String>>,
{
    static RUNTIME: OnceLock<Result<tokio::runtime::Runtime, String>> = OnceLock::new();
    let runtime = RUNTIME.get_or_init(|| {
        tokio::runtime::Builder::new_multi_thread()
            .enable_all()
            .build()
            .map_err(|e| format!("cannot start the IPC Tokio runtime: {e}"))
    });
    match runtime {
        Ok(runtime) => runtime.block_on(future),
        Err(e) => Err(e.clone()),
    }
}

fn lookup<'a>(payload: &'a Value, name: &str) -> Option<&'a Value> {
    payload
        .get(name)
        .or_else(|| payload.get(snake_to_camel(name).as_str()))
}

fn snake_to_camel(name: &str) -> String {
    let mut out = String::with_capacity(name.len());
    let mut upper = false;
    for c in name.chars() {
        if c == '_' {
            upper = true;
        } else if upper {
            out.extend(c.to_uppercase());
            upper = false;
        } else {
            out.push(c);
        }
    }
    out
}

struct Table(Vec<Command>);

impl Table {
    fn add<F>(&mut self, name: &'static str, required: &'static [&'static str], f: F)
    where
        F: Fn(&Value) -> Result<String, String> + Send + 'static,
    {
        self.0.push(Command {
            name,
            required,
            handler: Box::new(move |payload| Ok(respond(f(&payload)))),
        });
    }
}

// ---------------------------------------------------------------------------
// Command groups
// ---------------------------------------------------------------------------

fn coprocessor(t: &mut Table) {
    use crate::coprocessor::commands as c;
    t.add("query_compute_engine", &["engine_id", "operation"], |p| {
        block_on(c::query_compute_engine(
            arg(p, "engine_id")?,
            arg(p, "operation")?,
        ))
    });
    t.add("discover_compute_devices", &[], |_| {
        block_on(c::discover_compute_devices())
    });
    // An empty `lib_path` means "use runtime discovery", which is how the
    // "Load Local FFI" action calls it (no path at all).
    t.add("coprocessor_load_ffi", &[], |p| {
        let lib_path: Option<String> = arg(p, "lib_path")?;
        block_on(c::coprocessor_load_ffi(lib_path.unwrap_or_default()))
    });
    t.add(
        "coprocessor_ffi_dispatch",
        &["backend", "operation", "payload"],
        |p| {
            block_on(c::coprocessor_ffi_dispatch(
                arg(p, "backend")?,
                arg(p, "operation")?,
                arg(p, "payload")?,
            ))
        },
    );
    t.add("coprocessor_ffi_status", &[], |_| {
        block_on(c::coprocessor_ffi_status())
    });
    t.add("coprocessor_dispatch_local", &["operation", "input"], |p| {
        block_on(c::coprocessor_dispatch_local(
            arg(p, "operation")?,
            arg(p, "input")?,
        ))
    });
    t.add("coprocessor_check_ffi", &[], |_| {
        block_on(c::coprocessor_check_ffi())
    });
    t.add("coprocessor_benchmark", &[], |_| {
        block_on(c::coprocessor_benchmark())
    });
    t.add("coprocessor_local_resources", &[], |_| {
        block_on(c::coprocessor_local_resources())
    });
    t.add(
        "coprocessor_smart_dispatch",
        &["operation", "payload"],
        |p| {
            block_on(c::coprocessor_smart_dispatch(
                arg(p, "operation")?,
                arg(p, "payload")?,
            ))
        },
    );
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashSet;

    fn call(name: &str, payload: Value) -> Value {
        let commands = commands();
        let cmd = commands
            .iter()
            .find(|c| c.name == name)
            .unwrap_or_else(|| panic!("no command {name}"));
        (cmd.handler)(payload).expect("handlers always return Ok")
    }

    #[test]
    fn arg_reads_snake_then_camel() {
        let p =
            json!({ "panel_id": "a", "repoPath": "b", "both_set": "snake", "bothSet": "camel" });
        assert_eq!(arg::<String>(&p, "panel_id").unwrap(), "a");
        assert_eq!(arg::<String>(&p, "repo_path").unwrap(), "b");
        assert_eq!(arg::<String>(&p, "both_set").unwrap(), "snake");
    }

    #[test]
    fn arg_missing_required_and_optional() {
        let p = json!({});
        assert_eq!(
            arg::<String>(&p, "lib_path").unwrap_err(),
            "missing argument `lib_path`"
        );
        assert_eq!(arg::<Option<u16>>(&p, "port").unwrap(), None);
        assert_eq!(
            arg::<Option<u16>>(&json!({ "port": 8080 }), "port").unwrap(),
            Some(8080)
        );
        let err = arg::<u16>(&json!({ "port": "x" }), "port").unwrap_err();
        assert!(err.starts_with("invalid argument `port`"), "{err}");
    }

    #[test]
    fn struct_arg_accepts_nested_or_flattened() {
        #[derive(serde::Deserialize, Debug, PartialEq)]
        struct Req {
            content: String,
        }
        let nested = json!({ "request": { "content": "hi" } });
        let flat = json!({ "content": "hi" });
        assert_eq!(struct_arg::<Req>(&nested, "request").unwrap().content, "hi");
        assert_eq!(struct_arg::<Req>(&flat, "request").unwrap().content, "hi");
        assert!(struct_arg::<Req>(&json!({}), "request")
            .unwrap_err()
            .contains("missing"));
    }

    #[test]
    fn respond_envelope() {
        assert_eq!(
            respond(Ok(r#"{"a":1}"#.into())),
            json!({ "ok": true, "result": { "a": 1 } })
        );
        assert_eq!(
            respond(Ok("plain text".into())),
            json!({ "ok": true, "result": "plain text" })
        );
        assert_eq!(
            respond(Err("boom".into())),
            json!({ "ok": false, "error": "boom" })
        );
    }

    #[test]
    fn snake_to_camel_cases() {
        assert_eq!(snake_to_camel("provider_id"), "providerId");
        assert_eq!(snake_to_camel("base64_data"), "base64Data");
        assert_eq!(snake_to_camel("path"), "path");
    }

    #[test]
    fn command_names_are_unique_and_disjoint_from_main_rs() {
        let mut seen = HashSet::new();
        for cmd in commands() {
            assert!(seen.insert(cmd.name), "duplicate command {}", cmd.name);
        }
        // Commands main.rs registers itself must not be registered twice.
        let main_rs = include_str!("main.rs");
        for chunk in main_rs.split("app.command(\"").skip(1) {
            let name = chunk.split('"').next().unwrap_or_default();
            assert!(
                !seen.contains(name),
                "{name} is registered in main.rs and the table"
            );
        }
    }

    /// Every command with a required argument must reject an empty payload
    /// before its handler body runs (so this test has no side effects).
    #[test]
    fn required_arguments_are_enforced() {
        for cmd in commands() {
            if cmd.required.is_empty() {
                continue;
            }
            let response = (cmd.handler)(json!({})).expect("handlers always return Ok");
            assert_eq!(
                response["ok"], false,
                "{} accepted an empty payload",
                cmd.name
            );
            let error = response["error"].as_str().unwrap_or_default();
            assert!(
                error.contains("missing"),
                "{}: unexpected error {error}",
                cmd.name
            );
        }
    }

    #[test]
    fn coprocessor_commands_run_through_the_table() {
        let status = call("coprocessor_ffi_status", json!({}));
        assert_eq!(status["ok"], true, "{status}");
        assert_eq!(status["result"]["ffi_loaded"], false);

        let load = call(
            "coprocessor_load_ffi",
            json!({ "libPath": "/no/such/libpanll_copro.so" }),
        );
        assert_eq!(load["ok"], false, "{load}");

        // `lib_path` is optional: omitting it selects runtime discovery
        // rather than failing as a missing argument.
        let commands = commands();
        let load_ffi = commands
            .iter()
            .find(|c| c.name == "coprocessor_load_ffi")
            .expect("coprocessor_load_ffi is registered");
        assert!(load_ffi.required.is_empty());

        let missing = call("query_compute_engine", json!({ "operation": "x" }));
        assert_eq!(missing["error"], "missing argument `engine_id`");
    }
}
