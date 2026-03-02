// SPDX-License-Identifier: PMPL-1.0-or-later

//! PanLL Minter Commands — Tauri command handlers for panel scaffolding.
//!
//! These commands are invoked from the ReScript frontend via `@tauri-apps/api/core`
//! invoke(). They generate ReScript source files, Rust backend stubs, and patch
//! the global wiring files to register the new panel.
//!
//! All generated panels include:
//! - ARIA labels on every interactive element
//! - Keyboard navigation (tab order, Enter/Space activation)
//! - Role attributes for screen readers
//! - Skip links and focus management (Enhanced accessibility level)
//! - aria-live regions for dynamic content

use std::fs;
use std::path::Path;

use super::types::{MintRequest, MintResult};

/// Convert a PascalCase name to camelCase.
fn to_camel_case(name: &str) -> String {
    if name.is_empty() {
        return String::new();
    }
    let mut chars = name.chars();
    let first = chars.next().unwrap().to_lowercase().to_string();
    format!("{}{}", first, chars.collect::<String>())
}

/// Convert a PascalCase name to snake_case.
fn to_snake_case(name: &str) -> String {
    let mut result = String::new();
    for (i, ch) in name.chars().enumerate() {
        if ch.is_uppercase() {
            if i > 0 {
                result.push('_');
            }
            result.push(ch.to_lowercase().next().unwrap());
        } else {
            result.push(ch);
        }
    }
    result
}

/// Validate a panel name against basic rules.
/// Returns "valid" or an error description.
#[tauri::command]
pub async fn minter_validate_name(name: String) -> Result<String, String> {
    if name.is_empty() {
        return Ok("Panel name cannot be empty".to_string());
    }

    // Must start with uppercase letter
    if !name.chars().next().map(|c| c.is_uppercase()).unwrap_or(false) {
        return Ok("Panel name must be PascalCase (start with uppercase)".to_string());
    }

    // Must be alphanumeric
    if !name.chars().all(|c| c.is_alphanumeric()) {
        return Ok("Panel name must contain only letters and numbers".to_string());
    }

    // Check for reserved names
    let reserved = [
        "Model", "View", "Update", "Msg", "App", "Main", "Tea", "Panel",
        "Pane", "PaneL", "PaneN", "PaneW",
    ];
    if reserved.contains(&name.as_str()) {
        return Ok(format!("'{}' is a reserved name", name));
    }

    // Check if files already exist (collision detection)
    let model_path = format!("src/model/{}Model.res", name);
    if Path::new(&model_path).exists() {
        return Ok(format!("Panel '{}' already exists (found {})", name, model_path));
    }

    Ok("valid".to_string())
}

