// SPDX-License-Identifier: PMPL-1.0-or-later
//
// LLM Coding types — shared between Tauri commands and the coordination daemon.
//
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

use serde::{Deserialize, Serialize};

/// LLM provider for a coding session.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum LlmProvider {
    /// Claude Code (Anthropic CLI).
    Claude,
    /// Another LLM via CLI command.
    Other { name: String, command: String },
}

/// Lifecycle state of a spawned session.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(tag = "state")]
pub enum SessionState {
    Starting,
    Active,
    Frozen,
    Completed,
    Failed { reason: String },
    Killed,
}

/// Snapshot of a session's resource consumption.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ResourceUsage {
    /// Resident memory in megabytes.
    pub memory_mb: u64,
    /// CPU usage percentage (0-100).
    pub cpu_percent: f64,
    /// Number of child processes (subagents).
    pub subagent_count: u32,
}

/// Resource limits enforced on a session.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResourceLimits {
    /// Maximum RSS in megabytes before freeze.
    pub max_memory_mb: u64,
    /// Maximum CPU percentage before warning.
    pub max_cpu_percent: f64,
    /// Maximum concurrent subagents.
    pub max_subagents: u32,
}

impl Default for ResourceLimits {
    fn default() -> Self {
        Self {
            max_memory_mb: 4096,
            max_cpu_percent: 80.0,
            max_subagents: 3,
        }
    }
}

/// A workspace lock preventing concurrent access to a path.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkspaceLock {
    /// Path being locked.
    pub path: String,
    /// Session ID holding the lock.
    pub held_by: String,
    /// When the lock was acquired (ISO 8601).
    pub acquired_at: String,
    /// Whether this is an exclusive (write) lock.
    pub exclusive: bool,
}

/// A pending destructive action requiring supervisor approval.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PendingAction {
    /// Unique action ID.
    pub id: String,
    /// Session requesting the action.
    pub session_id: String,
    /// Human-readable description.
    pub description: String,
    /// Action category.
    pub category: String,
    /// When the request was made (ISO 8601).
    pub requested_at: String,
}

/// A cross-session message.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SessionMessage {
    /// Source session ID.
    pub from_session: String,
    /// Message content.
    pub content: String,
    /// When sent (timestamp).
    pub sent_at: u64,
}

/// A task in the shared task list.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SharedTask {
    /// Unique task ID.
    pub id: String,
    /// Task description.
    pub description: String,
    /// Current status.
    pub status: TaskStatus,
    /// Session assigned to this task (if any).
    pub assigned_to: Option<String>,
    /// When completed (if done).
    pub completed_at: Option<String>,
}

/// Task completion state.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum TaskStatus {
    Pending,
    InProgress,
    Done,
    Skipped,
    Blocked(String),
}

/// Request to spawn a new session.
#[derive(Debug, Clone, Deserialize)]
pub struct SpawnRequest {
    /// Human-readable session name.
    pub name: String,
    /// Working directory.
    pub work_dir: String,
    /// Newline-separated task list.
    pub task_list: String,
    /// Task description.
    pub task: String,
    /// Constraints for the task.
    pub constraints: Option<String>,
    /// Context for the task.
    pub context: Option<String>,
    /// Repos this session may touch.
    pub allowed_repos: Vec<String>,
    /// Profile to use.
    pub profile: Option<String>,
}

/// A managed LLM coding session.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LlmSession {
    /// Unique session ID (UUID).
    pub id: String,
    /// Human-readable name.
    pub name: String,
    /// LLM provider.
    pub provider: LlmProvider,
    /// Current state.
    pub state: SessionState,
    /// OS process ID of the terminal.
    pub pid: Option<u32>,
    /// Working directory.
    pub work_dir: String,
    /// Repos this session may touch.
    pub allowed_repos: Vec<String>,
    /// Current resource usage.
    pub resources: ResourceUsage,
    /// Resource limits.
    pub limits: ResourceLimits,
    /// Task list.
    pub tasks: Vec<SharedTask>,
    /// Session messages.
    pub messages: Vec<SessionMessage>,
    /// When spawned (timestamp).
    pub created_at: u64,
}

/// System-wide resource snapshot.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SystemResources {
    /// Available memory in MB.
    pub memory_available_mb: u64,
    /// Total memory in MB.
    pub memory_total_mb: u64,
    /// Overall CPU usage percentage.
    pub cpu_percent: f64,
}
