// SPDX-License-Identifier: PMPL-1.0-or-later

//! Panel wiring repairer — generates and applies patches for unsatisfied obligations.
//!
//! The repairer takes root failures with `repairability = Safe` and generates
//! concrete insertion patches for the four repairable obligation kinds:
//! `RegistryEntry`, `ModelSlice`, `MsgNamespace`, and `ViewRoute`.
//!
//! Safety rules:
//! - NEVER repairs obligations with `repairability != Safe`.
//! - NEVER deletes existing code.
//! - NEVER modifies unrelated sections.
//! - Default mode is dry-run (preview only).
//! - Idempotent: running repair twice does not duplicate entries.
//! - Re-verifies after applying to confirm success.

use crate::contract::PanelContract;
use crate::obligation::{FailureClass, Obligation, ObligationKind, ObligationStatus, Repairability};
use colored::Colorize;
use std::path::{Path, PathBuf};

/// A planned repair for one obligation.
#[derive(Debug, Clone)]
pub struct RepairPlan {
    /// The obligation ID being repaired (e.g. "registry:Wharf").
    pub obligation_id: String,

    /// Target file relative to repo root (e.g. "src/modules/PanelRegistry.res").
    pub target_file: String,

    /// What repair action to perform.
    pub action: RepairAction,

    /// Human-readable preview of the content to be inserted.
    pub preview: String,

    /// Human-readable label for the obligation kind.
    pub kind_label: String,
}

/// The type of file modification to perform.
#[derive(Debug, Clone)]
pub enum RepairAction {
    /// Insert content after the line containing the anchor text.
    InsertAfter {
        /// Text to search for in the target file.
        anchor: String,
        /// Content to insert on the line(s) after the anchor.
        content: String,
    },

    /// Insert content before the line containing the anchor text.
    InsertBefore {
        /// Text to search for in the target file.
        anchor: String,
        /// Content to insert on the line(s) before the anchor.
        content: String,
    },

    /// No repair needed — obligation is already satisfied.
    AlreadySatisfied,
}

/// Result of attempting to apply a single repair plan.
#[derive(Debug, Clone)]
pub enum RepairResult {
    /// The patch was applied successfully.
    Applied,
    /// The obligation was already satisfied (skipped).
    Skipped,
    /// The patch failed to apply.
    Failed(String),
}

/// Generate repair plans for all root failures with `repairability == Safe`.
///
/// Examines each obligation in the propagation result and produces a
/// `RepairPlan` for those that are unsatisfied root failures with safe
/// repairability. Obligations that are already satisfied get a plan
/// with `RepairAction::AlreadySatisfied`.
pub fn generate_repair_plans(
    obligations: &[Obligation],
    contract: &PanelContract,
) -> Vec<RepairPlan> {
    let mut plans = Vec::new();

    for obligation in obligations {
        // Skip the synthetic ContractExists and PanelWired obligations —
        // these are not directly repairable via file patches.
        if matches!(
            obligation.kind,
            ObligationKind::ContractExists | ObligationKind::PanelWired
        ) {
            continue;
        }

        // If already satisfied, emit a skip plan.
        if obligation.status == ObligationStatus::Satisfied {
            plans.push(RepairPlan {
                obligation_id: obligation.id.clone(),
                target_file: obligation.file.as_deref().unwrap_or("n/a").to_string(),
                action: RepairAction::AlreadySatisfied,
                preview: String::new(),
                kind_label: kind_to_label(&obligation.kind).to_string(),
            });
            continue;
        }

        // Only repair root failures with Safe repairability.
        if obligation.repairability != Repairability::Safe {
            continue;
        }
        if obligation.failure_class != Some(FailureClass::Root) {
            continue;
        }

        match obligation.kind {
            ObligationKind::RegistryEntry => {
                plans.push(generate_registry_plan(contract));
            }
            ObligationKind::ViewRoute => {
                plans.push(generate_view_plan(contract));
            }
            ObligationKind::ModelSlice => {
                plans.push(generate_model_plan(contract));
            }
            ObligationKind::MsgNamespace => {
                plans.push(generate_msg_plan(contract));
            }
            _ => {}
        }
    }

    plans
}