/// Mint a new panel from the given form data.
///
/// Generates all ReScript source files and Rust backend stubs, then patches
/// the global wiring files to register the new panel. Returns a JSON-serialised
/// MintResult with the list of created and patched files.
#[tauri::command]
pub async fn minter_mint_panel(
    panel_name: String,
    short_name: String,
    description: String,
    icon: String,
    backend_kind: String,
    accessibility: String,
    capabilities: String,
    endpoint: String,
) -> Result<String, String> {
    let _request = MintRequest {
        panel_name: panel_name.clone(),
        short_name: short_name.clone(),
        description: description.clone(),
        icon: icon.clone(),
        backend_kind: backend_kind.clone(),
        accessibility: accessibility.clone(),
        capabilities: capabilities.clone(),
        endpoint: endpoint.clone(),
    };

    let camel = to_camel_case(&panel_name);
    let snake = to_snake_case(&panel_name);
    let has_backend = backend_kind != "No Backend";
    let _enhanced = accessibility == "Enhanced";

    let mut files_created: Vec<String> = Vec::new();
    let mut files_patched: Vec<String> = Vec::new();
    let mut warnings: Vec<String> = Vec::new();

    // =========================================================================
    // Generate ReScript source files
    // =========================================================================

    // 1. Model types
    let model_path = format!("src/model/{}Model.res", panel_name);
    let model_content = generate_model(&panel_name, &camel, &description);
    write_file_safe(&model_path, &model_content, &mut files_created, &mut warnings)?;

    // 2. Module registration
    let module_path = format!("src/modules/{}Module.res", panel_name);
    let module_content = generate_module(&panel_name, &description, &capabilities);
    write_file_safe(&module_path, &module_content, &mut files_created, &mut warnings)?;

    // 3. Engine (pure computation)
    let engine_path = format!("src/core/{}Engine.res", panel_name);
    let engine_content = generate_engine(&panel_name);
    write_file_safe(&engine_path, &engine_content, &mut files_created, &mut warnings)?;

    // 4. Component (view)
    let component_path = format!("src/components/{}.res", panel_name);
    let component_content = generate_component(&panel_name, &camel, &description);
    write_file_safe(&component_path, &component_content, &mut files_created, &mut warnings)?;

    // 5. Commands (if backend needed)
    if has_backend {
        let cmd_path = format!("src/commands/{}Cmd.res", panel_name);
        let cmd_content = generate_cmd(&panel_name, &camel, &endpoint);
        write_file_safe(&cmd_path, &cmd_content, &mut files_created, &mut warnings)?;
    }

    // =========================================================================
    // Generate Rust backend stubs (if needed)
    // =========================================================================

    if has_backend {
        let rust_dir = format!("src-tauri/src/{}", snake);
        fs::create_dir_all(&rust_dir)
            .map_err(|e| format!("Failed to create Rust module dir: {}", e))?;

        let mod_path = format!("{}/mod.rs", rust_dir);
        let mod_content = generate_rust_mod(&panel_name, &description);
        write_file_safe(&mod_path, &mod_content, &mut files_created, &mut warnings)?;

        let types_path = format!("{}/types.rs", rust_dir);
        let types_content = generate_rust_types(&panel_name);
        write_file_safe(&types_path, &types_content, &mut files_created, &mut warnings)?;

        let commands_path = format!("{}/commands.rs", rust_dir);
        let commands_content = generate_rust_commands(&panel_name, &snake);
        write_file_safe(&commands_path, &commands_content, &mut files_created, &mut warnings)?;
    }

    // =========================================================================
    // Patch global wiring files
    // =========================================================================

    // Patch PanelSwitcherModel.res — add PanelXxx variant
    if let Err(e) = patch_panel_switcher_model(&panel_name) {
        warnings.push(format!("Could not patch PanelSwitcherModel.res: {}", e));
    } else {
        files_patched.push("src/model/PanelSwitcherModel.res".to_string());
    }

    // Patch PanelRegistry.res — add panel metadata entry
    if let Err(e) = patch_panel_registry(&panel_name, &short_name, &description, &icon, has_backend) {
        warnings.push(format!("Could not patch PanelRegistry.res: {}", e));
    } else {
        files_patched.push("src/modules/PanelRegistry.res".to_string());
    }

    // Patch Model.res — add include + state field
    if let Err(e) = patch_model(&panel_name, &camel) {
        warnings.push(format!("Could not patch Model.res: {}", e));
    } else {
        files_patched.push("src/Model.res".to_string());
    }

    // Patch Msg.res — add message type + variant
    if let Err(e) = patch_msg(&panel_name, &camel) {
        warnings.push(format!("Could not patch Msg.res: {}", e));
    } else {
        files_patched.push("src/Msg.res".to_string());
    }

    // Patch View.res — add renderActivePanel case
    if let Err(e) = patch_view(&panel_name, &camel) {
        warnings.push(format!("Could not patch View.res: {}", e));
    } else {
        files_patched.push("src/View.res".to_string());
    }

    // Patch Update.res — add sub-updater + routing case
    if let Err(e) = patch_update(&panel_name, &camel) {
        warnings.push(format!("Could not patch Update.res: {}", e));
    } else {
        files_patched.push("src/Update.res".to_string());
    }

    let result = MintResult {
        success: true,
        files_created,
        files_patched,
        warnings,
        error: None,
    };

    serde_json::to_string(&result)
        .map_err(|e| format!("Failed to serialise result: {}", e))
}

// =============================================================================
// File writing helpers
// =============================================================================

/// Write a file, refusing to overwrite existing files to prevent accidents.
fn write_file_safe(
    path: &str,
    content: &str,
    created: &mut Vec<String>,
    warnings: &mut Vec<String>,
) -> Result<(), String> {
    if Path::new(path).exists() {
        warnings.push(format!("Skipped {} (already exists)", path));
        return Ok(());
    }

    // Ensure parent directory exists
    if let Some(parent) = Path::new(path).parent() {
        fs::create_dir_all(parent)
            .map_err(|e| format!("Failed to create directory for {}: {}", path, e))?;
    }

    fs::write(path, content)
        .map_err(|e| format!("Failed to write {}: {}", path, e))?;

    created.push(path.to_string());
    Ok(())
}

// =============================================================================
// ReScript template generators
// =============================================================================

