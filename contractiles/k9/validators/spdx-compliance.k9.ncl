# SPDX-License-Identifier: PMPL-1.0-or-later
# K9 Yard Validator: SPDX Compliance
#
# Validates that source files carry correct SPDX license headers.
# Per hyperpolymath policy:
#   - All original code: PMPL-1.0-or-later
#   - Platform fallback: MPL-2.0 (with comment explaining why)
#   - Third-party code: preserve original license
#
# The validator checks for the presence of an SPDX-License-Identifier
# comment in the first 10 lines of each source file, and verifies the
# license ID is in the allowed set.
#
# Pedigree:
#   Name:    spdx-compliance
#   Version: 0.1.0
#   Author:  Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#   Leash:   Yard (read-only validation, no side effects)

let SpdxCheck = {
  # Path to the file being validated.
  file_path
    | String
    | doc "Path to the source file under validation",

  # Whether an SPDX-License-Identifier header was found in the first 10 lines.
  has_spdx_header
    | Bool
    | doc "True if an SPDX-License-Identifier comment was found",

  # The license identifier extracted from the SPDX header.
  license_id
    | String
    | default = "PMPL-1.0-or-later"
    | doc "The SPDX license identifier found in the file header",

  # Set of allowed license identifiers for this repository.
  # PMPL-1.0-or-later is the primary license for all hyperpolymath code.
  # MPL-2.0 is the fallback for platforms requiring OSI-approved licenses.
  # Other licenses are allowed only for third-party dependencies.
  allowed_licenses
    | Array String
    | default = [
        "PMPL-1.0-or-later",
        "MPL-2.0",
        "MIT",
        "Apache-2.0",
        "BSD-2-Clause",
        "BSD-3-Clause",
        "ISC",
      ]
    | doc "Set of allowed SPDX license identifiers",

  # Whether the license ID is in the allowed set.
  license_allowed
    | Bool
    | default = std.array.any (fun id => id == license_id) allowed_licenses
    | doc "True if the detected license ID is in the allowed set",

  # Whether this is a hyperpolymath-original file (should use PMPL).
  is_original_code
    | Bool
    | default = true
    | doc "True if this is hyperpolymath-original code (not third-party)",

  # Whether original code uses the correct primary license.
  uses_primary_license
    | Bool
    | default = if is_original_code then
        license_id == "PMPL-1.0-or-later" || license_id == "MPL-2.0"
      else
        true
    | doc "True if original code uses PMPL-1.0-or-later (or MPL-2.0 fallback)",

  # Overall compliance.
  is_compliant
    | Bool
    | default = has_spdx_header && license_allowed && uses_primary_license
    | doc "True when the file passes all SPDX compliance checks",
}
in

SpdxCheck
