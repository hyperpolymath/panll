// SPDX-License-Identifier: PMPL-1.0-or-later

//! Tauri commands for the coprocessor control plane and data plane.
//!
//! Phase 1: Query external compute engines over IPC/HTTP.
//!   - Axiom.jl: Unix socket at /tmp/axiom.sock or HTTP at localhost:7780
//!   - BoJ: Uses boj-server cartridge invoke over HTTP at localhost:7800
//!   - Device discovery: Probes all known engine endpoints
//!
//! Phase 2: Local Zig FFI dispatch via shared library loading.
//!   - `coprocessor_load_ffi(lib_path)` — Load a Zig .so via libloading
//!   - `coprocessor_ffi_dispatch(backend, operation, payload)` — Dispatch
//!     through loaded FFI, falling back to HTTP Axiom.jl if FFI not loaded
//!   - `coprocessor_ffi_status()` — Report FFI load state and available backends

// TODO: add libloading = "0.8" to Cargo.toml
// TODO: add once_cell = "1" to Cargo.toml (or use std::sync::LazyLock on Rust 1.80+)

use serde::{Deserialize, Serialize};

use super::{CoproBackend, FFI_STATE};

// ============================================================================
// Shared types
// ============================================================================

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

/// FFI status report — returned by `coprocessor_ffi_status`.
#[derive(Debug, Serialize, Deserialize)]
pub struct FfiStatusReport {
    /// Whether the Zig FFI shared library is loaded and initialised.
    pub ffi_loaded: bool,
    /// Filesystem path to the loaded library (empty if not loaded).
    pub ffi_lib_path: String,
    /// Backends available through the loaded FFI library.
    pub available_backends: Vec<String>,
    /// Number of CPU cores detected.
    pub cpu_cores: usize,
    /// Whether a GPU device file was found.
    pub gpu_available: bool,
    /// Current CPU utilisation (0.0–1.0).
    pub cpu_utilisation: f64,
    /// Estimated GPU memory in megabytes.
    pub gpu_memory_mb: u64,
}

/// FFI dispatch result — wraps the raw output with routing metadata.
#[derive(Debug, Serialize, Deserialize)]
pub struct FfiDispatchResult {
    /// Which route was taken: "ffi", "axiom", "boj", or "stub".
    pub route: String,
    /// The backend that was targeted.
    pub backend: String,
    /// The operation requested.
    pub operation: String,
    /// The raw result string from the compute engine.
    pub result: String,
    /// Latency in milliseconds.
    pub duration_ms: f64,
    /// Whether the dispatch succeeded.
    pub success: bool,
}

// ============================================================================
// Path constants
// ============================================================================

/// Path to the Zig FFI shared library for local compute dispatch.
const FFI_SO_PATH: &str =
    "/var/mnt/eclipse/repos/panll/ffi/zig/zig-out/lib/libpanll_copro.so";

// ============================================================================
// Phase 1 commands — external engine queries
// ============================================================================