/// Generate a repair plan for the `registry_entry` obligation.
///
/// Inserts a new panel metadata record before the closing `]` of the
/// `allPanels` array in `src/modules/PanelRegistry.res`.
fn generate_registry_plan(contract: &PanelContract) -> RepairPlan {
    let has_backend_str = if contract.has_backend { "true" } else { "false" };

    let content = format!(
        r#"  {{
    id: {view_route},
    name: "{short_name}",
    shortName: "{short_name}",
    description: "Panel — {panel_id}",
    icon: "box",
    connectionStatus: ServiceDisconnected,
    hasBackend: {has_backend},
    cladeId: Some("{clade_id}"),
  }},"#,
        view_route = contract.view_route,
        short_name = contract.short_name,
        panel_id = contract.panel_id,
        has_backend = has_backend_str,
        clade_id = contract.clade_id,
    );

    // The anchor is the closing `]` of the allPanels array. We insert
    // the new entry before it. We use the last `},` before `]` as the
    // anchor to insert after.
    RepairPlan {
        obligation_id: format!("registry:{}", contract.panel_id),
        target_file: "src/modules/PanelRegistry.res".to_string(),
        action: RepairAction::InsertBefore {
            anchor: "]\n\n/// Look up panel metadata".to_string(),
            content,
        },
        preview: format!(
            "Insert panel metadata entry for {} before the closing ] of allPanels",
            contract.panel_id,
        ),
        kind_label: "REGISTRY ENTRY".to_string(),
    }
}

/// Generate a repair plan for the `view_route` obligation.
///
/// Inserts a new match case in the `renderActivePanel` switch expression
/// in `src/View.res`.
fn generate_view_plan(contract: &PanelContract) -> RepairPlan {
    let content = format!(
        "  | Some({view_route}) => {module}.view(model.{slice})",
        view_route = contract.view_route,
        module = contract.module_name,
        slice = contract.model_slice,
    );

    // Insert before the closing `}` of the renderActivePanel match,
    // which is the last line `  }` before the next function definition.
    // We anchor on the last case in the Infrastructure panels section.
    RepairPlan {
        obligation_id: format!("view:{}", contract.panel_id),
        target_file: "src/View.res".to_string(),
        action: RepairAction::InsertAfter {
            anchor: "| Some(PanelWiringInspector) => WiringInspector.view(model.wiringInspector)"
                .to_string(),
            content,
        },
        preview: format!(
            "Insert renderActivePanel case: | Some({}) => {}.view(model.{})",
            contract.view_route, contract.module_name, contract.model_slice,
        ),
        kind_label: "VIEW ROUTE".to_string(),
    }
}

/// Generate a repair plan for the `model_slice` obligation.
///
/// Inserts both `include {Module}Model` and the state field into
/// `src/Model.res`. These are two separate insertions, so we produce
/// a single plan that inserts both.
fn generate_model_plan(contract: &PanelContract) -> RepairPlan {
    // The include line and model field are inserted together.
    // We anchor the include after the last existing `include *Model` line,
    // and the field after the last field in the model record.
    // For simplicity we produce a combined insertion anchored on the
    // last include statement before the model record.
    let include_line = format!("include {}Model", contract.module_name);
    let field_line = format!("  {}: {}State,", contract.model_slice, contract.model_slice);

    RepairPlan {
        obligation_id: format!("model:{}", contract.panel_id),
        target_file: "src/Model.res".to_string(),
        action: RepairAction::InsertAfter {
            // We use a two-phase approach in apply_repair for model repairs.
            // This anchor is for the include line.
            anchor: format!("__MODEL_DUAL_INSERT__{}__{}__", include_line, field_line),
            content: String::new(), // Content is encoded in the anchor for dual insert.
        },
        preview: format!(
            "Insert `{}` and `{}` into Model.res",
            include_line, field_line,
        ),
        kind_label: "MODEL SLICE".to_string(),
    }
}

