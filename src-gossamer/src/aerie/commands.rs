// SPDX-License-Identifier: MPL-2.0

//! Aerie Tauri commands — network diagnostics from the Tauri backend.
//!
//! Commands:
//!   - `aerie_get_latency`: Measure TCP connection latency to a target host.
//!   - `aerie_speed_test`: Download speed test using reqwest.
//!
//! These run in-process (no external service needed) using std::net for
//! latency and reqwest for download throughput measurement.

use std::net::TcpStream;
use std::time::Instant;
use serde_json::json;

/// Default target for latency probes. Override with AERIE_LATENCY_TARGET env var.
/// Format: "host:port".
fn latency_target() -> String {
    std::env::var("AERIE_LATENCY_TARGET")
        .unwrap_or_else(|_| "1.1.1.1:443".to_string())
}

/// Default URL for speed test downloads. Override with AERIE_SPEED_URL env var.
/// Uses a small Cloudflare endpoint by default to keep test duration short.
fn speed_test_url() -> String {
    std::env::var("AERIE_SPEED_URL")
        .unwrap_or_else(|_| "https://speed.cloudflare.com/__down?bytes=1000000".to_string())
}

/// Measure TCP connection latency to a configurable target.
///
/// Opens a TCP connection to the target and measures the time to establish
/// the connection. Returns JSON with `latency_ms`, `target`, and `status`
/// fields. On failure, returns `status: "unreachable"` with the error.
///
/// The 5-second connect_timeout prevents this from blocking the Tauri async
/// runtime for too long. For a truly non-blocking version, this would need
/// tokio::net::TcpStream, but the timeout keeps it safe enough for a panel
/// probe that runs on user action.

pub async fn aerie_get_latency() -> Result<String, String> {
    let target = latency_target();
    let addr: std::net::SocketAddr = target
        .parse()
        .map_err(|e| format!("Invalid target address '{target}': {e}"))?;

    let start = Instant::now();
    match TcpStream::connect_timeout(&addr, std::time::Duration::from_secs(5)) {
        Ok(_conn) => {
            let elapsed = start.elapsed();
            Ok(json!({
                "latency_ms": elapsed.as_secs_f64() * 1000.0,
                "target": target,
                "status": "reachable",
            })
            .to_string())
        }
        Err(e) => {
            Ok(json!({
                "latency_ms": null,
                "target": target,
                "status": "unreachable",
                "error": format!("{e}"),
            })
            .to_string())
        }
    }
}

/// Simple download speed test using reqwest.
///
/// Downloads a 1 MB payload from the configured URL and measures throughput.
/// Returns JSON with `speed_mbps`, `bytes_downloaded`, `duration_ms`, and
/// `status` fields. On failure, returns `status: "failed"` with the error.

pub async fn aerie_speed_test() -> Result<String, String> {
    let url = speed_test_url();
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(30))
        .build()
        .map_err(|e| format!("HTTP client error: {e}"))?;

    let start = Instant::now();
    match client.get(&url).send().await {
        Ok(resp) => {
            let bytes = resp.bytes().await.map_err(|e| format!("Download error: {e}"))?;
            let elapsed = start.elapsed();
            let bytes_count = bytes.len() as f64;
            let duration_secs = elapsed.as_secs_f64();
            // Convert to megabits per second: (bytes * 8) / (seconds * 1_000_000).
            let speed_mbps = (bytes_count * 8.0) / (duration_secs * 1_000_000.0);

            Ok(json!({
                "speed_mbps": format!("{speed_mbps:.2}").parse::<f64>().unwrap_or(speed_mbps),
                "bytes_downloaded": bytes_count as u64,
                "duration_ms": elapsed.as_millis(),
                "url": url,
                "status": "completed",
            })
            .to_string())
        }
        Err(e) => {
            Ok(json!({
                "speed_mbps": null,
                "bytes_downloaded": 0,
                "duration_ms": 0,
                "url": url,
                "status": "failed",
                "error": format!("{e}"),
            })
            .to_string())
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_latency_target_default() {
        // Should return the default target when env var is not set.
        // (May be overridden in CI, so just check it's non-empty.)
        let target = latency_target();
        assert!(!target.is_empty());
    }

    #[test]
    fn test_speed_test_url_default() {
        let url = speed_test_url();
        assert!(url.starts_with("https://"));
    }

    #[tokio::test]
    async fn test_aerie_get_latency_returns_json() {
        // Should return valid JSON regardless of network availability.
        let result = aerie_get_latency().await;
        assert!(result.is_ok());
        let json: serde_json::Value = serde_json::from_str(&result.unwrap()).unwrap();
        assert!(json.get("target").is_some());
        assert!(json.get("status").is_some());
    }
}
