# SPDX-License-Identifier: PMPL-1.0-or-later
# K9 Yard Validator: Provenance Chain (DD-006)
#
# Validates code provenance per DD-006 (Provenance Decision Document).
# Every source file in PanLL must have a traceable origin. The trust
# level determines the visual treatment in the UI:
#
#   - verified:         Cryptographically signed, CI-verified
#   - human_reviewed:   Reviewed by a human maintainer
#   - ai_assisted:      AI-generated but human-reviewed
#   - unreviewed_ai:    AI-generated, NOT yet reviewed (triggers hostile UX)
#   - unknown:          No provenance data (triggers hostile UX)
#
# "Hostile UX" means visual friction: the file/panel is rendered with
# warning overlays, reduced contrast, and mandatory review prompts.
# This is intentional — unreviewed AI code should feel uncomfortable
# until a human has signed off.
#
# Pedigree:
#   Name:    provenance-chain
#   Version: 0.1.0
#   Author:  Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#   Leash:   Yard (read-only validation, no side effects)

let TrustLevel = [|
  'verified,
  'human_reviewed,
  'ai_assisted,
  'unreviewed_ai,
  'unknown,
|]
in

let ProvenanceCheck = {
  # Path to the file being validated.
  file_path
    | String
    | doc "Path to the source file under validation",

  # The trust level of this file's code.
  trust_level
    | TrustLevel
    | doc "Provenance trust level of the file",

  # Whether git blame data is available for this file.
  has_git_blame
    | Bool
    | doc "True if git blame data is available",

  # Whether the file has a Co-Authored-By header in its most recent commit.
  has_co_author_header
    | Bool
    | doc "True if the most recent commit has a Co-Authored-By header",

  # The git author of the most recent commit touching this file.
  last_author
    | String
    | optional
    | doc "Git author name from the most recent commit",

  # BLAKE3 hash of the file contents (for integrity verification).
  content_hash
    | String
    | optional
    | doc "BLAKE3 hash of the file contents",

  # --- Computed validation ---

  # Whether this file requires human review before it can be trusted.
  # Unreviewed AI code and unknown-origin code both trigger this.
  requires_review
    | Bool
    | default = trust_level == 'unreviewed_ai || trust_level == 'unknown
    | doc "True if the file needs human review (triggers hostile UX)",

  # Whether the file has sufficient provenance data to be traceable.
  has_provenance
    | Bool
    | default = has_git_blame && (trust_level != 'unknown)
    | doc "True if the file has any provenance data at all",

  # Whether AI-assisted code is properly attributed.
  ai_attributed
    | Bool
    | default = if trust_level == 'ai_assisted || trust_level == 'unreviewed_ai then
        has_co_author_header
      else
        true
    | doc "True if AI-assisted code has a Co-Authored-By header",

  # Overall provenance validity.
  is_valid
    | Bool
    | default = has_provenance && ai_attributed
    | doc "True when provenance chain is complete and properly attributed",
}
in

ProvenanceCheck