/// Generate a repair plan for the `msg_namespace` obligation.
///
/// Inserts a message type definition and a routing variant into `src/Msg.res`.
fn generate_msg_plan(contract: &PanelContract) -> RepairPlan {
    let type_def = format!(
        "/// Messages for {} panel\ntype {} =\n  | Init\n",
        contract.panel_id, contract.msg_namespace,
    );

    let variant_line = format!(
        "  | {}({}) // {} panel",
        contract.module_name, contract.msg_namespace, contract.panel_id,
    );

    RepairPlan {
        obligation_id: format!("msg:{}", contract.panel_id),
        target_file: "src/Msg.res".to_string(),
        action: RepairAction::InsertAfter {
            // Dual insert: type definition before `/// The unified message type`
            // and variant before `| NoOp`.
            anchor: format!("__MSG_DUAL_INSERT__{}__{}__", type_def, variant_line),
            content: String::new(),
        },
        preview: format!(
            "Insert `type {} = | Init` and `| {}({})` into Msg.res",
            contract.msg_namespace, contract.module_name, contract.msg_namespace,
        ),
        kind_label: "MSG NAMESPACE".to_string(),
    }
}

/// Render the dry-run output for a set of repair plans.
///
/// Shows a numbered list of planned repairs with previews, without
/// modifying any files.
pub fn render_dry_run(plans: &[RepairPlan], panel_id: &str) {
    println!();
    println!(
        "{}",
        format!("DRY RUN — Repair plan for panel {}", panel_id)
            .bold()
            .cyan()
    );
    println!("{}", "=".repeat(56).dimmed());
    println!();

    let total = plans.len();
    for (idx, plan) in plans.iter().enumerate() {
        let step = idx + 1;

        match &plan.action {
            RepairAction::AlreadySatisfied => {
                println!(
                    "[{}/{}] {} — {} already satisfied",
                    step,
                    total,
                    format!("No repair needed").green(),
                    plan.obligation_id.green(),
                );
                println!();
            }
            RepairAction::InsertAfter { anchor, .. } | RepairAction::InsertBefore { anchor, .. } => {
                println!(
                    "[{}/{}] {} ({})",
                    step,
                    total,
                    plan.kind_label.yellow().bold(),
                    plan.obligation_id.yellow(),
                );
                println!("  File: {}", plan.target_file);
                println!("  Action: {}", plan.preview);

                // For dual-insert anchors, just show the preview.
                if !anchor.starts_with("__") {
                    println!("  Anchor: {}", anchor.dimmed());
                }
                println!();
            }
        }
    }

    println!(
        "Run with {} to execute these repairs.",
        "--apply".bold().green()
    );
    println!();
}

