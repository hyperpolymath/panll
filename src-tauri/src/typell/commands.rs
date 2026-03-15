// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! TypeLL server Tauri commands — type checking and type-level computation.

use serde_json::json;

// panic-attack:allow insecure-protocol — localhost dev endpoint
const DEFAULT_TYPELL_URL: &str = "http://localhost:7800/api/v1";

fn typell_url() -> String {
    std::env::var("TYPELL_URL").unwrap_or_else(|_| DEFAULT_TYPELL_URL.to_string())
}

fn client(timeout_secs: u64) -> Result<reqwest::blocking::Client, String> {
    reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(timeout_secs))
        .build()
        .map_err(|e| format!("HTTP client error: {}", e))
}

fn get(path: &str, timeout_secs: u64) -> Result<String, String> {
    let url = format!("{}{}", typell_url(), path);
    let c = client(timeout_secs)?;
    match c.get(&url).send() {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(body)
            } else {
                Err(format!("TypeLL returned {}: {}", status, body))
            }
        }
        Err(e) => Err(format!("TypeLL request failed ({}): {}", url, e)),
    }
}

fn post(path: &str, body: serde_json::Value, timeout_secs: u64) -> Result<String, String> {
    let url = format!("{}{}", typell_url(), path);
    let c = client(timeout_secs)?;
    match c.post(&url).json(&body).send() {
        Ok(resp) => {
            let status = resp.status();
            let text = resp.text().unwrap_or_default();
            if status.is_success() {
                Ok(text)
            } else {
                Err(format!("TypeLL returned {}: {}", status, text))
            }
        }
        Err(e) => Err(format!("TypeLL request failed ({}): {}", url, e)),
    }
}

/// GET /health — TypeLL server health check.
#[tauri::command]
pub fn typell_health() -> Result<String, String> {
    get("/health", 5)
}

/// POST /check — type-check a term or expression.
#[tauri::command]
pub fn typell_check(expression: String, context: Option<String>) -> Result<String, String> {
    let ctx: serde_json::Value = context
        .and_then(|c| serde_json::from_str(&c).ok())
        .unwrap_or(json!({}));
    post("/check", json!({"expression": expression, "context": ctx}), 30)
}

/// POST /infer — infer the type of an expression.
#[tauri::command]
pub fn typell_infer(expression: String) -> Result<String, String> {
    post("/infer", json!({"expression": expression}), 30)
}

/// POST /refine — apply refinement types to a specification.
#[tauri::command]
pub fn typell_refine(spec: String, constraints: Option<String>) -> Result<String, String> {
    let cons: serde_json::Value = constraints
        .and_then(|c| serde_json::from_str(&c).ok())
        .unwrap_or(json!([]));
    post("/refine", json!({"spec": spec, "constraints": cons}), 30)
}

/// POST /compute — evaluate a type-level computation.
#[tauri::command]
pub fn typell_compute(term: String) -> Result<String, String> {
    post("/compute", json!({"term": term}), 30)
}

/// GET /signatures — list available type signatures.
#[tauri::command]
pub fn typell_list_signatures() -> Result<String, String> {
    get("/signatures", 10)
}

/// GET /universes — get type universe hierarchy.
#[tauri::command]
pub fn typell_universes() -> Result<String, String> {
    get("/universes", 10)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn typell_url_default_and_override() {
        std::env::remove_var("TYPELL_URL");
        assert_eq!(typell_url(), DEFAULT_TYPELL_URL);
        let custom = "http://typell.local:9999/v2";
        std::env::set_var("TYPELL_URL", custom);
        assert_eq!(typell_url(), custom);
        std::env::remove_var("TYPELL_URL");
    }
}
