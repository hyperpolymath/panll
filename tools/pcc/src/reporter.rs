// SPDX-License-Identifier: MPL-2.0

//! Terminal and JSON output for propagation results.
//!
//! Two output modes: coloured terminal output for human consumption,
//! and structured JSON for CI/CD and machine consumers. The terminal
//! format highlights the primary bottleneck and sorts obligations by
//! failure class (root first, then derived, then satisfied).

use crate::obligation::{FailureClass, ObligationKind, ObligationStatus};
use crate::policy::{self, PanelState};
use crate::propagator::PropagationResult;
use colored::Colorize;

/// Render a propagation result to the terminal with colours.
///
/// Layout:
/// - Header box with panel name, overall status, primary bottleneck
/// - ROOT FAILURES section (red) — fix these first
/// - DERIVED FAILURES section (yellow) — blocked by root failures
/// - SATISFIED section (green) — confirmed wiring points
pub fn render_terminal(result: &PropagationResult) {
    let panel_id = &result.contract.panel_id;
    let total = result.summary.total;
    let satisfied = result.summary.satisfied;

    let status_label = if satisfied == total {
        "COMPLETE".green().bold().to_string()
    } else {
        format!("INCOMPLETE ({}/{} satisfied)", satisfied, total)
            .red()
            .bold()
            .to_string()
    };

    let bottleneck_label = result
        .summary
        .primary_bottleneck
        .as_deref()
        .unwrap_or("none");

    // Derive lifecycle state from policy engine.
    let decision = policy::evaluate_policy(result);
    let state_label = match decision.state {
        PanelState::Draft => decision.state.label().yellow().bold().to_string(),
        PanelState::Wired => decision.state.label().blue().bold().to_string(),
        PanelState::Viable => decision.state.label().cyan().bold().to_string(),
        PanelState::Releasable => decision.state.label().green().bold().to_string(),
        PanelState::Broken => decision.state.label().red().bold().to_string(),
    };

    // Header box.
    let width = 56;
    println!("{}", "=".repeat(width).dimmed());
    println!(
        "{}",
        format!("  PanLL Panel Contract Compiler v0.1").bold()
    );
    println!("{}", "-".repeat(width).dimmed());
    println!("  Panel:              {}", panel_id.bold());
    println!("  Status:             {}", status_label);
    println!("  State:              {}", state_label);
    if satisfied < total {
        println!("  Primary bottleneck: {}", bottleneck_label.red().bold());
    }
    if let Some(ref next) = decision.next_requirement {
        println!("  Next:               {}", next.dimmed());
    }
    println!("{}", "=".repeat(width).dimmed());
    println!();

    // Collect obligations by failure class.
    let root_failures: Vec<_> = result
        .obligations
        .iter()
        .filter(|o| o.failure_class == Some(FailureClass::Root))
        .collect();

    let derived_failures: Vec<_> = result
        .obligations
        .iter()
        .filter(|o| o.failure_class == Some(FailureClass::Derived))
        .collect();

    let satisfied_obs: Vec<_> = result
        .obligations
        .iter()
        .filter(|o| o.status == ObligationStatus::Satisfied)
        .collect();

    // ROOT FAILURES.
    if !root_failures.is_empty() {
        println!(
            "{}",
            "ROOT FAILURES (fix these first)".red().bold().underline()
        );
        for o in &root_failures {
            let kind_label = kind_to_label(&o.kind);
            println!(
                "  {} {}  panel={}  file={}",
                "[ERROR]".red().bold(),
                kind_label.red(),
                o.panel_id,
                o.file.as_deref().unwrap_or("n/a")
            );
            println!("          {}", o.message.dimmed());
            if let Some(expected) = &o.expected {
                println!("          Expected: {}", expected.yellow());
            }
            println!(
                "          Repairability: {}",
                format!("{:?}", o.repairability).to_lowercase()
            );
            let downstream = o.blocked_downstream_count;
            if downstream > 0 {
                println!(
                    "          Blocks: {} downstream obligation{}",
                    downstream.to_string().red().bold(),
                    if downstream == 1 { "" } else { "s" }
                );
            }
            println!();
        }
    }

    // DERIVED FAILURES.
    if !derived_failures.is_empty() {
        println!(
            "{}",
            "DERIVED FAILURES (blocked by root failures above)"
                .yellow()
                .bold()
                .underline()
        );
        for o in &derived_failures {
            let kind_label = kind_to_label(&o.kind);
            println!(
                "  {} {}  panel={}",
                "[BLOCKED]".yellow().bold(),
                kind_label.yellow(),
                o.panel_id,
            );
            println!("          {}", o.message.dimmed());
            println!(
                "          {}",
                "Will resolve when root failures are fixed.".dimmed()
            );
            println!();
        }
    }

    // SATISFIED.
    if !satisfied_obs.is_empty() {
        println!("{}", "SATISFIED".green().bold().underline());
        for o in &satisfied_obs {
            let file_info = match (&o.file, &o.status) {
                (Some(f), ObligationStatus::Satisfied) => {
                    // Find the line from message if present.
                    format!("  ({})", f)
                }
                _ => String::new(),
            };
            println!(
                "  {} {}{}",
                "[OK]".green().bold(),
                o.id.green(),
                file_info.dimmed()
            );
        }
        println!();
    }
}

