#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# check-abi.sh — typecheck the panel-clades ABI (all of src/abi/PanelClades)
# against typed-wasm's grade kernel at its pin, and run the expected
# rejections.
#
#   1. fetch typed-wasm at the pin (scripts/fetch-siblings.sh) and build its
#      ABI package (the kernel's TTCs);
#   2. build src/abi/panel-clades-grades.ipkg against them: exit 0 AND no
#      `Error:` line (idris2 can exit 0 while printing an error);
#   3. every tests/reject/*.idr must FAIL at its `invalid` declaration with
#      the message in its `-- EXPECT:` line, and not for a scope/parse/path
#      reason.
#
# A missing toolchain is a failure, never a skip.  Every module under
# src/abi/PanelClades/ must be listed in the ipkg (an unlisted one would be
# skipped silently), declare `%default total`, and use no escape hatch and no
# hole; the typed-wasm modules they import (the import cone) are held to the
# same scan, and the cone is printed as the run's record of it.
set -uo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." || exit 1
ROOT="$(pwd)"
OUT="_build/check-abi"
WRONG_REASON='Undefined name|Couldn.t parse|Parse error|not in the source directory|Can.t find import|Module .* not found|INTERNAL ERROR|does not match file name'
fail=0
# Print the supplied success message to standard output with a PASS prefix.
pass() { printf 'PASS: %s\n' "$1"; }
# Print the supplied failure message and set fail=1, then continue checking.
err()  { printf 'FAIL: %s\n' "$1"; fail=1; }
# Print the supplied failure message and terminate the gate with exit status 1.
die()  { printf 'FAIL: %s\n' "$1"; exit 1; }

# Print each .idr file's code with comments and string literals blanked, as
# FILE:LINE:TEXT, so a scan neither trips over prose ("NO believe_me") nor
# misses code.  Handles nested {- -} block comments, `--` line comments (not
# operators such as -->), `|||` doc comments, and "..." / '.' literals.
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

# Escape hatches and holes in code, plus any module that does not declare
# `%default total` (Idris2's default is `covering`, which does not check
# termination).  Returns 0 and prints the offending lines if anything is found.
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
    grep -qE '^%default[[:space:]]+total[[:space:]]*$' "$f" || { printf '%s: no %%default total\n' "$f"; found=0; }
  done
  return "$found"
}

# The modules a PanelClades module imports, transitively, that resolve to a
# source file under one of the given roots.  Imports that resolve nowhere
# are Idris2's own prelude/base/contrib, the prover's trust base, and are
# listed separately.  Output: one path per line (cone), and the unresolved
# module names in "$OUT/import-base".
import_cone() {
  local -a queue=("$@") roots=(src/abi "$TW") seen=()
  local f m r p hit
  : > "$OUT/import-base"
  while [ "${#queue[@]}" -gt 0 ]; do
    f="${queue[0]}"; queue=("${queue[@]:1}")
    case " ${seen[*]-} " in *" $f "*) continue ;; esac
    seen+=("$f"); printf '%s\n' "$f"
    while IFS= read -r m; do
      hit=""
      for r in "${roots[@]}"; do
        p="$r/${m//.//}.idr"
        [ -f "$p" ] && { hit="$p"; break; }
      done
      if [ -n "$hit" ]; then queue+=("$hit"); else printf '%s\n' "$m" >> "$OUT/import-base"; fi
    done < <(sed -nE 's/^import[[:space:]]+(public[[:space:]]+)?([A-Za-z0-9_.]+).*/\2/p' "$f")
  done
}

command -v idris2 >/dev/null || die "idris2 not on PATH (a gate that cannot run must not report OK)"
iv="$(idris2 --version)"; echo "$iv"
case "$iv" in *"version 0.8.0"*) ;; *) [ -n "${ALLOW_ANY_IDRIS2:-}" ] || die "Idris2 0.8.0 required (set ALLOW_ANY_IDRIS2=1 to try another)" ;; esac
rm -rf "$OUT"; mkdir -p "$OUT"

IPKG="src/abi/panel-clades-grades.ipkg"
# Enumerate into a file, not a process substitution, so a failing find is seen.
abi_list="$OUT/abi-files"
find src/abi/PanelClades -type f -name '*.idr' -print0 > "$abi_list" \
  || die "could not enumerate .idr files under src/abi/PanelClades"