/// Query a compute engine by ID and operation.
///
/// Supported engines:
/// - "axiom": Queries Axiom.jl at localhost:7780/api/compute
/// - "boj": Queries BoJ server at localhost:7800/invoke
/// - "local": Dispatches through Zig FFI if loaded, else returns stub
#[tauri::command]
pub async fn query_compute_engine(
    engine_id: String,
    operation: String,
) -> Result<String, String> {
    let start = std::time::Instant::now();

    let result = match engine_id.as_str() {
        "axiom" => query_axiom(&operation).await,
        "boj" => query_boj(&operation).await,
        "local" => {
            // Phase 2: attempt FFI dispatch for local engine
            let guard = FFI_STATE.lock().map_err(|e| e.to_string())?;
            if guard.loaded {
                drop(guard);
                dispatch_via_ffi("maths", &operation, "").await
            } else {
                Ok("Local compute: FFI not loaded — use coprocessor_load_ffi to load the Zig library".to_string())
            }
        }
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
/// Probes Axiom.jl and BoJ endpoints, includes FFI-backed local backends
/// if the Zig library is loaded.
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

    // Phase 2: report FFI-backed local backends
    let guard = FFI_STATE.lock().map_err(|e| e.to_string())?;
    if guard.loaded {
        for backend in &guard.available_backends {
            devices.push(ComputeDevice {
                engine: "local".to_string(),
                device_name: format!("Zig FFI — {}", backend.label()),
                device_type: "ffi".to_string(),
                available: true,
                capabilities: vec!["zig-ffi".to_string(), "zero-copy".to_string()],
            });
        }
    } else {
        // Always report CPU as available for local compute
        devices.push(ComputeDevice {
            engine: "local".to_string(),
            device_name: "CPU".to_string(),
            device_type: "cpu".to_string(),
            available: true,
            capabilities: vec!["basic-math".to_string(), "wasm".to_string()],
        });
    }

    serde_json::to_string(&devices).map_err(|e| e.to_string())
}

// ============================================================================
// Phase 2 commands — Zig FFI dispatch
// ============================================================================

/// Load a Zig FFI shared library for local coprocessor dispatch.
///
/// Accepts a filesystem path to a `.so` (Linux), `.dylib` (macOS), or `.dll`
/// (Windows). The library must export the PanLL coprocessor ABI:
///   - `copro_init() -> i32`
///   - `copro_deinit()`
///   - `copro_dispatch(backend: u8, op: *const u8, payload: *const u8) -> *mut u8`
///   - `copro_free(ptr: *mut u8)`
///
/// If `lib_path` is empty, uses the default path: `FFI_SO_PATH`.
#[tauri::command]
pub async fn coprocessor_load_ffi(lib_path: String) -> Result<String, String> {
    let path = if lib_path.is_empty() {
        FFI_SO_PATH.to_string()
    } else {
        lib_path
    };

    // Verify the file exists before attempting to load.
    if !std::path::Path::new(&path).exists() {
        return Err(format!(
            "FFI library not found at '{}'. Build it with: cd ffi/zig && zig build",
            path
        ));
    }

    // TODO: Once libloading is in Cargo.toml, replace this block with:
    //
    //   let lib = unsafe { libloading::Library::new(&path) }
    //       .map_err(|e| format!("Failed to load FFI library: {}", e))?;
    //
    //   // Resolve copro_init and call it.
    //   let init: libloading::Symbol<super::CoproInitFn> = unsafe { lib.get(b"copro_init\0") }
    //       .map_err(|e| format!("Symbol copro_init not found: {}", e))?;
    //   let rc = unsafe { init() };
    //   if rc != 0 {
    //       return Err(format!("copro_init returned error code: {}", rc));
    //   }
    //
    //   // Store library in global state.
    //   let mut guard = FFI_STATE.lock().map_err(|e| e.to_string())?;
    //   guard.library = Some(lib);
    //   guard.loaded = true;
    //   guard.lib_path = path.clone();
    //   guard.available_backends = CoproBackend::all().to_vec();

    // --- Stub implementation until libloading is added ---
    let mut guard = FFI_STATE.lock().map_err(|e| e.to_string())?;
    guard.loaded = true;
    guard.lib_path = path.clone();
    guard.available_backends = CoproBackend::all().to_vec();

    let cpu_cores = std::thread::available_parallelism()
        .map(|p| p.get())
        .unwrap_or(1);
    let gpu_memory_mb = super::estimate_gpu_memory_mb();

    let result = serde_json::json!({
        "ffi_loaded": true,
        "ffi_lib_path": path,
        "available_backends": guard.available_backends.iter()
            .map(|b| b.label())
            .collect::<Vec<_>>(),
        "cpu_cores": cpu_cores,
        "gpu_memory_mb": gpu_memory_mb,
        "message": "FFI library registered (stub — actual dlopen pending libloading dep)"
    });

    Ok(result.to_string())
}

/// Dispatch a computation through the loaded Zig FFI shared library.
///
/// If the FFI library is loaded and the requested backend is available locally,
/// the call goes directly through the C ABI — zero network round-trip.
///
/// If the FFI is not loaded, falls back to HTTP dispatch via Axiom.jl.
///
/// # Arguments
/// - `backend` — Backend name (e.g. "maths", "vector", "tensor")
/// - `operation` — Operation string (e.g. "matrix_multiply", "fft")
/// - `payload` — JSON-encoded payload for the operation
#[tauri::command]
pub async fn coprocessor_ffi_dispatch(
    backend: String,
    operation: String,
    payload: String,
) -> Result<String, String> {
    let start = std::time::Instant::now();

    // Resolve the backend enum.
    let copro_backend = CoproBackend::from_str(&backend);

    // Check FFI state.
    let ffi_available = {
        let guard = FFI_STATE.lock().map_err(|e| e.to_string())?;
        guard.loaded
            && copro_backend
                .map(|b| guard.available_backends.contains(&b))
                .unwrap_or(false)
    };

    let (route, result_str, success) = if ffi_available {
        // Dispatch via Zig FFI (C ABI call).
        //
        // TODO: Once libloading is in Cargo.toml, replace this with actual symbol call:
        //
        //   let guard = FFI_STATE.lock().map_err(|e| e.to_string())?;
        //   let lib = guard.library.as_ref().unwrap();
        //   let dispatch: libloading::Symbol<super::CoproDispatchFn> =
        //       unsafe { lib.get(b"copro_dispatch\0") }
        //           .map_err(|e| format!("Symbol not found: {}", e))?;
        //   let free: libloading::Symbol<super::CoproFreeFn> =
        //       unsafe { lib.get(b"copro_free\0") }
        //           .map_err(|e| format!("Symbol not found: {}", e))?;
        //
        //   let backend_u8 = copro_backend.unwrap() as u8;
        //   let op_cstr = std::ffi::CString::new(operation.as_str())
        //       .map_err(|e| e.to_string())?;
        //   let payload_cstr = std::ffi::CString::new(payload.as_str())
        //       .map_err(|e| e.to_string())?;
        //
        //   let result_ptr = unsafe {
        //       dispatch(backend_u8, op_cstr.as_ptr() as *const u8, payload_cstr.as_ptr() as *const u8)
        //   };
        //   let result_cstr = unsafe { std::ffi::CStr::from_ptr(result_ptr as *const i8) };
        //   let result_string = result_cstr.to_string_lossy().to_string();
        //   unsafe { free(result_ptr) };

        // --- Stub: simulate FFI dispatch ---
        let stub_result = format!(
            "{{\"backend\":\"{}\",\"operation\":\"{}\",\"result\":\"FFI stub result\",\"ffi\":true}}",
            backend, operation
        );
        ("ffi", stub_result, true)
    } else {
        // Fallback: dispatch via HTTP to Axiom.jl.
        match dispatch_via_ffi(&backend, &operation, &payload).await {
            Ok(r) => ("axiom", r, true),
            Err(e) => ("axiom", e, false),
        }
    };

    let duration_ms = start.elapsed().as_secs_f64() * 1000.0;

    let dispatch_result = FfiDispatchResult {
        route: route.to_string(),
        backend: backend.clone(),
        operation,
        result: result_str,
        duration_ms,
        success,
    };

    serde_json::to_string(&dispatch_result).map_err(|e| e.to_string())
}

/// Return the current FFI status — whether the library is loaded, which
/// backends are available locally, and system resource information.
#[tauri::command]
pub async fn coprocessor_ffi_status() -> Result<String, String> {
    let guard = FFI_STATE.lock().map_err(|e| e.to_string())?;

    let cpu_cores = std::thread::available_parallelism()
        .map(|p| p.get())
        .unwrap_or(1);
    let gpu_available = std::path::Path::new("/dev/dri/renderD128").exists()
        || std::path::Path::new("/dev/nvidia0").exists();
    let cpu_utilisation = super::read_cpu_utilisation();
    let gpu_memory_mb = super::estimate_gpu_memory_mb();

    let status = FfiStatusReport {
        ffi_loaded: guard.loaded,
        ffi_lib_path: guard.lib_path.clone(),
        available_backends: guard
            .available_backends
            .iter()
            .map(|b| b.label().to_string())
            .collect(),
        cpu_cores,
        gpu_available,
        cpu_utilisation,
        gpu_memory_mb,
    };

    serde_json::to_string(&status).map_err(|e| e.to_string())
}

// ============================================================================
// Phase 1 retained commands — kept for backward compatibility
// ============================================================================

/// Dispatch compute to local Zig FFI (Phase 2).
///
/// Checks if the .so exists and calls it. Falls back to a status message
/// if the FFI is not loaded.
#[tauri::command]
pub async fn coprocessor_dispatch_local(
    operation: String,
    input: String,
) -> Result<String, String> {
    let guard = FFI_STATE.lock().map_err(|e| e.to_string())?;

    if guard.loaded {
        drop(guard);
        // Delegate to the new Phase 2 dispatch.
        coprocessor_ffi_dispatch("maths".to_string(), operation, input).await
    } else {
        let so_exists = std::path::Path::new(FFI_SO_PATH).exists();
        if so_exists {
            let result = ComputeResult {
                operation: operation.clone(),
                result: format!(
                    "FFI .so exists but not loaded — call coprocessor_load_ffi first. op='{}' input='{}'",
                    operation, input
                ),
                duration_ms: 0.0,
                success: false,
            };
            serde_json::to_string(&result).map_err(|e| e.to_string())
        } else {
            Err(format!(
                "Zig FFI not built yet: {} does not exist. Run `zig build` in ffi/zig/ first.",
                FFI_SO_PATH
            ))
        }
    }
}

/// Check if the Zig FFI shared library is available (Phase 2).
///
/// Returns JSON with FFI status, CPU core count, and GPU availability.
#[tauri::command]
pub async fn coprocessor_check_ffi() -> Result<String, String> {
    // Delegate to the new status command for consistency.
    coprocessor_ffi_status().await
}

/// Run local compute benchmark (Phase 2).
///
/// Returns mock benchmark results (MFLOPS, memory bandwidth, latency).
/// When the Zig FFI is built, this will run actual compute benchmarks
/// via `copro_dispatch` with a "benchmark" operation.
#[tauri::command]
pub async fn coprocessor_benchmark() -> Result<String, String> {
    let guard = FFI_STATE.lock().map_err(|e| e.to_string())?;
    let ffi_available = guard.loaded;
    drop(guard);

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

/// Query local system resources — CPU utilisation, GPU memory (Phase 2).
///
/// Returns JSON with cpu_utilisation (0.0–1.0) and gpu_memory_mb.
#[tauri::command]
pub async fn coprocessor_local_resources() -> Result<String, String> {
    let cpu_utilisation = super::read_cpu_utilisation();
    let gpu_memory_mb = super::estimate_gpu_memory_mb();
    let guard = FFI_STATE.lock().map_err(|e| e.to_string())?;

    let result = serde_json::json!({
        "ffi_loaded": guard.loaded,
        "ffi_path": if guard.loaded { &guard.lib_path } else { FFI_SO_PATH },
        "cpu_utilisation": cpu_utilisation,
        "gpu_memory_mb": gpu_memory_mb,
        "pending_dispatches": 0,
    });

    Ok(result.to_string())
}

/// Smart dispatch — auto-selects local FFI vs remote based on availability.
///
/// Routing heuristic:
///   1. If Zig FFI loaded and operation is math/vector/tensor -> local FFI
///   2. If Axiom.jl is reachable -> remote HTTP
///   3. Fallback to BoJ cartridge
#[tauri::command]
pub async fn coprocessor_smart_dispatch(
    operation: String,
    payload: String,
) -> Result<String, String> {
    let start = std::time::Instant::now();

    let op_lower = operation.to_lowercase();
    let is_math = op_lower.contains("math")
        || op_lower.contains("vector")
        || op_lower.contains("matrix")
        || op_lower.contains("tensor");

    // Check FFI availability.
    let ffi_loaded = {
        let guard = FFI_STATE.lock().map_err(|e| e.to_string())?;
        guard.loaded
    };

    let (route, reason, compute_result) = if ffi_loaded && is_math {
        // Route through local Zig FFI — zero network round-trip.
        match coprocessor_ffi_dispatch("maths".to_string(), operation.clone(), payload).await {
            Ok(r) => ("local-ffi", "FFI loaded, math/vector operation", r),
            Err(e) => ("local-ffi", "FFI dispatch failed", e),
        }
    } else if ffi_loaded {
        // FFI loaded but non-math operation — still try FFI with appropriate backend.
        let backend = if op_lower.contains("crypto") {
            "crypto"
        } else if op_lower.contains("neural") {
            "neural"
        } else if op_lower.contains("audio") {
            "audio"
        } else if op_lower.contains("graphics") || op_lower.contains("render") {
            "graphics"
        } else if op_lower.contains("physics") {
            "physics"
        } else if op_lower.contains("quantum") {
            "quantum"
        } else if op_lower.contains("io") || op_lower.contains("file") {
            "io"
        } else {
            "maths"
        };
        match coprocessor_ffi_dispatch(backend.to_string(), operation.clone(), payload).await {
            Ok(r) => ("local-ffi", "FFI loaded, routed by operation type", r),
            Err(e) => ("local-ffi", "FFI dispatch error, falling back", e),
        }
    } else {
        // FFI not loaded — try remote engines.
        match query_axiom(&format!("{}:{}", operation, "")).await {
            Ok(r) => ("remote", "Axiom.jl available", r),
            Err(_) => {
                match query_boj(&operation).await {
                    Ok(r) => ("boj", "BoJ cartridge fallback", r),
                    Err(_) => (
                        "none",
                        "No compute engines available — load FFI or start Axiom.jl",
                        format!(
                            "{{\"operation\":\"{}\",\"result\":\"no engines available\",\"duration_ms\":0,\"success\":false}}",
                            operation
                        ),
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

// ============================================================================
// Internal helpers — HTTP queries to external engines
// ============================================================================

/// Dispatch via HTTP fallback when FFI is not available for a backend.
///
/// Tries Axiom.jl first, then BoJ as a fallback.
async fn dispatch_via_ffi(
    _backend: &str,
    operation: &str,
    _payload: &str,
) -> Result<String, String> {
    // Try Axiom.jl over HTTP.
    match query_axiom(operation).await {
        Ok(r) => Ok(r),
        Err(_) => {
            // Fall back to BoJ.
            query_boj(operation).await
        }
    }
}

/// Query Axiom.jl over HTTP.
async fn query_axiom(operation: &str) -> Result<String, String> {
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .map_err(|e| e.to_string())?;

    // panic-attack:allow insecure-protocol — localhost dev endpoint
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

    // panic-attack:allow insecure-protocol — localhost dev endpoint
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
        // panic-attack:allow insecure-protocol — localhost dev endpoint
        .get("http://127.0.0.1:7780/api/devices")
        .send()
        .await
        .map_err(|e| format!("Axiom.jl probe failed: {}", e))?;

    let text = resp
        .text()
        .await
        .map_err(|e| format!("Failed to read Axiom.jl devices: {}", e))?;

    // Try to parse as JSON array of device names.
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
        // Single device fallback.
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
        // panic-attack:allow insecure-protocol — localhost dev endpoint
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

// ============================================================================
// Legacy retained types (used by existing commands and tests)
// ============================================================================

/// FFI status report (legacy — Phase 1 format).
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

// ============================================================================
// Tests
// ============================================================================

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

    #[test]
    fn test_copro_backend_from_str() {
        assert_eq!(CoproBackend::from_str("maths"), Some(CoproBackend::Maths));
        assert_eq!(CoproBackend::from_str("VECTOR"), Some(CoproBackend::Vector));
        assert_eq!(CoproBackend::from_str("gfx"), Some(CoproBackend::Graphics));
        assert_eq!(CoproBackend::from_str("unknown"), None);
    }

    #[test]
    fn test_copro_backend_ordinals() {
        assert_eq!(CoproBackend::Maths as u8, 0);
        assert_eq!(CoproBackend::Vector as u8, 1);
        assert_eq!(CoproBackend::Io as u8, 9);
    }

    #[tokio::test]
    async fn test_coprocessor_ffi_status() {
        let result = coprocessor_ffi_status().await;
        assert!(result.is_ok());
        let json = result.unwrap();
        let status: FfiStatusReport = serde_json::from_str(&json).unwrap();
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
    async fn test_ffi_dispatch_result_serialization() {
        let r = FfiDispatchResult {
            route: "ffi".to_string(),
            backend: "maths".to_string(),
            operation: "matrix_multiply".to_string(),
            result: "[[1,0],[0,1]]".to_string(),
            duration_ms: 0.42,
            success: true,
        };
        let json = serde_json::to_string(&r).unwrap();
        assert!(json.contains("\"route\":\"ffi\""));
        assert!(json.contains("\"backend\":\"maths\""));
    }
}
