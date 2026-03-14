// SPDX-License-Identifier: PMPL-1.0-or-later

//! Obligation types and dependency graph construction.
//!
//! Each panel contract produces a set of obligations that must be satisfied
//! for the panel to be correctly wired into the PanLL TEA architecture.
//! Obligations form a directed acyclic graph: `contract` is the root,
//! `registry`, `model`, `msg`, and `view` depend on it, and `wired`
//! depends on all four leaf obligations.

use crate::contract::PanelContract;

/// The kind of check an obligation represents.
#[derive(Debug, Clone, PartialEq, Eq, serde::Serialize)]
#[serde(rename_all = "snake_case")]
pub enum ObligationKind {
    /// The contract TOML file itself exists and parses.
    ContractExists,
    /// The panel is registered in PanelRegistry.res.
    RegistryEntry,
    /// The model slice field exists in Model.res.
    ModelSlice,
    /// The message namespace type exists in Msg.res.
    MsgNamespace,
    /// The view route case exists in View.res.
    ViewRoute,
    /// All four wiring points are satisfied — panel is fully wired.
    PanelWired,
    /// Test file exists for this panel's engine.
    TestBundle,
    /// All required obligations satisfied — panel is complete.
    CompletionState,
}

/// Whether an obligation passed, failed, or is blocked by upstream failures.
#[derive(Debug, Clone, PartialEq, Eq, serde::Serialize)]
#[serde(rename_all = "snake_case")]
pub enum ObligationStatus {
    /// The scanner confirmed the obligation is met.
    Satisfied,
    /// The scanner could not find the expected evidence.
    Unsatisfied,
    /// One or more upstream dependencies are unsatisfied.
    Blocked,
}

/// Classifies whether a failure is the original cause or a downstream effect.
#[derive(Debug, Clone, PartialEq, Eq, serde::Serialize)]
#[serde(rename_all = "snake_case")]
pub enum FailureClass {
    /// This obligation failed on its own — the scanner found no evidence.
    Root,
    /// This obligation is blocked because an upstream dependency failed.
    Derived,
}

/// How safely the missing wiring could be repaired.
#[derive(Debug, Clone, PartialEq, Eq, serde::Serialize)]
#[serde(rename_all = "snake_case")]
pub enum Repairability {
    /// Can be repaired by adding a single declaration.
    Safe,
    /// Repair requires modifying existing code or types.
    Unsafe,
    /// Requires manual intervention — cannot be automated.
    Manual,
}

/// A single wiring obligation for a panel.
///
/// Obligations are identified by a unique `id` string (e.g. "registry:MyLang")
/// and track their satisfaction status, dependency relationships, and
/// diagnostic information for the reporter.
#[derive(Debug, Clone, serde::Serialize)]
pub struct Obligation {
    /// Unique identifier (e.g. "contract:MyLang", "registry:MyLang").
    pub id: String,

    /// What kind of check this obligation represents.
    pub kind: ObligationKind,

    /// Which panel this obligation belongs to.
    pub panel_id: String,

    /// Current satisfaction status (set by the propagator).
    pub status: ObligationStatus,

    /// Whether this is a root or derived failure (None if satisfied).
    pub failure_class: Option<FailureClass>,

    /// How safely this could be repaired (always set for context).
    pub repairability: Repairability,

    /// IDs of obligations this one depends on.
    pub depends_on: Vec<String>,

    /// IDs of obligations that are directly blocked by this one (computed).
    pub blocks: Vec<String>,

    /// Total count of transitively blocked downstream obligations (computed).
    pub blocked_downstream_count: usize,

    /// Human-readable diagnostic message.
    pub message: String,

    /// Relevant source file (relative to repo root).
    pub file: Option<String>,

    /// What was expected to be found in the source file.
    pub expected: Option<String>,
}

impl Obligation {
    /// Returns the string name of the obligation kind.
    pub fn kind_name(&self) -> &str {
        match self.kind {
            ObligationKind::ContractExists => "contract_exists",
            ObligationKind::RegistryEntry => "registry_entry",
            ObligationKind::ModelSlice => "model_slice",
            ObligationKind::MsgNamespace => "msg_namespace",
            ObligationKind::ViewRoute => "view_route",
            ObligationKind::PanelWired => "panel_wired",
            ObligationKind::TestBundle => "test_bundle",
            ObligationKind::CompletionState => "completion_state",
        }
    }

    /// Returns true if the obligation status is `Satisfied`.
    pub fn is_satisfied(&self) -> bool {
        self.status == ObligationStatus::Satisfied
    }
}

