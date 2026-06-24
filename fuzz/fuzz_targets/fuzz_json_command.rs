// SPDX-License-Identifier: MPL-2.0
//
// Fuzz target: JSON command deserialization.
//
// Tests that arbitrary byte sequences fed to serde_json::from_slice never
// cause panics, memory corruption, or undefined behaviour when parsed as
// Gossamer IPC command payloads.
//
// Run: cargo +nightly fuzz run fuzz_json_command

#![no_main]
use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: &[u8]| {
    // Attempt to parse arbitrary bytes as a JSON value.
    // This exercises serde_json's parser with untrusted input — the primary
    // attack surface for IPC payloads arriving from the webview.
    if let Ok(value) = serde_json::from_slice::<serde_json::Value>(data) {
        // If parsing succeeds, exercise common access patterns used by
        // command handlers to extract fields from the payload.
        let _ = value.get("cmd");
        let _ = value.get("payload");
        let _ = value.get("callback");

        // Exercise nested access (command handlers drill into payload objects)
        if let Some(payload) = value.get("payload") {
            let _ = payload.get("path");
            let _ = payload.get("content");
            let _ = payload.get("options");
            let _ = payload.as_str();
            let _ = payload.as_array();
            let _ = payload.as_object();
        }

        // Exercise string coercion paths
        if let Some(cmd) = value.get("cmd").and_then(|v| v.as_str()) {
            let _ = cmd.len();
            let _ = cmd.contains("__");
        }

        // Ensure round-trip serialization doesn't panic
        let _ = serde_json::to_string(&value);
        let _ = serde_json::to_vec(&value);
    }
});
