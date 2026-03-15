# SPDX-License-Identifier: PMPL-1.0-or-later
# K9 Yard Validator: Accessibility Baseline (DD-008)
#
# Validates WCAG accessibility baseline requirements for PanLL components.
# Every interactive component MUST meet a minimum accessibility standard
# before it can be considered "wired" in the PCC.
#
# DD-008 defines the accessibility contract:
#   - All interactive elements must have ARIA labels
#   - All semantic regions must have role attributes
#   - All interactive elements must have keyboard event handlers
#   - Focus management must be explicit (no mouse-only interactions)
#
# In PanLL's ReScript/TEA components, this translates to:
#   - Attrs.ariaLabel("...") on interactive nodes
#   - Attrs.role("...") on semantic regions
#   - Events.onKeyDown / Events.onKeyUp on interactive nodes
#   - Attrs.tabIndex(...) on focusable elements
#
# Pedigree:
#   Name:    accessibility-baseline
#   Version: 0.1.0
#   Author:  Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#   Leash:   Yard (read-only validation, no side effects)

let AccessibilityCheck = {
  # Path to the component file being validated.
  component_file
    | String
    | doc "Path to the ReScript component file under validation",

  # --- Detection flags (populated by K9 runner) ---

  # Whether at least one ariaLabel attribute was found.
  has_aria_labels
    | Bool
    | doc "True if at least one Attrs.ariaLabel call was found",

  # Whether at least one role attribute was found.
  has_role_attributes
    | Bool
    | doc "True if at least one Attrs.role call was found",

  # Whether at least one keyboard event handler was found.
  has_keyboard_handlers
    | Bool
    | doc "True if at least one Events.onKeyDown/onKeyUp call was found",

  # Whether at least one tabIndex attribute was found.
  has_tab_index
    | Bool
    | default = false
    | doc "True if at least one Attrs.tabIndex call was found",

  # --- Counts (for reporting) ---

  # Number of ariaLabel attributes found.
  aria_label_count
    | Number
    | doc "Count of Attrs.ariaLabel occurrences",

  # Number of role attributes found.
  role_count
    | Number
    | doc "Count of Attrs.role occurrences",

  # Number of keyboard handler attributes found.
  keyboard_handler_count
    | Number
    | default = 0
    | doc "Count of Events.onKeyDown/onKeyUp occurrences",

  # --- Computed validation ---

  # Minimum baseline: at least 1 ariaLabel and 1 role per interactive component.
  meets_baseline
    | Bool
    | default = has_aria_labels
        && has_role_attributes
        && aria_label_count >= 1
        && role_count >= 1
    | doc "True when the component meets the minimum WCAG baseline",

  # Full compliance: baseline + keyboard handlers + tab index.
  meets_full_compliance
    | Bool
    | default = meets_baseline
        && has_keyboard_handlers
        && has_tab_index
    | doc "True when the component meets full keyboard accessibility",
}
in

AccessibilityCheck
