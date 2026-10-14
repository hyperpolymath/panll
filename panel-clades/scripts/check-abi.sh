#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# check-abi.sh — typecheck the panel-clades grades ABI against typed-wasm's
# grade kernel at its pin, and run the expected rejections.
#
#   1. fetch typed-wasm at the pin (scripts/fetch-siblings.sh) and build its
#      ABI package (the kernel's TTCs);
#   2. build src/abi/panel-clades-grades.ipkg against them: exit 0 AND no
#      `Error:` line (idris2 can exit 0 while printing an error);
#   3. every tests/reject/*.idr must FAIL at its `invalid` declaration with
#      the message in its `-- EXPECT:` line, and not for a scope/parse/path
#      reason.
#
# A missing toolchain is a failure, never a skip.  Types.idr / Layout.idr /
# Foreign.idr are NOT checked: they do not typecheck (src/abi/README.adoc).
set -uo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
ROOT="$(pwd)"
OUT="_build/check-abi"
WRONG_REASON='Undefined name|Couldn.t parse|Parse error|not in the source directory|Can.t find import|Module .* not found|INTERNAL ERROR|does not match file name'
fail=0
pass() { printf 'PASS: %s\n' "$1"; }
err()  { printf 'FAIL: %s\n' "$1"; fail=1; }
die()  { printf 'FAIL: %s\n' "$1"; exit 1; }

command -v idris2 >/dev/null || die "idris2 not on PATH (a gate that cannot run must not report OK)"
iv="$(idris2 --version)"; echo "$iv"
case "$iv" in *"version 0.8.0"*) ;; *) [ -n "${ALLOW_ANY_IDRIS2:-}" ] || die "Idris2 0.8.0 required (set ALLOW_ANY_IDRIS2=1 to try another)" ;; esac
rm -rf "$OUT"; mkdir -p "$OUT"

bash scripts/fetch-siblings.sh || die "could not fetch typed-wasm at its pin"
TW="_build/dependencies/typed-wasm/src/abi"
rm -rf "$TW/build"
(cd "$TW" && idris2 --build typed-wasm.ipkg) > "$OUT/kernel.log" 2>&1
if [ $? -ne 0 ] || grep -q '^Error' "$OUT/kernel.log"; then
  grep -A10 '^Error' "$OUT/kernel.log" | head -30; die "typed-wasm's ABI package does not build at the pin"
fi
pass "typed-wasm grade kernel built at $(git -C _build/dependencies/typed-wasm rev-parse --short HEAD)"
KTTC="$ROOT/$TW/build/ttc"

rm -rf src/abi/build
(cd src/abi && IDRIS2_PATH="$KTTC" idris2 --build panel-clades-grades.ipkg) > "$OUT/grades.log" 2>&1
st=$?
if [ "$st" -eq 0 ] && ! grep -q '^Error' "$OUT/grades.log"; then
  pass "panel-clades-grades.ipkg builds against the kernel ($(grep -c ': Building ' "$OUT/grades.log") module(s), 0 errors)"
else
  grep -A12 '^Error' "$OUT/grades.log" | head -40; err "panel-clades-grades.ipkg (exit $st)"
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
echo "OK: panel-clades grades ABI — builds against the kernel, ${n} rejection(s)"
