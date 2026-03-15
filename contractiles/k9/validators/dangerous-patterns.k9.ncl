# SPDX-License-Identifier: PMPL-1.0-or-later
# K9 Yard Validator: Dangerous Patterns
#
# Validates that source files do not contain banned unsafe/escape-hatch
# patterns. These patterns bypass the type system or introduce undefined
# behaviour and MUST NEVER appear in production code.
#
# Per hyperpolymath standards, the following are banned:
#   ReScript:  Obj.magic, %identity
#   Rust:      unsafe {, .unwrap(), panic!(
#   Idris2:    believe_me, assert_total
#   OCaml:     Obj.magic
#   Haskell:   unsafeCoerce, unsafePerformIO
#
# When a banned pattern is found, the K9 runner should check the
# `proven` repo for formally verified alternatives before suggesting
# a fix.
#
# Pedigree:
#   Name:    dangerous-patterns
#   Version: 0.1.0
#   Author:  Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#   Leash:   Yard (read-only validation, no side effects)

let Language = [|
  'rescript,
  'rust,
  'idris2,
  'ocaml,
  'haskell,
|]
in

let DangerousPatternCheck = {
  # Path to the file being validated.
  file_path
    | String
    | doc "Path to the source file under validation",

  # Language of the file (determines which banned pattern set applies).
  language
    | Language
    | doc "Programming language of the file",

  # --- Banned pattern sets (per language) ---

  # ReScript banned patterns.
  banned_rescript
    | Array String
    | default = [
        "Obj.magic",       # Type-unsafe cast
        "%identity",       # Raw identity cast bypassing types
        "%raw",            # Raw JS injection (review case-by-case)
      ]
    | doc "Patterns banned in ReScript code",

  # Rust banned patterns.
  banned_rust
    | Array String
    | default = [
        "unsafe {",        # Unsafe block
        "unsafe fn",       # Unsafe function declaration
        ".unwrap()",       # Panicking unwrap (use ? or match)
        "panic!(",         # Explicit panic (use Result/Option)
        ".expect(",        # Panicking expect (use ? or match in lib code)
        "std::mem::transmute",  # Type-punning transmute
      ]
    | doc "Patterns banned in Rust code",

  # Idris2 banned patterns.
  banned_idris2
    | Array String
    | default = [
        "believe_me",      # Axiom that any type equals any other
        "assert_total",    # Bypass totality checker
        "really_believe_me",  # Even more dangerous believe_me
    ]
    | doc "Patterns banned in Idris2 code",

  # OCaml banned patterns.
  banned_ocaml
    | Array String
    | default = [
        "Obj.magic",       # Type-unsafe cast
        "Obj.repr",        # Low-level representation access
        "Marshal.from",    # Unsafe deserialization
    ]
    | doc "Patterns banned in OCaml code",

  # Haskell banned patterns.
  banned_haskell
    | Array String
    | default = [
        "unsafeCoerce",         # Type-unsafe coercion
        "unsafePerformIO",      # IO in pure code
        "unsafeDupablePerformIO",  # Even worse
        "unsafeInterleaveIO",   # Lazy IO (unpredictable evaluation)
    ]
    | doc "Patterns banned in Haskell code",

  # --- Results (populated by K9 runner) ---

  # Number of violations found in the file.
  violations_found
    | Number
    | default = 0
    | doc "Count of banned pattern occurrences found",

  # Specific violations with line numbers (populated by K9 runner).
  violation_details
    | Array String
    | default = []
    | doc "List of 'line:column: pattern' strings for each violation",

  # --- Computed validation ---

  # Whether the file is clean (no violations).
  is_clean
    | Bool
    | default = violations_found == 0
    | doc "True when no banned patterns were found in the file",
}
in

DangerousPatternCheck
