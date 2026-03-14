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