/// Render a propagation result as a JSON object.
///
/// The JSON structure is designed for machine consumption:
/// panel_id, status, summary, primary_bottleneck, and obligations array.
pub fn render_json(result: &PropagationResult) {
    let status = if result.summary.satisfied == result.summary.total {
        "complete"
    } else {
        "incomplete"
    };

    let decision = policy::evaluate_policy(result);

    let json = serde_json::json!({
        "panel_id": result.contract.panel_id,
        "status": status,
        "state": decision.state,
        "visible": decision.visible,
        "releasable": decision.releasable,
        "next_requirement": decision.next_requirement,
        "summary": {
            "total": result.summary.total,
            "satisfied": result.summary.satisfied,
            "unsatisfied": result.summary.unsatisfied,
            "blocked": result.summary.blocked,
        },
        "primary_bottleneck": result.summary.primary_bottleneck,
        "obligations": result.obligations.iter().map(|o| {
            serde_json::json!({
                "id": o.id,
                "kind": o.kind,
                "status": o.status,
                "failure_class": o.failure_class,
                "repairability": o.repairability,
                "message": o.message,
                "file": o.file,
                "expected": o.expected,
                "depends_on": o.depends_on,
                "blocked_downstream_count": o.blocked_downstream_count,
            })
        }).collect::<Vec<_>>(),
    });

    println!("{}", serde_json::to_string_pretty(&json).unwrap());
}

/// Render multiple propagation results as a JSON array.
///
/// Used when verifying all contracts at once with `--json`.
pub fn render_json_multi(results: &[PropagationResult]) {
    let panels: Vec<serde_json::Value> = results
        .iter()
        .map(|result| {
            let status = if result.summary.satisfied == result.summary.total {
                "complete"
            } else {
                "incomplete"
            };
            let decision = policy::evaluate_policy(result);
            serde_json::json!({
                "panel_id": result.contract.panel_id,
                "status": status,
                "state": decision.state,
                "visible": decision.visible,
                "releasable": decision.releasable,
                "next_requirement": decision.next_requirement,
                "summary": {
                    "total": result.summary.total,
                    "satisfied": result.summary.satisfied,
                    "unsatisfied": result.summary.unsatisfied,
                    "blocked": result.summary.blocked,
                },
                "primary_bottleneck": result.summary.primary_bottleneck,
                "obligations": result.obligations.iter().map(|o| {
                    serde_json::json!({
                        "id": o.id,
                        "kind": o.kind,
                        "status": o.status,
                        "failure_class": o.failure_class,
                        "repairability": o.repairability,
                        "message": o.message,
                        "file": o.file,
                        "expected": o.expected,
                        "depends_on": o.depends_on,
                        "blocked_downstream_count": o.blocked_downstream_count,
                    })
                }).collect::<Vec<_>>(),
            })
        })
        .collect();

    println!("{}", serde_json::to_string_pretty(&panels).unwrap());
}

/// Render a terminal summary across multiple panels.
///
/// Shows each panel result sequentially, then a final tally.
pub fn render_terminal_multi(results: &[PropagationResult]) {
    for result in results {
        render_terminal(result);
    }

    // Final tally with state distribution.
    let total_panels = results.len();

    // Count panels by lifecycle state.
    let mut releasable_count = 0usize;
    let mut viable_count = 0usize;
    let mut wired_count = 0usize;
    let mut draft_count = 0usize;
    let mut broken_count = 0usize;

    for result in results {
        match policy::derive_panel_state(result) {
            PanelState::Releasable => releasable_count += 1,
            PanelState::Viable => viable_count += 1,
            PanelState::Wired => wired_count += 1,
            PanelState::Draft => draft_count += 1,
            PanelState::Broken => broken_count += 1,
        }
    }

    println!("{}", "=".repeat(56).dimmed());
    println!("{}", "  SUMMARY".bold());
    println!("{}", "-".repeat(56).dimmed());
    println!(
        "  Panels verified: {}",
        total_panels.to_string().bold()
    );
    println!(
        "  Releasable:      {}",
        releasable_count.to_string().green().bold()
    );
    if viable_count > 0 {
        println!(
            "  Viable:          {}",
            viable_count.to_string().cyan().bold()
        );
    }
    if wired_count > 0 {
        println!(
            "  Wired:           {}",
            wired_count.to_string().blue().bold()
        );
    }
    if draft_count > 0 {
        println!(
            "  Draft:           {}",
            draft_count.to_string().yellow().bold()
        );
    }
    if broken_count > 0 {
        println!(
            "  Broken:          {}",
            broken_count.to_string().red().bold()
        );
    }
    println!("{}", "=".repeat(56).dimmed());
}

/// Convert an obligation kind to a human-readable label for terminal output.
fn kind_to_label(kind: &ObligationKind) -> &'static str {
    match kind {
        ObligationKind::ContractExists => "CONTRACT_MISSING",
        ObligationKind::RegistryEntry => "REGISTRY_MISSING",
        ObligationKind::ModelSlice => "MODEL_SLICE_MISSING",
        ObligationKind::MsgNamespace => "MSG_NAMESPACE_MISSING",
        ObligationKind::ViewRoute => "VIEW_ROUTE_MISSING",
        ObligationKind::PanelWired => "PANEL_NOT_WIRED",
        ObligationKind::TestBundle => "TEST_BUNDLE_MISSING",
        ObligationKind::ContractileHealth => "CONTRACTILE_UNHEALTHY",
        ObligationKind::CompletionState => "PANEL_INCOMPLETE",
    }
}
