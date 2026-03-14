// SPDX-License-Identifier: PMPL-1.0-or-later

//! Constraint propagation engine — evaluates obligations against repo facts.
//!
//! The propagator walks the obligation dependency graph in topological order,
//! running scanner checks for obligations whose dependencies are all satisfied,
//! and marking obligations as blocked when any upstream dependency has failed.
//! After propagation, it computes transitive downstream counts to identify
//! the primary bottleneck — the single root failure blocking the most work.

use crate::contract::PanelContract;
use crate::obligation::{FailureClass, Obligation, ObligationKind, ObligationStatus};
use crate::scanner::Scanner;
use std::collections::{HashMap, HashSet};

/// Summary statistics for a propagation run.
#[derive(Debug, Clone, serde::Serialize)]
pub struct PropagationSummary {
    /// Total number of obligations evaluated.
    pub total: usize,
    /// Obligations confirmed satisfied by the scanner.
    pub satisfied: usize,
    /// Obligations that failed their scanner check (root failures).
    pub unsatisfied: usize,
    /// Obligations blocked by upstream failures (derived failures).
    pub blocked: usize,
    /// ID of the obligation blocking the most downstream work (if any).
    pub primary_bottleneck: Option<String>,
}

/// Complete result of propagating obligations for one panel.
#[derive(Debug)]
pub struct PropagationResult {
    /// All obligations with updated status, failure_class, and messages.
    pub obligations: Vec<Obligation>,
    /// The panel contract these obligations were generated from.
    pub contract: PanelContract,
    /// Summary statistics.
    pub summary: PropagationSummary,
}

/// Run constraint propagation over a set of obligations for one panel.
///
/// The algorithm:
/// 1. Mark all obligations as `Unsatisfied`.
/// 2. For obligations with no unresolved deps, run the scanner check.
/// 3. For obligations with unsatisfied deps, mark as `Blocked` (derived).
/// 4. Compute `blocked_downstream_count` for each unsatisfied obligation.
/// 5. The obligation with the highest downstream count is the primary bottleneck.
///
/// This function is deterministic: same obligations + same repo state = same result.
pub fn propagate(
    mut obligations: Vec<Obligation>,
    contract: &PanelContract,
    scanner: &Scanner,
) -> PropagationResult {
    // Phase 1: Evaluate each obligation in dependency order.
    // Since the graph is a DAG with known structure (contract -> leaf -> wired),
    // we process in Vec order which is already topologically sorted by
    // `build_obligations`.

    // Build a status map for dependency lookups.
    let mut status_map: HashMap<String, ObligationStatus> = HashMap::new();

    for obligation in &mut obligations {
        // Check if all dependencies are satisfied.
        let all_deps_satisfied = obligation
            .depends_on
            .iter()
            .all(|dep_id| status_map.get(dep_id) == Some(&ObligationStatus::Satisfied));

        let any_dep_failed = obligation.depends_on.iter().any(|dep_id| {
            matches!(
                status_map.get(dep_id),
                Some(ObligationStatus::Unsatisfied) | Some(ObligationStatus::Blocked)
            )
        });

        if any_dep_failed {
            // Upstream failure — this obligation is blocked.
            obligation.status = ObligationStatus::Blocked;
            obligation.failure_class = Some(FailureClass::Derived);

            // Find which dependencies are the blockers.
            let blockers: Vec<String> = obligation
                .depends_on
                .iter()
                .filter(|dep_id| {
                    matches!(
                        status_map.get(*dep_id),
                        Some(ObligationStatus::Unsatisfied) | Some(ObligationStatus::Blocked)
                    )
                })
                .cloned()
                .collect();
            obligation.message = format!("Blocked by: {}", blockers.join(", "));
        } else if all_deps_satisfied {
            // All deps met — run the scanner check.
            let scan_result = run_check(obligation, contract, scanner);
            if scan_result {
                obligation.status = ObligationStatus::Satisfied;
                obligation.failure_class = None;
            } else {
                obligation.status = ObligationStatus::Unsatisfied;
                obligation.failure_class = Some(FailureClass::Root);
            }
        } else {
            // Should not happen with our DAG, but defensive.
            obligation.status = ObligationStatus::Unsatisfied;
            obligation.failure_class = Some(FailureClass::Root);
        }

        status_map.insert(obligation.id.clone(), obligation.status.clone());
    }

    // Phase 2: Compute blocked_downstream_count for each obligation.
    compute_downstream_counts(&mut obligations);

    // Phase 3: Find the primary bottleneck — the unsatisfied (root) obligation
    // with the highest blocked_downstream_count.
    let primary_bottleneck = obligations
        .iter()
        .filter(|o| o.failure_class == Some(FailureClass::Root))
        .max_by_key(|o| o.blocked_downstream_count)
        .map(|o| o.id.clone());

    // Phase 4: Build summary.
    let total = obligations.len();
    let satisfied = obligations
        .iter()
        .filter(|o| o.status == ObligationStatus::Satisfied)
        .count();
    let unsatisfied = obligations
        .iter()
        .filter(|o| o.failure_class == Some(FailureClass::Root))
        .count();
    let blocked = obligations
        .iter()
        .filter(|o| o.failure_class == Some(FailureClass::Derived))
        .count();

    PropagationResult {
        obligations,
        contract: contract.clone(),
        summary: PropagationSummary {
            total,
            satisfied,
            unsatisfied,
            blocked,
            primary_bottleneck,
        },
    }
}

