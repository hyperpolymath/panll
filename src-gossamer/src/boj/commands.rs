// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! BoJ server Tauri commands — cartridge management and service discovery.

use serde_json::json;

// panic-attack:allow insecure-protocol — localhost dev endpoint
const DEFAULT_BOJ_URL: &str = "http://localhost:7700";

fn boj_url() -> String {
    std::env::var("BOJ_URL").unwrap_or_else(|_| DEFAULT_BOJ_URL.to_string())
}

fn client(timeout_secs: u64) -> Result<reqwest::blocking::Client, String> {
    reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(timeout_secs))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))
}

fn get(path: &str, timeout_secs: u64) -> Result<String, String> {
    let url = format!("{}{}", boj_url(), path);
    let c = client(timeout_secs)?;
    match c.get(&url).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(body)
            } else {
                Err(format!("BoJ returned {}: {}", status, body))
            }
        }
        Err(e) => Err(format!("BoJ request failed ({}): {}", url, e)),
    }
}

fn post(path: &str, body: serde_json::Value, timeout_secs: u64) -> Result<String, String> {
    let url = format!("{}{}", boj_url(), path);
    let c = client(timeout_secs)?;
    match c.post(&url).json(&body).send() {
        Ok(resp) => {
            let status = resp.status();
            let text = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(text)
            } else {
                Err(format!("BoJ returned {}: {}", status, text))
            }
        }
        Err(e) => Err(format!("BoJ request failed ({}): {}", url, e)),
    }
}

/// GET /health — BoJ server health check.

pub fn boj_health() -> Result<String, String> {
    get("/health", 5)
}

/// GET /cartridges — list all loaded cartridges.

pub fn boj_list_cartridges() -> Result<String, String> {
    get("/cartridges", 10)
}

/// GET /cartridges/{name} — get details of a specific cartridge.

pub fn boj_get_cartridge(name: String) -> Result<String, String> {
    get(&format!("/cartridges/{}", name), 10)
}

/// POST /cartridges/{name}/load — load a cartridge.

pub fn boj_load_cartridge(name: String) -> Result<String, String> {
    post(&format!("/cartridges/{}/load", name), json!({}), 30)
}

/// POST /cartridges/{name}/unload — unload a cartridge.

pub fn boj_unload_cartridge(name: String) -> Result<String, String> {
    post(&format!("/cartridges/{}/unload", name), json!({}), 10)
}

/// GET /topology — get the BoJ service topology matrix.

pub fn boj_topology() -> Result<String, String> {
    get("/topology", 10)
}

/// POST /cartridges/{name}/invoke — invoke a cartridge tool/function.

pub fn boj_invoke(name: String, tool: String, args: Option<String>) -> Result<String, String> {
    let parsed_args: serde_json::Value = args
        .and_then(|a| serde_json::from_str(&a).ok())
        .unwrap_or(json!({}));
    post(
        &format!("/cartridges/{}/invoke", name),
        json!({"tool": tool, "args": parsed_args}),
        60,
    )
}

/// GET /umoja — get Umoja federation runtime status.

pub fn boj_umoja_status() -> Result<String, String> {
    get("/umoja/status", 10)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn boj_url_default_and_override() {
        std::env::remove_var("BOJ_URL");
        assert_eq!(boj_url(), DEFAULT_BOJ_URL);
        let custom = "http://boj.local:9999/v2";
        std::env::set_var("BOJ_URL", custom);
        assert_eq!(boj_url(), custom);
        std::env::remove_var("BOJ_URL");
    }
}
