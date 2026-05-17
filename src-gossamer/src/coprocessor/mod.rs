// SPDX-License-Identifier: PMPL-1.0-or-later

//! PanLL Coprocessor Control Plane — queries external compute engines
//! (Axiom.jl, BoJ cartridges) and discovers available devices.
//!
//! Phase 1: Control plane — orchestrates external compute over HTTP/IPC.
//! Phase 2: Data plane — local Zig FFI dispatch via shared library loading,
//!          eliminating HTTP round-trips for supported backends.

pub mod commands;

use serde::{Deserialize, Serialize};
use std::sync::Mutex;

/// Coprocessor backend identifiers, matching the ReScript CoprocessorsModel
/// variants. The `u8` wire value is used in the Zig FFI C ABI.
///
/// | Value | Backend   |
/// |-------|-----------|
/// | 0     | Maths     |
/// | 1     | Vector    |
/// | 2     | Tensor    |
/// | 3     | Physics   |
/// | 4     | Crypto    |
/// | 5     | Neural    |
/// | 6     | Quantum   |
/// | 7     | Audio     |
/// | 8     | Graphics  |
/// | 9     | IO        |
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[repr(u8)]
pub enum CoproBackend {
    Maths = 0,
    Vector = 1,
    Tensor = 2,
    Physics = 3,
    Crypto = 4,
    Neural = 5,
    Quantum = 6,
    Audio = 7,
    Graphics = 8,
    Io = 9,
}

impl CoproBackend {
    /// Parse a backend name string into a `CoproBackend`.
    pub fn from_str(s: &str) -> Option<Self> {
        match s.to_lowercase().as_str() {
            "maths" | "math" => Some(Self::Maths),
            "vector" | "vec" => Some(Self::Vector),
            "tensor" | "ten" => Some(Self::Tensor),
            "physics" | "phy" => Some(Self::Physics),
            "crypto" | "cry" => Some(Self::Crypto),
            "neural" | "neu" => Some(Self::Neural),
            "quantum" | "qua" => Some(Self::Quantum),
            "audio" | "aud" => Some(Self::Audio),
            "graphics" | "gfx" => Some(Self::Graphics),
            "io" => Some(Self::Io),
            _ => None,
        }
    }

    /// All ten backends, in ordinal order.
    pub fn all() -> &'static [CoproBackend; 10] {
        &[
            Self::Maths,
            Self::Vector,
            Self::Tensor,
            Self::Physics,
            Self::Crypto,
            Self::Neural,
            Self::Quantum,
            Self::Audio,
            Self::Graphics,
            Self::Io,
        ]
    }

    /// Human-readable label.
    pub fn label(&self) -> &'static str {
        match self {
            Self::Maths => "Maths",
            Self::Vector => "Vector",
            Self::Tensor => "Tensor",
            Self::Physics => "Physics",
            Self::Crypto => "Crypto",
            Self::Neural => "Neural",
            Self::Quantum => "Quantum",
            Self::Audio => "Audio",
            Self::Graphics => "Graphics",
            Self::Io => "I/O",
        }
    }
}

// ---------------------------------------------------------------------------
// FFI State — holds the dynamically loaded Zig shared library and its symbols.
// ---------------------------------------------------------------------------

/// Type alias for the `copro_dispatch` FFI function pointer.
///
/// Signature matches: `copro_dispatch(backend: u8, op: *const u8, payload: *const u8) -> *mut u8`
/// The returned pointer is heap-allocated by Zig and must be freed with `copro_free`.
///
/// NOTE: These are type aliases for documentation. Actual symbol loading uses
/// `libloading::Library::get` with the correct signature at call-site.
pub type CoproDispatchFn =
    unsafe extern "C" fn(backend: u8, op: *const u8, payload: *const u8) -> *mut u8;

/// Type alias for `copro_free(ptr: *mut u8)` — frees a Zig-allocated result string.
pub type CoproFreeFn = unsafe extern "C" fn(ptr: *mut u8);

/// Type alias for `copro_init() -> i32` — initialise the coprocessor library.
pub type CoproInitFn = unsafe extern "C" fn() -> i32;

/// Type alias for `copro_deinit()` — tear down the coprocessor library.
pub type CoproDeinitFn = unsafe extern "C" fn();

/// Runtime state for the loaded Zig FFI shared library.
///
/// Wrapped in a `Mutex` and stored as a global static so that Gossamer command
/// handlers (which are async and may run on different threads) can safely
/// access it.
pub struct FfiState {
    /// Whether a library has been successfully loaded and initialised.
    pub loaded: bool,

    /// Filesystem path to the loaded `.so` / `.dylib` / `.dll`.
    pub lib_path: String,

    /// Which backends the loaded library reports as available.
    /// Populated after calling `copro_init`.
    pub available_backends: Vec<CoproBackend>,

    /// The dynamically loaded library. Keeping it here keeps the `.so`
    /// mapped and its symbols valid for the lifetime of the process.
    /// Symbols are resolved per-call from this handle (the safe pattern —
    /// no self-referential `'static` symbol storage).
    pub library: Option<libloading::Library>,
}

impl FfiState {
    /// Create an empty (unloaded) FFI state.
    pub fn new() -> Self {
        Self {
            loaded: false,
            lib_path: String::new(),
            available_backends: Vec::new(),
            library: None,
        }
    }
}

impl Default for FfiState {
    fn default() -> Self {
        Self::new()
    }
}

/// Global FFI state, protected by a Mutex for thread-safe access from Gossamer
/// command handlers.
///
/// Usage from commands:
/// ```rust,ignore
/// let guard = FFI_STATE.lock().map_err(|e| e.to_string())?;
/// if guard.loaded { /* dispatch via FFI */ }
/// ```
pub static FFI_STATE: once_cell::sync::Lazy<Mutex<FfiState>> =
    once_cell::sync::Lazy::new(|| Mutex::new(FfiState::new()));

// ---------------------------------------------------------------------------
// CPU utilisation monitoring.
// ---------------------------------------------------------------------------

/// Read CPU utilisation from `/proc/loadavg` (Linux).
///
/// Returns a value in 0.0..=1.0 representing 1-minute load average normalised
/// by available CPU cores. Returns 0.0 on non-Linux or if the file is unreadable.
pub fn read_cpu_utilisation() -> f64 {
    let cpu_cores = std::thread::available_parallelism()
        .map(|p| p.get())
        .unwrap_or(1);

    if let Ok(contents) = std::fs::read_to_string("/proc/loadavg") {
        if let Some(first) = contents.split_whitespace().next() {
            let load = first.parse::<f64>().unwrap_or(0.0);
            return (load / cpu_cores as f64).min(1.0);
        }
    }
    0.0
}

/// Read available GPU memory in megabytes.
///
/// Checks for DRI render nodes (AMD/Intel) or NVIDIA device files.
/// Returns a rough estimate — actual memory detection requires vendor-specific
/// APIs (vulkaninfo, nvidia-smi, etc.) which Phase 3 will add.
pub fn estimate_gpu_memory_mb() -> u64 {
    if std::path::Path::new("/dev/nvidia0").exists() {
        // NVIDIA GPU present — assume 4 GiB as a conservative default.
        4096
    } else if std::path::Path::new("/dev/dri/renderD128").exists() {
        // AMD/Intel integrated or discrete GPU — assume 2 GiB.
        2048
    } else {
        0
    }
}
