#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# scan-escape-hatches.sh FILE.idr...  — fail if any Idris2 source in the
# proof's import cone weakens it:
#
#   * an escape hatch (believe_me, assert_total, assert_smaller, idris_crash,
#     unsafePerformIO, postulate);
#   * a hole (`?name`): idris2 --build accepts a module with unsolved holes,
#     so a theorem body `?todo` would otherwise pass the gate;
#   * a module without `%default total`, or one that opts out with
#     `partial` / `covering`.
#
# Comments (`--` to end of line, `|||` doc lines) are ignored, so prose that
# names a hatch is not a finding.  Neither tree uses `{- -}` block comments;
# a file that does is refused rather than scanned wrongly.
# Exit 0 when every file is clean, 1 otherwise; a missing file is a failure.
set -uo pipefail
[ "$#" -gt 0 ] || { echo "scan-escape-hatches: no files given" >&2; exit 1; }
HATCH='(^|[^A-Za-z0-9_'"'"'.])(believe_me|assert_total|assert_smaller|idris_crash|unsafePerformIO|postulate)([^A-Za-z0-9_'"'"']|$)'
HOLE='(^|[^A-Za-z0-9_'"'"'?])\?[A-Za-z_]'
OPTOUT='^[[:space:]]*(partial|covering)([[:space:]]|$)|%default[[:space:]]+(partial|covering)'
bad=0
for f in "$@"; do
  if [ ! -f "$f" ]; then echo "MISSING: $f"; bad=1; continue; fi
  if grep -q '{-' "$f"; then echo "BLOCK-COMMENT (not scannable): $f"; bad=1; continue; fi
  code="$(sed -E -e 's/^[[:space:]]*\|\|\|.*$//' -e 's/--.*$//' "$f")"
  if hits="$(printf '%s\n' "$code" | grep -nE "$HATCH")"; then
    printf '%s\n' "$hits" | sed "s|^|ESCAPE-HATCH $f:|"; bad=1
  fi
  if hits="$(printf '%s\n' "$code" | grep -nE "$HOLE")"; then
    printf '%s\n' "$hits" | sed "s|^|HOLE $f:|"; bad=1
  fi
  if hits="$(printf '%s\n' "$code" | grep -nE "$OPTOUT")"; then
    printf '%s\n' "$hits" | sed "s|^|TOTALITY-OPT-OUT $f:|"; bad=1
  fi
  printf '%s\n' "$code" | grep -qE '^[[:space:]]*%default[[:space:]]+total([[:space:]]|$)' \
    || { echo "NOT-TOTAL (no %default total): $f"; bad=1; }
done
exit "$bad"
