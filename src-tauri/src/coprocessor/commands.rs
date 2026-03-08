// SPDX-License-Identifier: PMPL-1.0-or-later

//! Tauri commands for the coprocessor control plane.
//!
//! Phase 1: Query external compute engines over IPC/HTTP.
//! - Axiom.jl: Unix socket at /tmp/axiom.sock or HTTP at localhost:7780
//! - BoJ: Uses boj-server cartridge invoke over HTTP at localhost:7800
//! - Device discovery: Probes all known engine endpoints

use serde::{Deserialize, Serialize};

/// A discovered compute device.
#[derive(Debug, Serialize, Deserialize)]
pub struct ComputeDevice {
    pub engine: String,
    pub device_name: String,
    pub device_type: String,
    pub available: bool,
    pub capabilities: Vec<String>,
}

/// A compute query result.
#[derive(Debug, Serialize, Deserialize)]
pub struct ComputeResult {
    pub operation: String,
    pub result: String,
    pub duration_ms: f64,
    pub success: bool,
}

/// Query a compute engine by ID and operation.
///
/// Supported engines:
/// - "axiom": Queries Axiom.jl at localhost:7780/api/compute
/// - "boj": Queries BoJ server at localhost:7800/invoke
/// - "local": Returns stub for Phase 2
#[tauri::command]
pub async fn query_compute_engine(
    engine_id: String,
    operation: String,
) -> Result<String, String> {
    let start = std::time::Instant::now();

    let result = match engine_id.as_str() {
        "axiom" => query_axiom(&operation).await,
        "boj" => query_boj(&operation).await,
        "local" => Ok("Local compute not yet available (Phase 2)".to_string()),
        _ => Err(format!("Unknown compute engine: {}", engine_id)),
    };

    let duration_ms = start.elapsed().as_secs_f64() * 1000.0;

    match result {
        Ok(output) => {
            let r = ComputeResult {
                operation,
                result: output,
                duration_ms,
                success: true,
            };
            serde_json::to_string(&r).map_err(|e| e.to_string())
        }
        Err(e) => {
            let r = ComputeResult {
                operation,
                result: e.clone(),
                duration_ms,
                success: false,
            };
            serde_json::to_string(&r).map_err(|e2| e2.to_string())
        }
    }
}

/// Discover compute devices from all known engines.
///
/// Probes Axiom.jl and BoJ endpoints, returns a JSON array of discovered devices.
#[tauri::command]
pub async fn discover_compute_devices() -> Result<String, String> {
    let mut devices: Vec<ComputeDevice> = Vec::new();

    // Probe Axiom.jl
    if let Ok(axiom_devices) = probe_axiom().await {
        devices.extend(axiom_devices);
    }

    // Probe BoJ
    if let Ok(boj_devices) = probe_boj().await {
        devices.extend(boj_devices);
    }

    // Local is always available (Phase 2 stub)
    devices.push(ComputeDevice {
        engine: "local".to_string(),
        device_name: "CPU".to_string(),
        device_type: "cpu".to_string(),
        available: true,
        capabilities: vec!["basic-math".to_string(), "wasm".to_string()],
    });

    serde_json::to_string(&devices).map_err(|e| e.to_string())
}

/// Query Axiom.jl over HTTP.
async fn query_axiom(operation: &str) -> Result<String, String> {
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .map_err(|e| e.to_string())?;

    let url = "http://127.0.0.1:7780/api/compute";
    let body = serde_json::json!({ "operation": operation });

    let resp = client
        .post(url)
        .json(&body)
        .send()
        .await
        .map_err(|e| format!("Axiom.jl not reachable: {}", e))?;

    resp.text()
        .await
        .map_err(|e| format!("Failed to read Axiom.jl response: {}", e))
}

/// Query BoJ server over HTTP.
async fn query_boj(operation: &str) -> Result<String, String> {
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .map_err(|e| e.to_string())?;

    let url = "http://127.0.0.1:7800/invoke";
    let body = serde_json::json!({ "operation": operation });

    let resp = client
        .post(url)
        .json(&body)
        .send()
        .await
        .map_err(|e| format!("BoJ server not reachable: {}", e))?;

    resp.text()
        .await
        .map_err(|e| format!("Failed to read BoJ response: {}", e))
}