/// Build the full obligation graph for a single panel contract.
///
/// Returns 8 obligations per panel in dependency order:
/// - `contract:{id}` (root, no deps)
/// - `registry:{id}` (depends on contract)
/// - `model:{id}` (depends on contract)
/// - `msg:{id}` (depends on contract)
/// - `view:{id}` (depends on contract)
/// - `wired:{id}` (depends on registry, model, msg, view)
/// - `test:{id}` (depends on contract)
/// - `complete:{id}` (depends on wired + test)
pub fn build_obligations(contract: &PanelContract) -> Vec<Obligation> {
    let id = &contract.panel_id;

    let contract_id = format!("contract:{id}");
    let registry_id = format!("registry:{id}");
    let model_id = format!("model:{id}");
    let msg_id = format!("msg:{id}");
    let view_id = format!("view:{id}");
    let wired_id = format!("wired:{id}");
    let test_id = format!("test:{id}");
    let complete_id = format!("complete:{id}");

    vec![
        Obligation {
            id: contract_id.clone(),
            kind: ObligationKind::ContractExists,
            panel_id: id.clone(),
            status: ObligationStatus::Unsatisfied,
            failure_class: None,
            repairability: Repairability::Safe,
            depends_on: vec![],
            blocks: vec![
                registry_id.clone(),
                model_id.clone(),
                msg_id.clone(),
                view_id.clone(),
                test_id.clone(),
            ],
            blocked_downstream_count: 0,
            message: String::new(),
            file: None,
            expected: None,
        },
        Obligation {
            id: registry_id.clone(),
            kind: ObligationKind::RegistryEntry,
            panel_id: id.clone(),
            status: ObligationStatus::Unsatisfied,
            failure_class: None,
            repairability: Repairability::Safe,
            depends_on: vec![contract_id.clone()],
            blocks: vec![wired_id.clone()],
            blocked_downstream_count: 0,
            message: String::new(),
            file: Some("src/modules/PanelRegistry.res".to_string()),
            expected: Some(format!("id: {}", contract.view_route)),
        },
        Obligation {
            id: model_id.clone(),
            kind: ObligationKind::ModelSlice,
            panel_id: id.clone(),
            status: ObligationStatus::Unsatisfied,
            failure_class: None,
            repairability: Repairability::Safe,
            depends_on: vec![contract_id.clone()],
            blocks: vec![wired_id.clone()],
            blocked_downstream_count: 0,
            message: String::new(),
            file: Some("src/Model.res".to_string()),
            expected: Some(format!(
                "include {}Model AND {}: in model record",
                contract.module_name, contract.model_slice
            )),
        },
        Obligation {
            id: msg_id.clone(),
            kind: ObligationKind::MsgNamespace,
            panel_id: id.clone(),
            status: ObligationStatus::Unsatisfied,
            failure_class: None,
            repairability: Repairability::Safe,
            depends_on: vec![contract_id.clone()],
            blocks: vec![wired_id.clone()],
            blocked_downstream_count: 0,
            message: String::new(),
            file: Some("src/Msg.res".to_string()),
            expected: Some(format!(
                "type {} AND | {}({})",
                contract.msg_namespace, contract.module_name, contract.msg_namespace
            )),
        },
        Obligation {
            id: view_id.clone(),
            kind: ObligationKind::ViewRoute,
            panel_id: id.clone(),
            status: ObligationStatus::Unsatisfied,
            failure_class: None,
            repairability: Repairability::Safe,
            depends_on: vec![contract_id.clone()],
            blocks: vec![wired_id.clone()],
            blocked_downstream_count: 0,
            message: String::new(),
            file: Some("src/View.res".to_string()),
            expected: Some(format!("Some({}) =>", contract.view_route)),
        },
        Obligation {
            id: wired_id.clone(),
            kind: ObligationKind::PanelWired,
            panel_id: id.clone(),
            status: ObligationStatus::Unsatisfied,
            failure_class: None,
            repairability: Repairability::Manual,
            depends_on: vec![registry_id, model_id, msg_id, view_id],
            blocks: vec![complete_id.clone()],
            blocked_downstream_count: 0,
            message: String::new(),
            file: None,
            expected: None,
        },
        Obligation {
            id: test_id.clone(),
            kind: ObligationKind::TestBundle,
            panel_id: id.clone(),
            status: ObligationStatus::Unsatisfied,
            failure_class: None,
            repairability: Repairability::Safe,
            depends_on: vec![contract_id],
            blocks: vec![complete_id.clone()],
            blocked_downstream_count: 0,
            message: String::new(),
            file: None,
            expected: None,
        },
        Obligation {
            id: complete_id,
            kind: ObligationKind::CompletionState,
            panel_id: id.clone(),
            status: ObligationStatus::Unsatisfied,
            failure_class: None,
            repairability: Repairability::Manual,
            depends_on: vec![wired_id, test_id],
            blocks: vec![],
            blocked_downstream_count: 0,
            message: String::new(),
            file: None,
            expected: None,
        },
    ]
}
