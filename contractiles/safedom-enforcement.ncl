# SPDX-License-Identifier: MPL-2.0
# K9-SVC Contractile: SafeDOM Enforcement
# Security Level: Yard (validated config with Nickel contracts)

{
  k9 = {
    level = "Yard",
    pedigree = {
      name = "safedom-enforcement",
      version = "1.0.0",
      description = "Ensures all DOM mounts go through SafeDOM's 4-layer defence-in-depth",
      author = "Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>",
    },
  },

  contracts = {
    dom_mount = {
      description = "All DOM mounting MUST use SafeDOMCore.mount or SafeMount.mountRawHtml",
      banned_patterns = [
        ".innerHTML =",
        ".outerHTML =",
        "document.write(",
        "insertAdjacentHTML(",
      ],
      allowed_modules = [
        "SafeDOMCore",
        "SafeMount",
      ],
      enforcement = "block",
    },

    selector_format = {
      description = "CSS selectors must be valid and bounded",
      max_length = 255,
      must_start_with = "#",
      enforcement = "warn",
    },

    html_size = {
      description = "HTML content must not exceed 1MB",
      max_bytes = 1048576,
      enforcement = "block",
    },

    sanitisation = {
      description = "Sanitisation pipeline must include at least 2 layers",
      required_layers = [
        "DOMPurify",
        "regex",
      ],
      optional_layers = [
        "nesting",
        "trusted-types",
      ],
      min_active_layers = 2,
      enforcement = "block",
    },
  },

  audit = {
    trace_required = true,
    otel_export = true,
    sarif_export = true,
    max_trace_entries = 1000,
  },
}
