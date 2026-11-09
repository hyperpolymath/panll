#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# abi-scan-lib.sh — the source scans behind check-abi.sh, sourced by it and
# by tests/scan/test-abi-scan.sh.  Every scan reads code only: comments and
# string literals are set aside first, so prose such as "NO believe_me" does
# not trip a scan, and a directive or import inside a comment does not count.

# Print each .idr file's code with comments and string literals blanked, as
# FILE:LINE:TEXT.  Handles nested {- -} block comments, `--` line comments
# (not operators such as -->), `|||` doc comments, and "..." / '.' literals.
code_only() {
  awk '
    FNR == 1 { depth = 0 }
    {
      line = $0; out = ""; i = 1; n = length(line)
      if (depth == 0 && line ~ /^[[:space:]]*\|\|\|/) { print FILENAME ":" FNR ":"; next }
      while (i <= n) {
        two = substr(line, i, 2); c = substr(line, i, 1)
        if (two == "{-") { depth++; i += 2; continue }
        if (depth > 0) { if (two == "-}") { depth--; i += 2 } else i++; continue }
        if (two == "--" && substr(line, i + 2, 1) !~ /[!#$%&*+.\/<=>?@\\^|~:-]/) break
        if (c == "\"") { i++; while (i <= n && substr(line, i, 1) != "\"") { if (substr(line, i, 1) == "\\") i++; i++ }; i++; out = out "\"\""; continue }
        if (c == "'"'"'" && substr(line, i + 2, 1) == "'"'"'") { i += 3; out = out "'"'"''"'"'"; continue }
        out = out c; i++
      }
      print FILENAME ":" FNR ":" out
    }' "$@"
}

# Escape hatches and holes in code, plus any module whose code does not
# declare `%default total` (Idris2's default is `covering`, which does not
# check termination; a directive inside a comment does not count).
# Returns 0 and prints the offending lines if anything is found.
#   believe_me assert_total assert_smaller idris_crash unsafePerformIO
#   postulate             -- trust or totality escapes
#   ?name                 -- a hole: idris2 --build accepts a module with holes
#   partial / covering    -- a declaration opting out of %default total
scan_escapes() {
  local found=1 f
  if code_only "$@" | grep -E \
       -e ':[0-9]+:.*\b(believe_me|assert_total|assert_smaller|idris_crash|unsafePerformIO|postulate)\b' \
       -e ':[0-9]+:(.*[^A-Za-z0-9_'"'"'?])?\?[a-z_][A-Za-z0-9_'"'"']*' \
       -e ':[0-9]+:.*\b(partial|covering)\b'; then
    found=0
  fi
  for f in "$@"; do
    if ! code_only "$f" | grep -E '^[^:]*:[0-9]+:[[:space:]]*%default[[:space:]]+total[[:space:]]*$' > /dev/null; then
      printf '%s: no %%default total in code\n' "$f"; found=0
    fi
  done
  return "$found"
}

# import_cone BASE_FILE ROOT... -- FILE...
# The modules the given files import, transitively, that resolve to a source
# file under one of the roots, one path per line (the files themselves
# first).  Imports are read from code only, at any indentation.  Imports
# that resolve under no root are Idris2's own prelude/base/contrib, the
# prover's trust base: their module names are written to BASE_FILE.
import_cone() {
  local base="$1"; shift
  local -a roots=() queue=() seen=()
  while [[ $# -gt 0 && "$1" != "--" ]]; do roots+=("$1"); shift; done
  [[ $# -gt 0 ]] && shift
  queue=("$@")
  local f m r p hit
  : > "$base"
  while [[ ${#queue[@]} -gt 0 ]]; do
    f="${queue[0]}"; queue=("${queue[@]:1}")
    case " ${seen[*]-} " in *" $f "*) continue ;; esac
    seen+=("$f"); printf '%s\n' "$f"
    while IFS= read -r m; do
      hit=""
      for r in "${roots[@]}"; do
        p="$r/${m//.//}.idr"
        if [[ -f "$p" ]]; then hit="$p"; break; fi
      done
      if [[ -n "$hit" ]]; then queue+=("$hit"); else printf '%s\n' "$m" >> "$base"; fi
    done < <(code_only "$f" \
      | sed -nE 's/^[^:]*:[0-9]+:[[:space:]]*import[[:space:]]+(public[[:space:]]+)?([A-Za-z0-9_.]+).*/\2/p')
  done
}