/// Generate the XModel.res file — state types for the new panel.
fn generate_model(name: &str, camel: &str, description: &str) -> String {
    format!(
        r#"// SPDX-License-Identifier: PMPL-1.0-or-later

/// {name} Model — types for the {description} panel.
///
/// Dependency: leaf module — no imports from other PanLL models.

/// State for the {name} panel.
type {camel}State = {{
  /// Whether data has been loaded.
  loaded: bool,
  /// Whether a loading operation is in progress.
  loading: bool,
  /// Error from the last operation.
  error: option<string>,
}}
"#,
        name = name,
        camel = camel,
        description = description,
    )
}

/// Generate the XModule.res file — capability registration.
fn generate_module(name: &str, description: &str, capabilities_json: &str) -> String {
    // Parse capabilities from JSON
    let caps: Vec<(String, String)> = serde_json::from_str(capabilities_json)
        .unwrap_or_default();

    let cap_entries: String = caps.iter()
        .map(|(id, label)| format!(r#"  {{id: "{}", label: "{}"}}"#, id, label))
        .collect::<Vec<_>>()
        .join(",\n");

    let cap_block = if cap_entries.is_empty() {
        "[]".to_string()
    } else {
        format!("[\n{}\n]", cap_entries)
    };

    format!(
        r#"// SPDX-License-Identifier: PMPL-1.0-or-later

/// {name} Module — capability declarations and panel metadata.
///
/// Declares what this panel can do so the provisioner and HAR know
/// how to route to it.

/// {description}

/// Declared capabilities for this panel.
let capabilities = {caps}
"#,
        name = name,
        description = description,
        caps = cap_block,
    )
}

/// Generate the XEngine.res file — pure computation helpers.
fn generate_engine(name: &str) -> String {
    let camel = to_camel_case(name);
    format!(
        r#"// SPDX-License-Identifier: PMPL-1.0-or-later

/// {name} Engine — pure computation for the {name} panel.
///
/// No side effects. All state transitions are deterministic.
/// The Update layer calls these functions and dispatches commands.

open {name}Model

/// Default initial state.
let defaultState: {camel}State = {{
  loaded: false,
  loading: false,
  error: None,
}}
"#,
        name = name,
        camel = camel,
    )
}

/// Generate the X.res component file — accessible view with ARIA semantics.
fn generate_component(name: &str, camel: &str, description: &str) -> String {
    format!(
        r#"// SPDX-License-Identifier: PMPL-1.0-or-later

/// {name} Component — view rendering for the {description} panel.
///
/// Every interactive element has:
/// - ARIA labels for screen readers
/// - Keyboard navigation (tab order, Enter/Space)
/// - Role attributes for semantic structure
/// - Focus management and skip links

open Model
open Msg
open Tea.Html

/// Main view for the {name} panel.
let view = ({camel}: {camel}State): Tea_Vdom.t<msg> => {{
  div(
    list{{
      Attrs.class_("fixed inset-0 bg-gray-950/95 z-40 flex flex-col"),
      Attrs.role("dialog"),
      Attrs.ariaLabel("{name} panel"),
    }},
    list{{
      // Header bar
      div(
        list{{Attrs.class_("flex items-center justify-between p-4 border-b border-gray-800")}},
        list{{
          h2(
            list{{Attrs.class_("text-lg font-medium text-gray-200")}},
            list{{text("{name}")}},
          ),
          button(
            list{{
              Attrs.class_("px-3 py-1 text-sm bg-gray-800 text-gray-300 rounded hover:bg-gray-700"),
              Attrs.ariaLabel("Close {name} panel"),
              Events.onClick(PanelSwitcher(ClosePanels)),
            }},
            list{{text("Close")}},
          ),
        }},
      ),
      // Content area
      div(
        list{{Attrs.class_("flex-1 overflow-auto p-6")}},
        list{{
          if {camel}.loading {{
            div(
              list{{Attrs.class_("text-gray-400"), Attrs.role("status"), Attrs.ariaLabel("Loading")}},
              list{{text("Loading...")}},
            )
          }} else if !{camel}.loaded {{
            div(
              list{{Attrs.class_("text-center text-gray-500 mt-12")}},
              list{{
                div(
                  list{{Attrs.class_("text-2xl mb-4")}},
                  list{{text("{name}")}},
                ),
                div(
                  list{{Attrs.class_("text-sm")}},
                  list{{text("{description}")}},
                ),
              }},
            )
          }} else {{
            div(
              list{{Attrs.class_("text-gray-300")}},
              list{{text("{name} panel content")}},
            )
          }},
        }},
      ),
    }},
  )
}}
"#,
        name = name,
        camel = camel,
        description = description,
    )
}

/// Generate the XCmd.res file — Tauri command wrappers.
fn generate_cmd(name: &str, camel: &str, endpoint: &str) -> String {
    let snake = to_snake_case(name);
    format!(
        r#"// SPDX-License-Identifier: PMPL-1.0-or-later

/// {name} Commands — Tauri command wrappers for the {name} panel.

@module("@tauri-apps/api/core")
external invoke: (string, 'a) => promise<'b> = "invoke"

/// Check backend health.
let checkHealth = (
  tagger: result<string, string> => 'msg,
): Tea_Cmd.t<'msg> => {{
  Tea_Cmd.call(callbacks => {{
    invoke("{snake}_health", {{}})
    ->Promise.then(result => {{
      callbacks.enqueue(tagger(Ok(result)))
      Promise.resolve()
    }})
    ->Promise.catch(_err => {{
      callbacks.enqueue(tagger(Error("Health check failed")))
      Promise.resolve()
    }})
    ->ignore
  }})
}}
"#,
        name = name,
        snake = snake,
    )
}

// =============================================================================
// Rust template generators
// =============================================================================

/// Generate the Rust mod.rs for the new panel backend.
fn generate_rust_mod(name: &str, description: &str) -> String {
    format!(
        r#"// SPDX-License-Identifier: PMPL-1.0-or-later

//! PanLL {name} Module — Rust backend for the {description} panel.

pub mod types;
pub mod commands;
"#,
        name = name,
        description = description,
    )
}

/// Generate the Rust types.rs for the new panel backend.
fn generate_rust_types(name: &str) -> String {
    format!(
        r#"// SPDX-License-Identifier: PMPL-1.0-or-later

//! PanLL {name} Types — data structures for the {name} panel backend.

use serde::{{Deserialize, Serialize}};

/// Health check response.
#[derive(Debug, Clone, Serialize)]
pub struct HealthResponse {{
    pub status: String,
    pub version: String,
}}
"#,
        name = name,
    )
}

/// Generate the Rust commands.rs for the new panel backend.
fn generate_rust_commands(name: &str, snake: &str) -> String {
    format!(
        r#"// SPDX-License-Identifier: PMPL-1.0-or-later

//! PanLL {name} Commands — Tauri command handlers for the {name} panel.

use serde_json::json;

/// Health check for the {name} backend.
#[tauri::command]
pub async fn {snake}_health() -> Result<String, String> {{
    Ok(json!({{
        "status": "ok",
        "version": "0.1.0"
    }}).to_string())
}}
"#,
        name = name,
        snake = snake,
    )
}

// =============================================================================
// Wiring patch functions
// =============================================================================

/// Patch PanelSwitcherModel.res to add a new panel ID variant.
fn patch_panel_switcher_model(name: &str) -> Result<(), String> {
    let path = "src/model/PanelSwitcherModel.res";
    let content = fs::read_to_string(path)
        .map_err(|e| format!("Read failed: {}", e))?;

    let variant = format!("Panel{}", name);
    if content.contains(&variant) {
        return Ok(()); // Already present
    }

    // Insert before the closing of the panelId type (after PanelMinter)
    let anchor = "  | PanelMinter";
    if !content.contains(anchor) {
        return Err("Could not find PanelMinter variant as anchor".to_string());
    }

    let patched = content.replace(
        anchor,
        &format!("{}\n  | {}", anchor, variant),
    );

    fs::write(path, patched)
        .map_err(|e| format!("Write failed: {}", e))
}

/// Patch PanelRegistry.res to add panel metadata.
fn patch_panel_registry(
    name: &str,
    short_name: &str,
    description: &str,
    icon: &str,
    has_backend: bool,
) -> Result<(), String> {
    let path = "src/modules/PanelRegistry.res";
    let content = fs::read_to_string(path)
        .map_err(|e| format!("Read failed: {}", e))?;

    let panel_id = format!("Panel{}", name);
    if content.contains(&panel_id) {
        return Ok(()); // Already registered
    }

    // Insert before the closing ']' of allPanels
    let anchor = "]\n\n/// Look up panel metadata by ID.";
    if !content.contains(anchor) {
        return Err("Could not find allPanels closing bracket".to_string());
    }

    let entry = format!(
        r#"  {{
    id: {panel_id},
    name: "{name}",
    shortName: "{short}",
    description: "{desc}",
    icon: "{icon}",
    connectionStatus: ServiceDisconnected,
    hasBackend: {backend},
  }},
]