/// Run the appropriate scanner check for an obligation kind.
///
/// Returns `true` if the obligation is satisfied.
fn run_check(obligation: &mut Obligation, contract: &PanelContract, scanner: &Scanner) -> bool {
    match obligation.kind {
        ObligationKind::ContractExists => {
            // The contract obligation is always satisfied if we got this far
            // (the contract was successfully parsed).
            obligation.message = "Contract file exists and parses".to_string();
            true
        }
        ObligationKind::RegistryEntry => {
            let result = scanner.check_registry(contract);
            if result.found {
                obligation.message = format!(
                    "Found in {}{}",
                    result.file,
                    result
                        .line
                        .map(|l| format!(":{l}"))
                        .unwrap_or_default()
                );
                obligation.file = Some(result.file);
                if let Some(line) = result.line {
                    obligation.message =
                        format!("Found at {}:{}", obligation.file.as_deref().unwrap(), line);
                }
            } else {
                obligation.message = format!(
                    "Not found in {}: expected `id: {}`",
                    result.file, contract.view_route
                );
                obligation.file = Some(result.file);
                obligation.expected = Some(format!("id: {}", contract.view_route));
            }
            result.found
        }
        ObligationKind::ModelSlice => {
            let result = scanner.check_model(contract);
            if result.found {
                obligation.message = format!(
                    "Found in {}{}",
                    result.file,
                    result
                        .line
                        .map(|l| format!(":{l}"))
                        .unwrap_or_default()
                );
                obligation.file = Some(result.file);
            } else {
                obligation.message = format!(
                    "Not found in {}: expected `include {}Model` and `{}:`",
                    result.file, contract.module_name, contract.model_slice
                );
                obligation.file = Some(result.file);
                obligation.expected = Some(format!(
                    "include {}Model + {}: in model record",
                    contract.module_name, contract.model_slice
                ));
            }
            result.found
        }
        ObligationKind::MsgNamespace => {
            let result = scanner.check_msg(contract);
            if result.found {
                obligation.message = format!(
                    "Found in {}{}",
                    result.file,
                    result
                        .line
                        .map(|l| format!(":{l}"))
                        .unwrap_or_default()
                );
                obligation.file = Some(result.file);
            } else {
                obligation.message = format!(
                    "Not found in {}: expected `type {}` and `{}({})`",
                    result.file,
                    contract.msg_namespace,
                    contract.module_name,
                    contract.msg_namespace
                );
                obligation.file = Some(result.file);
                obligation.expected = Some(format!(
                    "type {} = ... AND | {}({})",
                    contract.msg_namespace, contract.module_name, contract.msg_namespace
                ));
            }
            result.found
        }
        ObligationKind::ViewRoute => {
            let result = scanner.check_view_route(contract);
            if result.found {
                obligation.message = format!(
                    "Found in {}{}",
                    result.file,
                    result
                        .line
                        .map(|l| format!(":{l}"))
                        .unwrap_or_default()
                );
                obligation.file = Some(result.file);
            } else {
                obligation.message = format!(
                    "Not found in {}: expected `Some({})`",
                    result.file, contract.view_route
                );
                obligation.file = Some(result.file);
                obligation.expected = Some(format!("Some({}) =>", contract.view_route));
            }
            result.found
        }
        ObligationKind::PanelWired => {
            // This is a synthetic obligation — satisfied iff all deps are satisfied.
            // If we reached this check, all deps are satisfied.
            obligation.message = "All wiring points confirmed".to_string();
            true
        }
        ObligationKind::TestBundle => {
            // Check if test coverage is required by the contract.
            if !contract.requires_tests {
                obligation.message = "Tests not required by contract".to_string();
                return true;
            }
            let result = scanner.check_test_bundle(&contract.module_name);
            if result.found {
                obligation.message = format!("Found test file: {}", result.file);
                obligation.file = Some(result.file);
            } else {
                obligation.message = format!(
                    "Test file not found: {}",
                    result.file
                );
                obligation.file = Some(result.file);
                obligation.expected = Some(format!(
                    "tests/{}_engine_test.js",
                    contract.panel_id
                ));
            }
            result.found
        }
        ObligationKind::CompletionState => {
            // Purely derived — satisfied iff all deps are satisfied.
            // If we reached this check, all deps are satisfied.
            obligation.message = "All obligations satisfied — panel is complete".to_string();
            true
        }
    }
}

