// SPDX-License-Identifier: MPL-2.0

//! Completion policy — derives panel lifecycle states from constraint satisfaction.
//!
//! Phase 4 of the constraint-core architecture. Converts the propagation engine's
//! satisfied/unsatisfied/blocked results into human-meaningful lifecycle states.
//!
//! States form a strict ordering:
//!   Draft -> Wired -> Viable -> Releasable
//!
//! Each state has entry requirements defined by which obligations must be satisfied.

use serde::{Deserialize, Serialize};

use crate::propagator::PropagationResult;

/// Panel lifecycle state derived from constraint satisfaction.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum PanelState {
    /// Contract exists but panel is not wired into the TEA loop.
    /// Entry: contract obligation satisfied.
    Draft,

    /// Panel is wired (registry + model + msg + view) but not tested.
    /// Entry: wired obligation satisfied.
    Wired,

    /// Panel is wired and has test coverage. Ready for use but not audited.
    /// Entry: wired + test obligations satisfied.
    Viable,

    /// All obligations satisfied. Panel is production-ready.
    /// Entry: complete obligation satisfied.
    Releasable,

    /// Contract exists but has errors that prevent classification.
    /// This is not a lifecycle state — it is an error condition.
    Broken,
}

impl PanelState {
    /// Human-readable label.
    pub fn label(&self) -> &'static str {
        match self {
            PanelState::Draft => "DRAFT",
            PanelState::Wired => "WIRED",
            PanelState::Viable => "VIABLE",
            PanelState::Releasable => "RELEASABLE",
            PanelState::Broken => "BROKEN",
        }
    }

    /// Terminal colour name for this state.
    pub fn color(&self) -> &'static str {
        match self {
            PanelState::Draft => "yellow",
            PanelState::Wired => "blue",
            PanelState::Viable => "cyan",
            PanelState::Releasable => "green",
            PanelState::Broken => "red",
        }
    }

    /// Whether this state allows the panel to be visible to users.
    pub fn is_visible(&self) -> bool {
        matches!(self, PanelState::Viable | PanelState::Releasable)
    }

    /// Whether this state allows the panel to be included in releases.
    pub fn is_releasable(&self) -> bool {
        matches!(self, PanelState::Releasable)
    }
}

/// Derive the panel state from propagation results.
///
/// Checks obligation satisfaction gates in reverse order (most permissive first):
/// - Releasable: completion_state satisfied
/// - Viable: panel_wired AND test_bundle satisfied
/// - Wired: panel_wired satisfied
/// - Draft: contract_exists satisfied
/// - Broken: none of the above
pub fn derive_panel_state(result: &PropagationResult) -> PanelState {
    let contract_ok = result
        .obligations
        .iter()
        .any(|o| o.kind_name() == "contract_exists" && o.is_satisfied());
    let wired_ok = result
        .obligations
        .iter()
        .any(|o| o.kind_name() == "panel_wired" && o.is_satisfied());
    let test_ok = result
        .obligations
        .iter()
        .any(|o| o.kind_name() == "test_bundle" && o.is_satisfied());
    let complete_ok = result
        .obligations
        .iter()
        .any(|o| o.kind_name() == "completion_state" && o.is_satisfied());

    if complete_ok {
        PanelState::Releasable
    } else if wired_ok && test_ok {
        PanelState::Viable
    } else if wired_ok {
        PanelState::Wired
    } else if contract_ok {
        PanelState::Draft
    } else {
        PanelState::Broken
    }
}

/// Policy decision for a panel based on its state.
#[derive(Debug, Clone, Serialize)]
pub struct PolicyDecision {
    /// The derived lifecycle state.
    pub state: PanelState,
    /// Whether the panel can be shown to users.
    pub visible: bool,
    /// Whether the panel can be included in releases.
    pub releasable: bool,
    /// What is needed to reach the next state.
    pub next_requirement: Option<String>,
}

/// Generate a policy decision from propagation results.
///
/// Derives the panel state from obligation satisfaction and produces
/// a decision struct with visibility, releasability, and guidance
/// on what is needed to advance to the next lifecycle state.
pub fn evaluate_policy(result: &PropagationResult) -> PolicyDecision {
    let state = derive_panel_state(result);

    let next_requirement = match state {
        PanelState::Broken => Some("Fix contract errors".to_string()),
        PanelState::Draft => {
            Some("Wire panel into TEA loop (registry, model, msg, view)".to_string())
        }
        PanelState::Wired => Some("Add test coverage".to_string()),
        PanelState::Viable => Some("Satisfy all remaining obligations".to_string()),
        PanelState::Releasable => None,
    };

    PolicyDecision {
        state,
        visible: state.is_visible(),
        releasable: state.is_releasable(),
        next_requirement,
    }
}
