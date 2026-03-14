// SPDX-License-Identifier: PMPL-1.0-or-later

//! PanLL Panel Contract Compiler (PCC) — constraint verifier for panel wiring.
//!
//! PCC is a read-only verifier that validates panel wiring contracts against
//! the actual PanLL repository source files. It reads TOML contract files
//! declaring how each panel should be wired (registry, model, msg, view),
//! scans the .res source files for evidence, propagates constraints through
//! a dependency graph, and reports root failures with bottleneck ranking.
//!
//! Usage:
//!   panll panel verify                     # verify all contracts
//!   panll panel verify --panel MyLang      # verify single panel
//!   panll panel verify --json              # JSON output
//!   panll panel doctor --json              # alias for verify --json (all panels)
//!   panll panel repair --panel Wharf       # dry-run repair preview
//!   panll panel repair --panel Wharf --apply  # apply repairs

mod contract;
mod obligation;
mod policy;
mod propagator;
mod repairer;
mod reporter;
mod scanner;

use clap::{Parser, Subcommand};
use std::path::PathBuf;
use std::process;

/// PanLL Panel Contract Compiler — constraint verifier for panel wiring.
#[derive(Parser, Debug)]
#[command(name = "panll", version = "0.1.0")]
#[command(about = "PanLL Panel Contract Compiler — verifies panel wiring contracts against repo reality")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

/// Top-level subcommands.
#[derive(Subcommand, Debug)]
enum Commands {
    /// Panel wiring verification and diagnostics.
    Panel {
        #[command(subcommand)]
        action: PanelAction,
    },
}

/// Panel subcommands.
#[derive(Subcommand, Debug)]
enum PanelAction {
    /// Verify panel wiring contracts against repo source files.
    Verify {
        /// Verify only the named panel (default: all panels).
        #[arg(long)]
        panel: Option<String>,

        /// Output JSON instead of coloured terminal output.
        #[arg(long)]
        json: bool,

        /// Path to the PanLL repository root (default: current directory).
        #[arg(long, default_value = ".")]
        repo_root: PathBuf,

        /// Path to the contracts directory (default: contracts/).
        #[arg(long, default_value = "contracts/")]
        contracts_dir: PathBuf,
    },

    /// Run full diagnostics on all panels (alias for verify --json).
    Doctor {
        /// Output JSON instead of coloured terminal output.
        #[arg(long, default_value_t = true)]
        json: bool,

        /// Path to the PanLL repository root (default: current directory).
        #[arg(long, default_value = ".")]
        repo_root: PathBuf,

        /// Path to the contracts directory (default: contracts/).
        #[arg(long, default_value = "contracts/")]
        contracts_dir: PathBuf,
    },

    /// Repair unsatisfied panel wiring obligations (dry-run by default).
    ///
    /// Generates and optionally applies file patches for root failures
    /// with `repairability = Safe`. Requires `--panel` for safety.
    Repair {
        /// Repair only the named panel (required for safety).
        #[arg(long)]
        panel: String,

        /// Actually apply repairs (default: dry-run preview only).
        #[arg(long)]
        apply: bool,

        /// Path to the PanLL repository root (default: current directory).
        #[arg(long, default_value = ".")]
        repo_root: PathBuf,

        /// Path to the contracts directory (default: contracts/).
        #[arg(long, default_value = "contracts/")]
        contracts_dir: PathBuf,
    },
}

fn main() {
    let cli = Cli::parse();

    match cli.command {
        Commands::Panel { action } => match action {
            PanelAction::Verify {
                panel,
                json,
                repo_root,
                contracts_dir,
            } => run_verify(panel, json, repo_root, contracts_dir),
            PanelAction::Doctor {
                json,
                repo_root,
                contracts_dir,
            } => run_verify(None, json, repo_root, contracts_dir),
            PanelAction::Repair {
                panel,
                apply,
                repo_root,
                contracts_dir,
            } => run_repair(panel, apply, repo_root, contracts_dir),
        },
    }
}