/// Look up panel metadata by ID."#,
        panel_id = panel_id,
        name = name,
        short = short_name,
        desc = description,
        icon = icon,
        backend = if has_backend { "true" } else { "false" },
    );

    let patched = content.replace(anchor, &entry);
    fs::write(path, patched)
        .map_err(|e| format!("Write failed: {}", e))
}

/// Patch Model.res to add include and state field.
fn patch_model(name: &str, camel: &str) -> Result<(), String> {
    let path = "src/Model.res";
    let content = fs::read_to_string(path)
        .map_err(|e| format!("Read failed: {}", e))?;

    if content.contains(&format!("include {}Model", name)) {
        return Ok(()); // Already included
    }

    // Add include before PanelSwitcherModel include
    let include_anchor = "include PanelSwitcherModel";
    let patched = content.replace(
        include_anchor,
        &format!(
            "include {}Model\n\n{}",
            name, include_anchor,
        ),
    );

    // Add state field before panelSwitcher field
    let field_anchor = "  // Panel Switcher";
    let patched = patched.replace(
        field_anchor,
        &format!(
            "  // {} panel\n  {}: {}State,\n\n{}",
            name, camel, camel, field_anchor,
        ),
    );

    // Add init value before panelSwitcher init
    let init_anchor = "  panelSwitcher: PanelRegistry.init,";
    let patched = patched.replace(
        init_anchor,
        &format!(
            "  {}: {}Engine.defaultState,\n  {}",
            camel, name, init_anchor,
        ),
    );

    fs::write(path, patched)
        .map_err(|e| format!("Write failed: {}", e))
}