mapfile -d '' -t abi_files < "$abi_list"
[ "${#abi_files[@]}" -gt 0 ] || die "no .idr files found under src/abi/PanelClades"
for f in "${abi_files[@]}"; do
  mod="$(printf '%s' "${f#src/abi/}" | sed 's|\.idr$||; s|/|.|g')"
  grep -qE "^[[:space:]]*(modules[[:space:]]*=|,)[[:space:]]*${mod//./\\.}[[:space:]]*$" "$IPKG" \
    || err "$mod is not listed in $IPKG (it would never be checked)"
done
if scan_escapes "${abi_files[@]}"; then
  err "escape hatch in src/abi/PanelClades (lines above)"
fi
[ "$fail" -eq 0 ] && pass "every PanelClades module is listed in the ipkg, declares %default total, and has no escape hatch or hole"
if bash scripts/gen-budgets.sh --check; then
  pass "Budgets.idr is current with the clade configs"
else
  err "Budgets.idr is stale or a clade config's resources block is malformed"
fi

bash scripts/fetch-siblings.sh || die "could not fetch typed-wasm at its pin"
TW="_build/dependencies/typed-wasm/src/abi"
rm -rf "$TW/build"
if ! (cd "$TW" && idris2 --build typed-wasm.ipkg) > "$OUT/kernel.log" 2>&1 \
   || grep -q '^Error' "$OUT/kernel.log"; then
  { grep -A10 '^Error' "$OUT/kernel.log" || tail -30 "$OUT/kernel.log"; } | head -30
  die "typed-wasm's ABI package does not build at the pin"
fi
pass "typed-wasm grade kernel built at $(git -C _build/dependencies/typed-wasm rev-parse --short HEAD)"
KTTC="$ROOT/$TW/build/ttc"

# The import cone (standards PROOF-POLICY §1.1): every first-party module the
# proofs rest on, PanelClades and typed-wasm alike, is held to the same scan.
# A kernel module with a hole or an escape hatch would be trusted silently.
import_cone "${abi_files[@]}" > "$OUT/import-cone"
mapfile -t cone < <(grep -v '^src/abi/PanelClades/' "$OUT/import-cone")
[ "${#cone[@]}" -gt 0 ] || die "import cone has no typed-wasm module; Grades.idr imports the kernel"
if scan_escapes "${cone[@]}"; then
  err "escape hatch or hole in the typed-wasm import cone (lines above)"
else
  pass "import cone: ${#cone[@]} typed-wasm module(s), no escape hatch or hole; base: $(sort -u "$OUT/import-base" | tr '\n' ' ')"
fi
sed 's/^/  cone: /' "$OUT/import-cone"

rm -rf src/abi/build
(cd src/abi && IDRIS2_PATH="$KTTC" idris2 --build panel-clades-grades.ipkg) > "$OUT/grades.log" 2>&1
st=$?
if [ "$st" -eq 0 ] && ! grep -q '^Error' "$OUT/grades.log"; then
  pass "panel-clades-grades.ipkg builds against the kernel ($(grep -c ': Building ' "$OUT/grades.log") module(s), 0 errors)"
else
  { grep -A12 '^Error' "$OUT/grades.log" || tail -40 "$OUT/grades.log"; } | head -40
  err "panel-clades-grades.ipkg (exit $st)"
fi
PTTC="$ROOT/src/abi/build/ttc"

n=0
for f in tests/reject/*.idr; do
  [ -e "$f" ] || { err "no tests/reject/*.idr fixtures"; break; }
  n=$((n + 1)); name="$(basename "$f" .idr)"
  expect="$(sed -n 's/^-- EXPECT: //p' "$f" | head -1)"
  decl="$(grep -nE '^invalid[[:space:]]*:' "$f" | head -1 | cut -d: -f1)"
  log="$OUT/reject-$name.log"
  (cd tests/reject && IDRIS2_PATH="$KTTC:$PTTC" idris2 --build-dir "$ROOT/$OUT/reject-build" --check "$name.idr") > "$log" 2>&1
  loc="$(grep -oE "^${name}:[0-9]+:" "$log" | head -1 | cut -d: -f2)"
  if [ -z "$expect" ] || [ -z "$decl" ]; then err "reject $name: no '-- EXPECT:' line or 'invalid :' declaration"
  elif ! grep -q '^Error' "$log"; then cat "$log"; err "reject $name: ACCEPTED"
  elif grep -qE "$WRONG_REASON" "$log"; then cat "$log"; err "reject $name: refused for the WRONG reason"
  elif [ -z "$loc" ] || [ "$loc" -lt "$decl" ]; then cat "$log"; err "reject $name: error not at its invalid declaration"
  elif ! grep -qE -- "$expect" "$log"; then cat "$log"; err "reject $name: not refused with: $expect"
  else pass "rejected $name at line $loc ($expect)"; fi
done

echo
[ "$fail" -eq 0 ] || { echo "PANEL-CLADES ABI CHECK FAILED"; exit 1; }
echo "OK: panel-clades ABI — builds against the kernel, ${n} rejection(s)"