/// Execute the verify pipeline: load contracts, build obligations, propagate, report.
fn run_verify(panel_filter: Option<String>, json: bool, repo_root: PathBuf, contracts_dir: PathBuf) {
    // Resolve contracts directory relative to repo root if not absolute.
    let contracts_path = if contracts_dir.is_absolute() {
        contracts_dir
    } else {
        repo_root.join(&contracts_dir)
    };

    // Load all contract files.
    let contract_results = match contract::load_contracts_from_dir(&contracts_path) {
        Ok(results) => results,
        Err(err) => {
            eprintln!(
                "Error reading contracts directory {}: {}",
                contracts_path.display(),
                err
            );
            process::exit(1);
        }
    };

    // Collect successfully parsed contracts, reporting parse errors.
    let mut contracts = Vec::new();
    let mut had_errors = false;

    for result in contract_results {
        match result {
            Ok(c) => {
                if contract::matches_filter(&c, &panel_filter) {
                    contracts.push(c);
                }
            }
            Err(err) => {
                eprintln!("Warning: {}", err);
                had_errors = true;
            }
        }
    }

    if contracts.is_empty() {
        if let Some(ref filter) = panel_filter {
            eprintln!("No contract found for panel '{}'", filter);
        } else {
            eprintln!(
                "No contract files found in {}",
                contracts_path.display()
            );
        }
        process::exit(1);
    }

    // Create the scanner.
    let scanner = scanner::Scanner::new(&repo_root);

    // Process each contract.
    let mut results = Vec::new();

    for contract_item in &contracts {
        let obligations = obligation::build_obligations(contract_item);
        let result = propagator::propagate(obligations, contract_item, &scanner);
        results.push(result);
    }

    // Report.
    if json {
        if results.len() == 1 {
            reporter::render_json(&results[0]);
        } else {
            reporter::render_json_multi(&results);
        }
    } else if results.len() == 1 {
        reporter::render_terminal(&results[0]);
    } else {
        reporter::render_terminal_multi(&results);
    }

    // Exit with non-zero if any panel is incomplete.
    let all_complete = results
        .iter()
        .all(|r| r.summary.satisfied == r.summary.total);

    if had_errors || !all_complete {
        process::exit(1);
    }
}

/// Execute the repair pipeline: load contract, verify, generate plans, optionally apply.
///
/// Flow:
/// 1. Load single contract (--panel is required).
/// 2. Run verify to find unsatisfied obligations.
/// 3. If all satisfied: "Nothing to repair".
/// 4. If unsatisfied: generate repair plans.
/// 5. If --apply: apply patches, then re-verify.
/// 6. If no --apply: show dry-run preview.
fn run_repair(panel: String, apply: bool, repo_root: PathBuf, contracts_dir: PathBuf) {
    use colored::Colorize;

    // Resolve contracts directory relative to repo root if not absolute.
    let contracts_path = if contracts_dir.is_absolute() {
        contracts_dir
    } else {
        repo_root.join(&contracts_dir)
    };

    // Load all contract files and find the one matching --panel.
    let contract_results = match contract::load_contracts_from_dir(&contracts_path) {
        Ok(results) => results,
        Err(err) => {
            eprintln!(
                "Error reading contracts directory {}: {}",
                contracts_path.display(),
                err
            );
            process::exit(1);
        }
    };

    let panel_filter = Some(panel.clone());
    let mut target_contract = None;

    for result in contract_results {
        match result {
            Ok(c) => {
                if contract::matches_filter(&c, &panel_filter) {
                    target_contract = Some(c);
                }
            }
            Err(err) => {
                eprintln!("Warning: {}", err);
            }
        }
    }

    let contract = match target_contract {
        Some(c) => c,
        None => {
            eprintln!("No contract found for panel '{}'", panel);
            process::exit(1);
        }
    };

    // Run the verify pipeline to find current state.
    let scanner = scanner::Scanner::new(&repo_root);
    let obligations = obligation::build_obligations(&contract);
    let result = propagator::propagate(obligations, &contract, &scanner);

    // If all satisfied, nothing to do.
    if result.summary.satisfied == result.summary.total {
        println!();
        println!(
            "Panel: {} — {} ({}/{} satisfied)",
            contract.panel_id,
            "COMPLETE".green().bold(),
            result.summary.satisfied,
            result.summary.total,
        );
        println!("Nothing to repair.");
        println!();
        return;
    }

    // Generate repair plans for root failures with Safe repairability.
    let plans = repairer::generate_repair_plans(&result.obligations, &contract);

    if plans.is_empty() {
        eprintln!(
            "No safe repairs available for panel '{}'. Manual intervention required.",
            panel
        );
        process::exit(1);
    }

    if apply {
        // Apply repairs.
        let results = repairer::apply_repairs(&plans, &panel, &repo_root);

        // Check for any failures.
        let any_failed = results
            .iter()
            .any(|r| matches!(r, repairer::RepairResult::Failed(_)));

        if any_failed {
            eprintln!("{}", "Some repairs failed. Check output above.".red());
            process::exit(1);
        }

        // Re-verify to confirm repairs worked.
        println!("{}", "Re-verifying...".dimmed());
        println!();

        let scanner = scanner::Scanner::new(&repo_root);
        let obligations = obligation::build_obligations(&contract);
        let re_result = propagator::propagate(obligations, &contract, &scanner);

        if re_result.summary.satisfied == re_result.summary.total {
            println!(
                "Panel: {} — {} ({}/{} satisfied)",
                contract.panel_id,
                "COMPLETE".green().bold(),
                re_result.summary.satisfied,
                re_result.summary.total,
            );
            println!("{}", "All repairs successful.".green().bold());
        } else {
            reporter::render_terminal(&re_result);
            println!(
                "{}",
                "Some obligations remain unsatisfied after repair."
                    .yellow()
                    .bold()
            );
            process::exit(1);
        }
        println!();
    } else {
        // Dry-run: show preview only.
        repairer::render_dry_run(&plans, &panel);
    }
}
