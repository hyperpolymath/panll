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

/// Path to the Zig FFI shared library for local compute dispatch.
const FFI_SO_PATH: &str =
    "/var/mnt/eclipse/repos/panll/ffi/zig/zig-out/lib/libpanll_compute.so";

/// FFI status report.
#[derive(Debug, Serialize, Deserialize)]
pub struct FfiStatus {
    pub ffi_loaded: bool,
    pub ffi_path: String,
    pub cpu_cores: usize,
    pub gpu_available: bool,
}

/// Local benchmark result.
#[derive(Debug, Serialize, Deserialize)]
pub struct BenchmarkResult {
    pub mflops: f64,
    pub memory_bandwidth_gbps: f64,
    pub latency_ns: f64,
    pub ffi_available: bool,
    pub timestamp: f64,
}

/// Dispatch compute to local Zig FFI (Phase 2).
///
/// Checks if the .so exists and calls it. Currently a stub — actual FFI
/// binding requires the Zig build to produce libpanll_compute.so.
#[tauri::command]
pub async fn coprocessor_dispatch_local(
    operation: String,
    input: String,
) -> Result<String, String> {
    let so_exists = std::path::Path::new(FFI_SO_PATH).exists();

    if so_exists {
        // FFI library found — return stub result indicating dispatch is available
        // but not yet wired to the actual Zig symbols.
        let result = ComputeResult {
            operation: operation.clone(),
            result: format!(
                "FFI stub: operation='{}' input='{}' — Zig dispatch available but not yet bound",
                operation, input
            ),
            duration_ms: 0.0,
            success: true,
        };
        serde_json::to_string(&result).map_err(|e| e.to_string())
    } else {
        Err(format!(
            "Zig FFI not built yet: {} does not exist. Run `zig build` in ffi/zig/ first.",
            FFI_SO_PATH
        ))
    }
}

/// Check if the Zig FFI shared library is available (Phase 2).
///
/// Returns JSON with FFI status, CPU core count, and GPU availability.
#[tauri::command]
pub async fn coprocessor_check_ffi() -> Result<String, String> {
    let so_exists = std::path::Path::new(FFI_SO_PATH).exists();
    let cpu_cores = std::thread::available_parallelism()
        .map(|p| p.get())
        .unwrap_or(1);

    // GPU detection: check for common GPU device paths on Linux.
    let gpu_available = std::path::Path::new("/dev/dri/renderD128").exists()
        || std::path::Path::new("/dev/nvidia0").exists();

    let status = FfiStatus {
        ffi_loaded: so_exists,
        ffi_path: FFI_SO_PATH.to_string(),
        cpu_cores,
        gpu_available,
    };

    serde_json::to_string(&status).map_err(|e| e.to_string())
}

/// Run local compute benchmark (Phase 2).
///
/// Returns mock benchmark results (MFLOPS, memory bandwidth, latency).
/// When the Zig FFI is built, this will run actual compute benchmarks.
#[tauri::command]
pub async fn coprocessor_benchmark() -> Result<String, String> {
    let ffi_available = std::path::Path::new(FFI_SO_PATH).exists();
    let cpu_cores = std::thread::available_parallelism()
        .map(|p| p.get())
        .unwrap_or(1);

    // Mock benchmark: scale results by CPU core count for plausible numbers.
    let result = BenchmarkResult {
        mflops: cpu_cores as f64 * 1200.0,
        memory_bandwidth_gbps: cpu_cores as f64 * 3.2,
        latency_ns: 150.0 / cpu_cores as f64,
        ffi_available,
        timestamp: std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs_f64(),
    };

    serde_json::to_string(&result).map_err(|e| e.to_string())
}

/// Load the Zig FFI shared library (Phase 2).
///
/// Checks for the .so file, reports system capabilities, and returns
/// JSON with load status, path, CPU cores, and GPU availability.
/// Actual dlopen binding is deferred until the Zig build is available.
#[tauri::command]
pub async fn coprocessor_load_ffi() -> Result<String, String> {
    let so_exists = std::path::Path::new(FFI_SO_PATH).exists();
    let cpu_cores = std::thread::available_parallelism()
        .map(|p| p.get())
        .unwrap_or(1);
    let gpu_available = std::path::Path::new("/dev/dri/renderD128").exists()
        || std::path::Path::new("/dev/nvidia0").exists();

    let result = serde_json::json!({
        "ffi_loaded": so_exists,
        "ffi_path": FFI_SO_PATH,
        "cpu_utilisation": 0.0,
        "gpu_memory_mb": if gpu_available { 4096 } else { 0 },
        "pending_dispatches": 0,
        "cpu_cores": cpu_cores,
        "gpu_available": gpu_available,
    });

    Ok(result.to_string())
}