/// Compute `blocked_downstream_count` for every obligation.
///
/// For each unsatisfied or blocked obligation, count how many obligations
/// are transitively reachable via the `blocks` edges. This gives a
/// bottleneck ranking: the obligation with the highest count is the
/// single fix that would unblock the most downstream work.
fn compute_downstream_counts(obligations: &mut Vec<Obligation>) {
    // Build adjacency list from `blocks` edges.
    let blocks_map: HashMap<String, Vec<String>> = obligations
        .iter()
        .map(|o| (o.id.clone(), o.blocks.clone()))
        .collect();

    let unsatisfied_ids: HashSet<String> = obligations
        .iter()
        .filter(|o| o.status != ObligationStatus::Satisfied)
        .map(|o| o.id.clone())
        .collect();

    // For each obligation, compute transitive downstream count via BFS.
    let mut counts: HashMap<String, usize> = HashMap::new();

    for obligation in obligations.iter() {
        if obligation.failure_class != Some(FailureClass::Root) {
            continue;
        }

        let mut visited = HashSet::new();
        let mut queue = Vec::new();

        // Seed with direct blocks.
        if let Some(direct_blocks) = blocks_map.get(&obligation.id) {
            for blocked_id in direct_blocks {
                if unsatisfied_ids.contains(blocked_id) && visited.insert(blocked_id.clone()) {
                    queue.push(blocked_id.clone());
                }
            }
        }

        // BFS to find transitive downstream.
        let mut idx = 0;
        while idx < queue.len() {
            let current = queue[idx].clone();
            idx += 1;
            if let Some(next_blocks) = blocks_map.get(&current) {
                for next_id in next_blocks {
                    if unsatisfied_ids.contains(next_id) && visited.insert(next_id.clone()) {
                        queue.push(next_id.clone());
                    }
                }
            }
        }

        counts.insert(obligation.id.clone(), visited.len());
    }

    // Write counts back.
    for obligation in obligations.iter_mut() {
        if let Some(&count) = counts.get(&obligation.id) {
            obligation.blocked_downstream_count = count;
        }
    }
}
