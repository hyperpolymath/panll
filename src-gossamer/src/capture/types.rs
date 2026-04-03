// SPDX-License-Identifier: PMPL-1.0-or-later

//! Capture types — serde-compatible structs for screenshots, recordings, demos.

#![allow(dead_code)]

use serde::{Deserialize, Serialize};

/// Format for captured images.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum CaptureFormat {
    Png,
    Pdf,
    Svg,
}

/// A captured screenshot or recording entry.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CaptureEntry {
    pub id: String,
    pub panel_id: String,
    pub label: String,
    pub file_path: String,
    pub format: CaptureFormat,
    pub timestamp: f64,
    pub width: u32,
    pub height: u32,
    pub is_recording: bool,
    pub duration_seconds: f64,
}

/// A step in a demo sequence.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DemoStep {
    pub step_number: u32,
    pub description: String,
    pub capture_id: String,
    pub state_snapshot: String,
    pub timestamp: f64,
}

/// A complete demo package.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DemoPackage {
    pub id: String,
    pub title: String,
    pub author: String,
    pub description: String,
    pub panel_id: String,
    pub steps: Vec<DemoStep>,
    pub created: f64,
    pub file_path: Option<String>,
}

// ---------------------------------------------------------------------------
// Smoke tests — serde round-trips for capture types
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn smoke_capture_format_roundtrip() {
        let formats = [CaptureFormat::Png, CaptureFormat::Pdf, CaptureFormat::Svg];
        for fmt in formats {
            let json = serde_json::to_string(&fmt).expect("serialise CaptureFormat must succeed");
            let _back: CaptureFormat = serde_json::from_str(&json).expect("deserialise must succeed");
        }
    }

    #[test]
    fn smoke_capture_entry_roundtrip() {
        let entry = CaptureEntry {
            id: "cap-001".to_string(),
            panel_id: "panel-l".to_string(),
            label: "Initial state".to_string(),
            file_path: "/tmp/cap-001.png".to_string(),
            format: CaptureFormat::Png,
            timestamp: 1_700_000_000.0,
            width: 1920,
            height: 1080,
            is_recording: false,
            duration_seconds: 0.0,
        };
        let json = serde_json::to_string(&entry).expect("serialise must succeed");
        let back: CaptureEntry = serde_json::from_str(&json).expect("deserialise must succeed");
        assert_eq!(back.id, "cap-001");
        assert_eq!(back.width, 1920);
        assert_eq!(back.height, 1080);
        assert!(!back.is_recording);
    }

    #[test]
    fn smoke_demo_package_empty_steps() {
        let pkg = DemoPackage {
            id: "demo-001".to_string(),
            title: "Getting Started".to_string(),
            author: "Jonathan D.A. Jewell".to_string(),
            description: "Basic demo".to_string(),
            panel_id: "panel-w".to_string(),
            steps: vec![],
            created: 1_700_000_000.0,
            file_path: None,
        };
        assert!(pkg.steps.is_empty());
        assert!(pkg.file_path.is_none());
    }

    #[test]
    fn smoke_demo_step_roundtrip() {
        let step = DemoStep {
            step_number: 1,
            description: "Open the workspace".to_string(),
            capture_id: "cap-001".to_string(),
            state_snapshot: r#"{"mode":"EverythingMode"}"#.to_string(),
            timestamp: 1_700_000_001.0,
        };
        let json = serde_json::to_string(&step).expect("serialise must succeed");
        let back: DemoStep = serde_json::from_str(&json).expect("deserialise must succeed");
        assert_eq!(back.step_number, 1);
    }
}