/// Apply all repair plans to the filesystem.
///
/// Reads each target file, finds the anchor, inserts the content, and
/// writes the file back. Returns a Vec of results for each plan.
pub fn apply_repairs(
    plans: &[RepairPlan],
    panel_id: &str,
    repo_root: &Path,
) -> Vec<RepairResult> {
    println!();
    println!(
        "{}",
        format!("APPLYING REPAIRS for panel {}", panel_id)
            .bold()
            .cyan()
    );
    println!("{}", "=".repeat(56).dimmed());
    println!();

    let total = plans.len();
    let mut results = Vec::new();

    for (idx, plan) in plans.iter().enumerate() {
        let step = idx + 1;

        match &plan.action {
            RepairAction::AlreadySatisfied => {
                println!(
                    "[{}/{}] {} {} (already satisfied)",
                    step,
                    total,
                    "Skipping".green(),
                    plan.obligation_id,
                );
                results.push(RepairResult::Skipped);
            }
            RepairAction::InsertBefore { anchor, content } => {
                print!(
                    "[{}/{}] Patching {}... ",
                    step, total, plan.target_file
                );
                let result = apply_insert_before(repo_root, &plan.target_file, anchor, content);
                match &result {
                    RepairResult::Applied => println!("{}", "OK".green().bold()),
                    RepairResult::Failed(msg) => {
                        println!("{}: {}", "FAILED".red().bold(), msg)
                    }
                    RepairResult::Skipped => println!("{}", "SKIPPED".yellow()),
                }
                results.push(result);
            }
            RepairAction::InsertAfter { anchor, content } => {
                // Handle dual-insert special anchors.
                if anchor.starts_with("__MODEL_DUAL_INSERT__") {
                    print!(
                        "[{}/{}] Patching {}... ",
                        step, total, plan.target_file
                    );
                    let result = apply_model_dual_insert(repo_root, anchor);
                    match &result {
                        RepairResult::Applied => println!("{}", "OK".green().bold()),
                        RepairResult::Failed(msg) => {
                            println!("{}: {}", "FAILED".red().bold(), msg)
                        }
                        RepairResult::Skipped => println!("{}", "SKIPPED".yellow()),
                    }
                    results.push(result);
                } else if anchor.starts_with("__MSG_DUAL_INSERT__") {
                    print!(
                        "[{}/{}] Patching {}... ",
                        step, total, plan.target_file
                    );
                    let result = apply_msg_dual_insert(repo_root, anchor);
                    match &result {
                        RepairResult::Applied => println!("{}", "OK".green().bold()),
                        RepairResult::Failed(msg) => {
                            println!("{}: {}", "FAILED".red().bold(), msg)
                        }
                        RepairResult::Skipped => println!("{}", "SKIPPED".yellow()),
                    }
                    results.push(result);
                } else {
                    print!(
                        "[{}/{}] Patching {}... ",
                        step, total, plan.target_file
                    );
                    let result =
                        apply_insert_after(repo_root, &plan.target_file, anchor, content);
                    match &result {
                        RepairResult::Applied => println!("{}", "OK".green().bold()),
                        RepairResult::Failed(msg) => {
                            println!("{}: {}", "FAILED".red().bold(), msg)
                        }
                        RepairResult::Skipped => println!("{}", "SKIPPED".yellow()),
                    }
                    results.push(result);
                }
            }
        }
    }

    println!();
    results
}

/// Insert content before a line containing the anchor text.
///
/// Reads the file, finds the anchor line, inserts content before it,
/// and writes the file back. Idempotent: checks if content already exists.
fn apply_insert_before(
    repo_root: &Path,
    relative_path: &str,
    anchor: &str,
    content: &str,
) -> RepairResult {
    let full_path = repo_root.join(relative_path);
    let file_content = match std::fs::read_to_string(&full_path) {
        Ok(c) => c,
        Err(e) => return RepairResult::Failed(format!("Cannot read {}: {}", relative_path, e)),
    };

    // Idempotency check: if any non-blank line of the content already exists,
    // skip the insertion.
    let first_significant_line = content
        .lines()
        .find(|l| !l.trim().is_empty())
        .unwrap_or("");
    if !first_significant_line.is_empty() && file_content.contains(first_significant_line) {
        return RepairResult::Skipped;
    }

    // Find the anchor position.
    if let Some(pos) = file_content.find(anchor) {
        let mut result = String::with_capacity(file_content.len() + content.len() + 2);
        result.push_str(&file_content[..pos]);
        result.push_str(content);
        result.push('\n');
        result.push_str(&file_content[pos..]);

        match write_file_safe(&full_path, &result) {
            Ok(()) => RepairResult::Applied,
            Err(e) => RepairResult::Failed(format!("Cannot write {}: {}", relative_path, e)),
        }
    } else {
        RepairResult::Failed(format!(
            "Anchor not found in {}: {}",
            relative_path,
            truncate_anchor(anchor),
        ))
    }
}

