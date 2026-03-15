# SPDX-License-Identifier: PMPL-1.0-or-later
# K9 Yard Validator: TEA Purity
#
# Ensures Engine files have no side effects. In PanLL's TEA (The Elm
# Architecture) framework, Engine files contain the pure `update` logic.
# Side effects are routed exclusively through Tea_Cmd — never called
# directly in engine code.
#
# This validator defines the set of banned patterns that indicate
# impurity in engine files. Any occurrence of these patterns in an
# Engine file is a TEA architecture violation.
#
# The banned patterns are:
#   - invoke(          Tauri IPC = side effect (use {Name}Cmd.res instead)
#   - fetch(           HTTP calls = side effect (use Tea_Http instead)
#   - localStorage     Storage access = side effect
#   - console.log      Logging = side effect (use DebugLogger panel)
#   - window.          DOM/BOM access = side effect
#   - document.        DOM access = side effect
#   - setTimeout       Timing = side effect (use Tea_Cmd.delay)
#   - setInterval      Timing = side effect
#   - Promise           Async = side effect (use Tea_Cmd.call)
#   - Math.random       Non-determinism = side effect
#
# Pedigree:
#   Name:    tea-purity
#   Version: 0.1.0
#   Author:  Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
#   Leash:   Yard (read-only validation, no side effects)

let TeaPurityCheck = {
  # Path to the engine file being validated.
  engine_file
    | String
    | doc "Path to the ReScript engine file under validation",

  # Whether any banned pattern was found in the engine file.
  # This should be computed by the K9 runner after scanning the file.
  has_side_effects
    | Bool
    | default = false
    | doc "Set to true if any banned pattern is detected in the engine file",

  # Patterns that must NEVER appear in an Engine file.
  # Each string is a literal substring to search for.
  banned_patterns
    | Array String
    | default = [
        "invoke(",         # Tauri invoke = side effect
        "fetch(",          # HTTP = side effect
        "localStorage",    # Storage = side effect
        "console.log",     # Logging = side effect (use DebugLogger)
        "window.",         # DOM/BOM access = side effect
        "document.",       # DOM access = side effect
        "setTimeout",      # Timing = side effect (use Tea_Cmd.delay)
        "setInterval",     # Timing = side effect
        "Promise",         # Async = side effect (use Tea_Cmd.call)
        "Math.random",     # Non-determinism = side effect
      ]
    | doc "Substring patterns that indicate impurity in engine code",

  # Patterns that ARE allowed in engine files (for documentation/reference).
  allowed_patterns
    | Array String
    | default = [
        "Tea_Cmd.none",     # No-op command (pure)
        "Tea_Cmd.msg",      # Synchronous message dispatch (pure)
        "Tea_Cmd.batch",    # Batching commands (pure — the commands themselves are data)
        "Tea_Cmd.call",     # Command constructor (pure — execution is deferred)
      ]
    | doc "Patterns that are explicitly allowed in engine code",

  # List of specific violations found (populated by K9 runner).
  violations
    | Array String
    | default = []
    | doc "List of specific banned patterns found in the engine file",

  # Whether the engine file passes the purity check.
  is_pure
    | Bool
    | default = !has_side_effects && (std.array.length violations == 0)
    | doc "True when the engine file contains no banned patterns",
}
in

TeaPurityCheck
