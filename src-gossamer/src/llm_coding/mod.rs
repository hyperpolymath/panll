// SPDX-License-Identifier: PMPL-1.0-or-later
//
// PanLL LLM Coding — multi-session Claude/LLM coordinator.
//
// This module provides the headed supervisor for parallel LLM coding sessions.
// It spawns terminal processes running `claude` (or other LLMs), monitors their
// resource usage, manages workspace locks, gates destructive actions, and
// tracks task completion across sessions.
//
// Architecture:
//   - Runs as an axum HTTP server on port 7900
//   - Each session = a `konsole -e claude "task..."` process
//   - Coordination state lives in ~/.claude/coordination/
//   - Resource monitoring reads /proc for memory/CPU per-PID
//   - Workspace locks are advisory (filesystem-based)
//
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

pub mod types;
pub mod commands;