/// Probe Axiom.jl for available devices.
async fn probe_axiom() -> Result<Vec<ComputeDevice>, String> {
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(3))
        .build()
        .map_err(|e| e.to_string())?;

    let resp = client
        .get("http://127.0.0.1:7780/api/devices")
        .send()
        .await
        .map_err(|e| format!("Axiom.jl probe failed: {}", e))?;

    let text = resp
        .text()
        .await
        .map_err(|e| format!("Failed to read Axiom.jl devices: {}", e))?;

    // Try to parse as JSON array of device names
    if let Ok(names) = serde_json::from_str::<Vec<String>>(&text) {
        Ok(names
            .into_iter()
            .map(|name| ComputeDevice {
                engine: "axiom".to_string(),
                device_name: name.clone(),
                device_type: classify_device(&name),
                available: true,
                capabilities: vec![],
            })
            .collect())
    } else {
        // Single device fallback
        Ok(vec![ComputeDevice {
            engine: "axiom".to_string(),
            device_name: "Axiom.jl Runtime".to_string(),
            device_type: "runtime".to_string(),
            available: true,
            capabilities: vec!["smart-backend".to_string()],
        }])
    }
}

/// Probe BoJ for available cartridges as compute devices.
async fn probe_boj() -> Result<Vec<ComputeDevice>, String> {
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(3))
        .build()
        .map_err(|e| e.to_string())?;

    let resp = client
        .get("http://127.0.0.1:7800/cartridges")
        .send()
        .await
        .map_err(|e| format!("BoJ probe failed: {}", e))?;

    let text = resp
        .text()
        .await
        .map_err(|e| format!("Failed to read BoJ cartridges: {}", e))?;

    if let Ok(names) = serde_json::from_str::<Vec<String>>(&text) {
        Ok(names
            .into_iter()
            .map(|name| ComputeDevice {
                engine: "boj".to_string(),
                device_name: name,
                device_type: "cartridge".to_string(),
                available: true,
                capabilities: vec!["zig-ffi".to_string()],
            })
            .collect())
    } else {
        Ok(vec![])
    }
}

/// Classify a device name into a type.
fn classify_device(name: &str) -> String {
    let lower = name.to_lowercase();
    if lower.contains("gpu") || lower.contains("cuda") || lower.contains("rocm") {
        "gpu".to_string()
    } else if lower.contains("tpu") {
        "tpu".to_string()
    } else if lower.contains("npu") {
        "npu".to_string()
    } else if lower.contains("fpga") {
        "fpga".to_string()
    } else if lower.contains("cpu") {
        "cpu".to_string()
    } else {
        "compute".to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_classify_device() {
        assert_eq!(classify_device("NVIDIA CUDA"), "gpu");
        assert_eq!(classify_device("AMD ROCm"), "gpu");
        assert_eq!(classify_device("Google TPU v4"), "tpu");
        assert_eq!(classify_device("Intel CPU"), "cpu");
        assert_eq!(classify_device("Xilinx FPGA"), "fpga");
        assert_eq!(classify_device("Neural NPU"), "npu");
        assert_eq!(classify_device("Unknown"), "compute");
    }

    #[test]
    fn test_compute_result_serialization() {
        let r = ComputeResult {
            operation: "test".to_string(),
            result: "ok".to_string(),
            duration_ms: 1.5,
            success: true,
        };
        let json = serde_json::to_string(&r).unwrap();
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"duration_ms\":1.5"));
    }

    #[test]
    fn test_compute_device_serialization() {
        let d = ComputeDevice {
            engine: "axiom".to_string(),
            device_name: "Test GPU".to_string(),
            device_type: "gpu".to_string(),
            available: true,
            capabilities: vec!["cuda".to_string()],
        };
        let json = serde_json::to_string(&d).unwrap();
        assert!(json.contains("\"engine\":\"axiom\""));
    }
}