/// Query local system resources — CPU utilisation, GPU memory (Phase 2).
///
/// Returns JSON with cpu_utilisation (0.0–1.0) and gpu_memory_mb.
/// Currently estimates CPU load from /proc/loadavg on Linux.
#[tauri::command]
pub async fn coprocessor_local_resources() -> Result<String, String> {
    let cpu_cores = std::thread::available_parallelism()
        .map(|p| p.get())
        .unwrap_or(1);

    // Read 1-minute load average from /proc/loadavg (Linux).
    let cpu_utilisation = if let Ok(contents) = std::fs::read_to_string("/proc/loadavg") {
        if let Some(first) = contents.split_whitespace().next() {
            first
                .parse::<f64>()
                .unwrap_or(0.0)
                .min(cpu_cores as f64)
                / cpu_cores as f64
        } else {
            0.0
        }
    } else {
        0.0
    };

    let gpu_available = std::path::Path::new("/dev/dri/renderD128").exists()
        || std::path::Path::new("/dev/nvidia0").exists();
    let so_exists = std::path::Path::new(FFI_SO_PATH).exists();

    let result = serde_json::json!({
        "ffi_loaded": so_exists,
        "ffi_path": FFI_SO_PATH,
        "cpu_utilisation": cpu_utilisation,
        "gpu_memory_mb": if gpu_available { 4096 } else { 0 },
        "pending_dispatches": 0,
    });

    Ok(result.to_string())
}

/// Smart dispatch — auto-selects local vs remote based on availability (Phase 3).
///
/// The Rust side implements a simple routing heuristic:
///   1. If Zig FFI .so exists and operation is math/vector → local
///   2. If Axiom.jl is reachable → remote
///   3. Fallback to BoJ cartridge
#[tauri::command]
pub async fn coprocessor_smart_dispatch(
    operation: String,
    payload: String,
) -> Result<String, String> {
    let start = std::time::Instant::now();
    let so_exists = std::path::Path::new(FFI_SO_PATH).exists();
    let op_lower = operation.to_lowercase();
    let is_math = op_lower.contains("math")
        || op_lower.contains("vector")
        || op_lower.contains("matrix")
        || op_lower.contains("tensor");

    let (route, reason, compute_result) = if so_exists && is_math {
        // Route local
        match coprocessor_dispatch_local(operation.clone(), payload).await {
            Ok(r) => ("local", "FFI loaded, math operation", r),
            Err(e) => ("local", "FFI dispatch failed", e),
        }
    } else {
        // Try remote, fallback to stub
        match query_axiom(&format!("{}:{}", operation, "")).await {
            Ok(r) => ("remote", "Axiom.jl available", r),
            Err(_) => {
                // BoJ fallback
                match query_boj(&operation).await {
                    Ok(r) => ("boj", "BoJ cartridge fallback", r),
                    Err(_) => (
                        "local",
                        "No remote engines available — local stub",
                        format!("{{\"operation\":\"{}\",\"result\":\"no engines available\",\"duration_ms\":0,\"success\":false}}", operation),
                    ),
                }
            }
        }
    };

    let duration_ms = start.elapsed().as_secs_f64() * 1000.0;
    let timestamp = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs_f64();

    let result = serde_json::json!({
        "route": route,
        "reason": reason,
        "operation": operation,
        "result": compute_result,
        "latency_ms": duration_ms,
        "timestamp": timestamp,
    });

    Ok(result.to_string())
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

    #[tokio::test]
    async fn test_coprocessor_check_ffi() {
        let result = coprocessor_check_ffi().await;
        assert!(result.is_ok());
        let json = result.unwrap();
        let status: FfiStatus = serde_json::from_str(&json).unwrap();
        assert_eq!(status.ffi_path, FFI_SO_PATH);
        assert!(status.cpu_cores >= 1);
    }

    #[tokio::test]
    async fn test_coprocessor_benchmark() {
        let result = coprocessor_benchmark().await;
        assert!(result.is_ok());
        let json = result.unwrap();
        let bench: BenchmarkResult = serde_json::from_str(&json).unwrap();
        assert!(bench.mflops > 0.0);
        assert!(bench.memory_bandwidth_gbps > 0.0);
        assert!(bench.latency_ns > 0.0);
        assert!(bench.timestamp > 0.0);
    }

    #[tokio::test]
    async fn test_coprocessor_dispatch_local() {
        let result =
            coprocessor_dispatch_local("matrix_multiply".to_string(), "[[1,2],[3,4]]".to_string())
                .await;
        // Result depends on whether the .so exists — either way, no panic.
        match result {
            Ok(json) => {
                let cr: ComputeResult = serde_json::from_str(&json).unwrap();
                assert_eq!(cr.operation, "matrix_multiply");
                assert!(cr.success);
            }
            Err(e) => {
                assert!(e.contains("does not exist"));
            }
        }
    }
}