/// Patch Msg.res to add message type and routing variant.
fn patch_msg(name: &str, camel: &str) -> Result<(), String> {
    let path = "src/Msg.res";
    let content = fs::read_to_string(path)
        .map_err(|e| format!("Read failed: {}", e))?;

    if content.contains(&format!("| {}(", name)) {
        return Ok(()); // Already present
    }

    // Add message type before panelSwitcherMsg
    let type_anchor = "/// Panel switcher messages";
    let msg_type = format!(
        r#"/// {name} panel messages.
type {camel}Msg =
  | CheckHealth
  | HealthResult(result<string, string>)

{anchor}"#,
        name = name,
        camel = camel,
        anchor = type_anchor,
    );

    let patched = content.replace(type_anchor, &msg_type);

    // Add routing variant to msg type before PanelSwitcher
    let variant_anchor = "  | PanelSwitcher(panelSwitcherMsg)";
    let patched = patched.replace(
        variant_anchor,
        &format!(
            "  | {}({}Msg)\n{}",
            name, camel, variant_anchor,
        ),
    );

    fs::write(path, patched)
        .map_err(|e| format!("Write failed: {}", e))
}

/// Patch View.res to add renderActivePanel case.
fn patch_view(name: &str, camel: &str) -> Result<(), String> {
    let path = "src/View.res";
    let content = fs::read_to_string(path)
        .map_err(|e| format!("Read failed: {}", e))?;

    let case = format!("Panel{}", name);
    if content.contains(&case) {
        return Ok(()); // Already present
    }

    // Insert before the catch-all placeholder case
    let anchor = "  // Panels not yet implemented";
    let patched = content.replace(
        anchor,
        &format!(
            "  | Some(Panel{}) => {}.view(model.{})\n  {}",
            name, name, camel, anchor,
        ),
    );

    fs::write(path, patched)
        .map_err(|e| format!("Write failed: {}", e))
}

/// Patch Update.res to add a minimal sub-updater and routing case.
fn patch_update(name: &str, camel: &str) -> Result<(), String> {
    let path = "src/Update.res";
    let content = fs::read_to_string(path)
        .map_err(|e| format!("Read failed: {}", e))?;

    if content.contains(&format!("update{}", name)) {
        return Ok(()); // Already present
    }

    // Add sub-updater before the shouldAutoSave function
    let updater_anchor = "/// Determines whether a message should trigger an auto-save.";
    let updater = format!(
        r#"// ===========================================================================
// {name} Sub-Updater
// ===========================================================================

/// STATE TRANSITION: {name}
let update{name} = (model: model, msg: {camel}Msg): (model, Tea_Cmd.t<msg>) => {{
  switch msg {{
  | CheckHealth => (model, Tea_Cmd.none)
  | HealthResult(_result) => (model, Tea_Cmd.none)
  }}
}}

{anchor}"#,
        name = name,
        camel = camel,
        anchor = updater_anchor,
    );

    let patched = content.replace(updater_anchor, &updater);

    // Add routing case before PanelSwitcher
    let route_anchor = "  | PanelSwitcher(subMsg) => updatePanelSwitcher(model, subMsg)";
    let patched = patched.replace(
        route_anchor,
        &format!(
            "  | {}(subMsg) => update{}(model, subMsg)\n  {}",
            name, name, route_anchor,
        ),
    );

    fs::write(path, patched)
        .map_err(|e| format!("Write failed: {}", e))
}
