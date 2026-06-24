// SPDX-License-Identifier: MPL-2.0
//
// Fuzz target: IPC payload structure validation.
//
// Tests that the IPC message framing and field extraction logic handles
// arbitrary payloads without panicking. Simulates the Gossamer IPC channel
// receiving malformed or adversarial messages from the webview.
//
// Run: cargo +nightly fuzz run fuzz_ipc_payload

#![no_main]
use libfuzzer_sys::fuzz_target;

/// Simulates the IPC message structure used by Gossamer.
/// The webview sends JSON objects with { cmd, callback, payload }.
#[derive(serde::Deserialize, Debug)]
struct IpcMessage {
    cmd: Option<String>,
    callback: Option<u64>,
    #[serde(default)]
    payload: serde_json::Value,
}

/// Simulates command routing — maps command names to handler categories.
fn classify_command(cmd: &str) -> &'static str {
    if cmd.starts_with("boj_") { return "boj"; }
    if cmd.starts_with("cloudguard_") { return "cloudguard"; }
    if cmd.starts_with("farm_") { return "farm"; }
    if cmd.starts_with("verisim_") { return "verisim"; }
    if cmd.starts_with("echidna_") { return "echidna"; }
    if cmd.starts_with("typell_") { return "typell"; }
    if cmd.starts_with("overlay_") { return "overlay"; }
    if cmd.starts_with("game_") { return "game"; }
    if cmd.starts_with("valence_") { return "valence"; }
    "general"
}

/// Simulates payload field extraction patterns used by command handlers.
fn extract_common_fields(payload: &serde_json::Value) {
    // String fields
    let _ = payload.get("path").and_then(|v| v.as_str());
    let _ = payload.get("content").and_then(|v| v.as_str());
    let _ = payload.get("id").and_then(|v| v.as_str());
    let _ = payload.get("name").and_then(|v| v.as_str());
    let _ = payload.get("query").and_then(|v| v.as_str());

    // Numeric fields
    let _ = payload.get("port").and_then(|v| v.as_u64());
    let _ = payload.get("timeout").and_then(|v| v.as_u64());
    let _ = payload.get("limit").and_then(|v| v.as_i64());

    // Boolean fields
    let _ = payload.get("recursive").and_then(|v| v.as_bool());
    let _ = payload.get("force").and_then(|v| v.as_bool());

    // Array fields
    if let Some(arr) = payload.get("items").and_then(|v| v.as_array()) {
        for item in arr.iter().take(100) {
            let _ = item.as_str();
            let _ = item.as_u64();
        }
    }

    // Nested object fields
    if let Some(obj) = payload.get("options").and_then(|v| v.as_object()) {
        for (key, val) in obj.iter().take(50) {
            let _ = key.len();
            let _ = val.as_str();
        }
    }
}

fuzz_target!(|data: &[u8]| {
    // Parse as IPC message
    if let Ok(msg) = serde_json::from_slice::<IpcMessage>(data) {
        // Exercise command classification
        if let Some(ref cmd) = msg.cmd {
            let category = classify_command(cmd);
            let _ = category.len();

            // Reject excessively long command names (DoS prevention check)
            if cmd.len() > 256 {
                return;
            }
        }

        // Exercise payload field extraction
        extract_common_fields(&msg.payload);

        // Exercise callback ID handling
        if let Some(cb) = msg.callback {
            let _ = cb.wrapping_add(1);
        }

        // Verify re-serialization doesn't panic
        let _ = serde_json::to_string(&msg.payload);
    }
});