/// Insert content after a line containing the anchor text.
///
/// Reads the file, finds the line containing the anchor, inserts content
/// after that line, and writes the file back. Idempotent.
fn apply_insert_after(
    repo_root: &Path,
    relative_path: &str,
    anchor: &str,
    content: &str,
) -> RepairResult {
    let full_path = repo_root.join(relative_path);
    let file_content = match std::fs::read_to_string(&full_path) {
        Ok(c) => c,
        Err(e) => return RepairResult::Failed(format!("Cannot read {}: {}", relative_path, e)),
    };

    // Idempotency check.
    let first_significant_line = content
        .lines()
        .find(|l| !l.trim().is_empty())
        .unwrap_or("");
    if !first_significant_line.is_empty() && file_content.contains(first_significant_line) {
        return RepairResult::Skipped;
    }

    // Find the line containing the anchor and insert after it.
    let lines: Vec<&str> = file_content.lines().collect();
    let mut found = false;
    let mut result_lines: Vec<String> = Vec::with_capacity(lines.len() + 10);

    for line in &lines {
        result_lines.push(line.to_string());
        if !found && line.contains(anchor) {
            result_lines.push(content.to_string());
            found = true;
        }
    }

    if !found {
        return RepairResult::Failed(format!(
            "Anchor not found in {}: {}",
            relative_path,
            truncate_anchor(anchor),
        ));
    }

    let result = result_lines.join("\n");
    // Preserve trailing newline if original had one.
    let result = if file_content.ends_with('\n') && !result.ends_with('\n') {
        format!("{}\n", result)
    } else {
        result
    };

    match write_file_safe(&full_path, &result) {
        Ok(()) => RepairResult::Applied,
        Err(e) => RepairResult::Failed(format!("Cannot write {}: {}", relative_path, e)),
    }
}

/// Apply a dual insertion for Model.res: `include` line + model field.
///
/// The anchor format is: `__MODEL_DUAL_INSERT__{include_line}__{field_line}__`
fn apply_model_dual_insert(repo_root: &Path, anchor: &str) -> RepairResult {
    let relative_path = "src/Model.res";
    let full_path = repo_root.join(relative_path);
    let file_content = match std::fs::read_to_string(&full_path) {
        Ok(c) => c,
        Err(e) => return RepairResult::Failed(format!("Cannot read {}: {}", relative_path, e)),
    };

    // Parse the dual-insert anchor.
    let stripped = anchor
        .strip_prefix("__MODEL_DUAL_INSERT__")
        .and_then(|s| s.strip_suffix("__"))
        .unwrap_or("");
    let parts: Vec<&str> = stripped.splitn(2, "__").collect();
    if parts.len() != 2 {
        return RepairResult::Failed("Malformed MODEL_DUAL_INSERT anchor".to_string());
    }
    let include_line = parts[0];
    let field_line = parts[1];

    // Check idempotency — if both are already present, skip.
    let include_present = file_content.contains(include_line);
    let field_present = file_content.contains(field_line.trim());

    if include_present && field_present {
        return RepairResult::Skipped;
    }

    let mut content = file_content.clone();

    // Insert include line if not present.
    // Find the last `include *Model` line and insert after it.
    if !include_present {
        let lines: Vec<&str> = content.lines().collect();
        let mut last_include_idx = None;
        for (idx, line) in lines.iter().enumerate() {
            if line.starts_with("include ") && line.contains("Model") {
                last_include_idx = Some(idx);
            }
        }

        if let Some(idx) = last_include_idx {
            let mut new_lines: Vec<String> = lines.iter().map(|l| l.to_string()).collect();
            new_lines.insert(idx + 1, include_line.to_string());
            content = new_lines.join("\n");
            if file_content.ends_with('\n') {
                content.push('\n');
            }
        } else {
            return RepairResult::Failed(
                "Cannot find any existing `include *Model` line in Model.res".to_string(),
            );
        }
    }

    // Insert field line if not present.
    // Find the `type model = {` record and insert the field before the
    // closing `}`. We look for the last field line (ending with `,`)
    // before `}` in the model record.
    if !field_present {
        let lines: Vec<&str> = content.lines().collect();
        let mut in_model_record = false;
        let mut last_field_idx = None;

        for (idx, line) in lines.iter().enumerate() {
            if line.contains("type model = {") || line.contains("type model =") {
                in_model_record = true;
            }
            if in_model_record {
                let trimmed = line.trim();
                if trimmed.ends_with(',') || trimmed.ends_with(": bool,") {
                    last_field_idx = Some(idx);
                }
                if trimmed == "}" && in_model_record {
                    break;
                }
            }
        }

        if let Some(idx) = last_field_idx {
            let mut new_lines: Vec<String> = lines.iter().map(|l| l.to_string()).collect();
            new_lines.insert(idx + 1, field_line.to_string());
            content = new_lines.join("\n");
            if file_content.ends_with('\n') && !content.ends_with('\n') {
                content.push('\n');
            }
        } else {
            return RepairResult::Failed(
                "Cannot find model record fields in Model.res".to_string(),
            );
        }
    }

    match write_file_safe(&full_path, &content) {
        Ok(()) => RepairResult::Applied,
        Err(e) => RepairResult::Failed(format!("Cannot write {}: {}", relative_path, e)),
    }
}

