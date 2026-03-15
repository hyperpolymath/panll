// SPDX-License-Identifier: PMPL-1.0-or-later

//! Unified error module for the PanLL Tauri backend.
//!
//! Provides a single `PanllError` enum that covers all common failure modes
//! across panels: I/O, JSON serialisation, mutex poisoning, missing resources,
//! invalid input, network faults, and internal bugs. Every variant carries
//! enough context for a human-readable error message.
//!
//! Tauri commands return `Result<T, String>`, so the module also provides
//! [`to_tauri_result`] to convert `Result<T, PanllError>` at the command
//! boundary, and an `Into<String>` impl for direct use with `.map_err()`.

use std::fmt;
use std::sync::PoisonError;

/// Unified error type for PanLL backend operations.
///
/// Covers filesystem I/O, JSON (de)serialisation, mutex lock failures,
/// resource look-ups, input validation, network calls, and an internal
/// catch-all for anything that doesn't fit a more specific variant.
#[derive(Debug)]
pub enum PanllError {
    /// Filesystem operation failed (read, write, create_dir, etc.).
    Io(std::io::Error),

    /// JSON serialisation or deserialisation failed.
    Json(serde_json::Error),

    /// A mutex lock was poisoned (previous holder panicked).
    Lock(String),

    /// A requested resource (file, session, recording, checkpoint, …) was not found.
    NotFound(String),

    /// The caller supplied an invalid or out-of-range parameter.
    InvalidInput(String),

    /// An HTTP or network request failed.
    Network(String),

    /// Catch-all for internal logic errors that don't fit another variant.
    Internal(String),
}

// ---------------------------------------------------------------------------
// Display — user-friendly formatting
// ---------------------------------------------------------------------------

impl fmt::Display for PanllError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            PanllError::Io(e) => write!(f, "I/O error: {e}"),
            PanllError::Json(e) => write!(f, "JSON error: {e}"),
            PanllError::Lock(msg) => write!(f, "Lock poisoned: {msg}"),
            PanllError::NotFound(msg) => write!(f, "Not found: {msg}"),
            PanllError::InvalidInput(msg) => write!(f, "Invalid input: {msg}"),
            PanllError::Network(msg) => write!(f, "Network error: {msg}"),
            PanllError::Internal(msg) => write!(f, "Internal error: {msg}"),
        }
    }
}

// ---------------------------------------------------------------------------
// std::error::Error — enables ? chaining and anyhow/eyre interop
// ---------------------------------------------------------------------------

impl std::error::Error for PanllError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            PanllError::Io(e) => Some(e),
            PanllError::Json(e) => Some(e),
            _ => None,
        }
    }
}

// ---------------------------------------------------------------------------
// From impls — allow `?` to auto-convert common error types
// ---------------------------------------------------------------------------

impl From<std::io::Error> for PanllError {
    fn from(e: std::io::Error) -> Self {
        PanllError::Io(e)
    }
}

impl From<serde_json::Error> for PanllError {
    fn from(e: serde_json::Error) -> Self {
        PanllError::Json(e)
    }
}

impl<T> From<PoisonError<T>> for PanllError {
    fn from(e: PoisonError<T>) -> Self {
        PanllError::Lock(e.to_string())
    }
}

// ---------------------------------------------------------------------------
// Into<String> — needed for Tauri command returns (Result<T, String>)
// ---------------------------------------------------------------------------

impl From<PanllError> for String {
    fn from(e: PanllError) -> Self {
        e.to_string()
    }
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

/// Convert a `PanllError` result to a `String` result for Tauri command boundaries.
///
/// Tauri commands must return `Result<T, String>`. This helper lets internal
/// functions use the richer `PanllError` type and convert at the boundary:
///
/// ```rust,ignore
/// #[tauri::command]
/// pub async fn my_command() -> Result<String, String> {
///     to_tauri_result(do_work())
/// }
/// ```
pub fn to_tauri_result<T>(result: Result<T, PanllError>) -> Result<T, String> {
    result.map_err(|e| e.to_string())
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_display_io() {
        let err = PanllError::Io(std::io::Error::new(
            std::io::ErrorKind::NotFound,
            "file missing",
        ));
        assert_eq!(err.to_string(), "I/O error: file missing");
    }

    #[test]
    fn test_display_not_found() {
        let err = PanllError::NotFound("session abc-123".to_string());
        assert_eq!(err.to_string(), "Not found: session abc-123");
    }

    #[test]
    fn test_display_invalid_input() {
        let err = PanllError::InvalidInput("negative grid width".to_string());
        assert_eq!(err.to_string(), "Invalid input: negative grid width");
    }

    #[test]
    fn test_display_network() {
        let err = PanllError::Network("connection refused".to_string());
        assert_eq!(err.to_string(), "Network error: connection refused");
    }

    #[test]
    fn test_display_internal() {
        let err = PanllError::Internal("unexpected state".to_string());
        assert_eq!(err.to_string(), "Internal error: unexpected state");
    }

    #[test]
    fn test_display_lock() {
        let err = PanllError::Lock("VM mutex poisoned".to_string());
        assert_eq!(err.to_string(), "Lock poisoned: VM mutex poisoned");
    }

    #[test]
    fn test_from_io_error() {
        let io_err = std::io::Error::new(std::io::ErrorKind::PermissionDenied, "denied");
        let panll_err: PanllError = io_err.into();
        assert!(matches!(panll_err, PanllError::Io(_)));
    }

    #[test]
    fn test_from_json_error() {
        let json_err = serde_json::from_str::<serde_json::Value>("not json").unwrap_err();
        let panll_err: PanllError = json_err.into();
        assert!(matches!(panll_err, PanllError::Json(_)));
    }

    #[test]
    fn test_from_poison_error() {
        // Simulate a poisoned mutex by panicking inside a lock.
        let mutex = std::sync::Mutex::new(42);
        let _ = std::panic::catch_unwind(|| {
            let _guard = mutex.lock().unwrap();
            panic!("intentional panic to poison mutex");
        });
        let poison_result = mutex.lock();
        assert!(poison_result.is_err());
        let panll_err: PanllError = poison_result.unwrap_err().into();
        assert!(matches!(panll_err, PanllError::Lock(_)));
    }

    #[test]
    fn test_into_string() {
        let err = PanllError::NotFound("widget xyz".to_string());
        let s: String = err.into();
        assert_eq!(s, "Not found: widget xyz");
    }

    #[test]
    fn test_to_tauri_result_ok() {
        let result: Result<i32, PanllError> = Ok(42);
        let tauri_result = to_tauri_result(result);
        assert_eq!(tauri_result, Ok(42));
    }

    #[test]
    fn test_to_tauri_result_err() {
        let result: Result<i32, PanllError> =
            Err(PanllError::Internal("boom".to_string()));
        let tauri_result = to_tauri_result(result);
        assert_eq!(tauri_result, Err("Internal error: boom".to_string()));
    }
}