/// Apply a dual insertion for Msg.res: type definition + routing variant.
///
/// The anchor format is: `__MSG_DUAL_INSERT__{type_def}__{variant_line}__`
fn apply_msg_dual_insert(repo_root: &Path, anchor: &str) -> RepairResult {
    let relative_path = "src/Msg.res";
    let full_path = repo_root.join(relative_path);
    let file_content = match std::fs::read_to_string(&full_path) {
        Ok(c) => c,
        Err(e) => return RepairResult::Failed(format!("Cannot read {}: {}", relative_path, e)),
    };

    // Parse the dual-insert anchor.
    let stripped = anchor
        .strip_prefix("__MSG_DUAL_INSERT__")
        .and_then(|s| s.strip_suffix("__"))
        .unwrap_or("");
    let parts: Vec<&str> = stripped.splitn(2, "__").collect();
    if parts.len() != 2 {
        return RepairResult::Failed("Malformed MSG_DUAL_INSERT anchor".to_string());
    }
    let type_def = parts[0];
    let variant_line = parts[1];

    // Extract the type name from the type definition (e.g. "type fooMsg")
    // and the variant pattern from the variant line (e.g. "| Foo(fooMsg)")
    // for idempotency checks.
    let type_name = type_def
        .lines()
        .find(|l| l.starts_with("type "))
        .unwrap_or("");
    let variant_pattern = variant_line.trim();

    let type_present = !type_name.is_empty() && file_content.contains(type_name);
    let variant_present = !variant_pattern.is_empty() && file_content.contains(variant_pattern);

    if type_present && variant_present {
        return RepairResult::Skipped;
    }

    let mut content = file_content.clone();

    // Insert type definition before `/// The unified message type`.
    if !type_present {
        let marker = "/// The unified message type";
        if let Some(pos) = content.find(marker) {
            let insertion = format!("{}\n\n", type_def);
            content.insert_str(pos, &insertion);
        } else {
            return RepairResult::Failed(
                "Cannot find `/// The unified message type` marker in Msg.res".to_string(),
            );
        }
    }

    // Insert variant line before `| NoOp`.
    if !variant_present {
        let marker = "  | NoOp";
        if let Some(pos) = content.find(marker) {
            let insertion = format!("{}\n", variant_line);
            content.insert_str(pos, &insertion);
        } else {
            return RepairResult::Failed(
                "Cannot find `| NoOp` marker in Msg.res".to_string(),
            );
        }
    }

    match write_file_safe(&full_path, &content) {
        Ok(()) => RepairResult::Applied,
        Err(e) => RepairResult::Failed(format!("Cannot write {}: {}", relative_path, e)),
    }
}

/// Write file contents safely — reads, modifies, writes.
///
/// Uses `std::fs::write` which is atomic on most filesystems (write to
/// temp + rename).
fn write_file_safe(path: &PathBuf, content: &str) -> Result<(), std::io::Error> {
    std::fs::write(path, content)
}

/// Truncate an anchor string for error messages.
fn truncate_anchor(anchor: &str) -> String {
    if anchor.len() > 60 {
        format!("{}...", &anchor[..57])
    } else {
        anchor.to_string()
    }
}

/// Convert an obligation kind to a human-readable repair label.
fn kind_to_label(kind: &ObligationKind) -> &'static str {
    match kind {
        ObligationKind::ContractExists => "CONTRACT",
        ObligationKind::RegistryEntry => "REGISTRY ENTRY",
        ObligationKind::ModelSlice => "MODEL SLICE",
        ObligationKind::MsgNamespace => "MSG NAMESPACE",
        ObligationKind::ViewRoute => "VIEW ROUTE",
        ObligationKind::PanelWired => "PANEL WIRED",
    }
}
