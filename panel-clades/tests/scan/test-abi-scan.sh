#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# test-abi-scan.sh — regression tests for scripts/abi-scan-lib.sh, the scans
# behind check-abi.sh.  Both ways: each planted escape, hole, missing
# directive or commented-out import must be caught or ignored as stated, and
# the same words in comments or strings must not trip a scan.  Needs only
# bash and awk; it runs before the Idris2 build in CI.
set -uo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." || exit 1
# shellcheck source=../../scripts/abi-scan-lib.sh
. scripts/abi-scan-lib.sh

work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
fail=0; n=0

# mod BODY... : write a module T.idr whose lines are BODY (no %default added).
mod() { printf '%s\n' "module T" "$@" > "$work/T.idr"; }

# expect found|clean DESCRIPTION BODY... : scan_escapes on a module with
# `%default total` plus BODY.
expect() {
  local want="$1" what="$2"; shift 2
  mod "%default total" "$@"
  local got=clean
  if scan_escapes "$work/T.idr" > /dev/null; then got=found; fi
  n=$((n + 1))
  if [[ "$got" == "$want" ]]; then echo "ok   $want: $what"; else echo "FAIL got $got, want $want: $what"; fail=1; fi
}

expect found "hole"                       'f : Nat' 'f = ?todo'
expect found "hole as an argument"        'f : Nat -> Nat' 'f x = plus x ?hole_1'
expect found "believe_me"                 'f = believe_me 1'
expect found "idris_crash"                'g = idris_crash ""'
expect found "assert_total"               'g = assert_total (f 1)'
expect found "assert_smaller"             'g = assert_smaller x y'
expect found "unsafePerformIO"            'g = unsafePerformIO action'
expect found "postulate"                  'postulate p : Nat'
expect found "partial declaration"        'partial' 'f : Nat'
expect found "export partial"             'export partial' 'f : Nat'
expect found "covering declaration"       'covering' 'f : Nat'
expect found "hole after an operator"     'x = a --> ?b'
expect clean "words in a line comment"    '-- NO believe_me, NO postulate, ?hole here'
expect clean "words in a doc comment"     '||| partial functions and ?holes are banned'
expect clean "nested block comment"       '{- block' 'believe_me ?x' '{- nested -} still' '-}' 'f : Nat'
expect clean "words in a string"          'msg = "is it ?ok to say believe_me"'
expect clean "operator, not a comment"    'x = a --> b'
expect clean "operator ending in ?, not a hole" 'x = a =?b'
expect found "hole after an operator and a space" 'x = a =? ?b'
expect clean "primed identifier"          "f' : Nat" "f' = 1"
expect clean "identifier containing partial" 'partialSum : Nat'
expect found "escape after an escaped-quote char literal" "f = ('\\\"', believe_me v)"
expect found "escape after an escaped-apostrophe char"   "f = ('\\'', believe_me v)"
expect found "escape after a quote char literal"         "f = ('\"', believe_me v)"
expect found "escape after a hex char literal"           "f = ('\\x41', ?h)"
expect found "escape after a raw string with a backslash" 'f = #"\"# ++ believe_me v'
expect found "escape after a closed multi-line string"   's = """' 'text' '"""' 'g = believe_me 1'
expect clean "words in a raw string"      'msg = #"say "believe_me" and ?ok"#'
expect clean "words in a multi-line string" 's = """' 'believe_me ?x partial' '"""'
expect clean "primed identifier then a char literal" "f' = g' 'a'"

# %default total: required in code, not in a comment.
directive() { # directive found|clean DESCRIPTION BODY...
  local want="$1" what="$2"; shift 2
  mod "$@"
  local got=clean
  if scan_escapes "$work/T.idr" > /dev/null; then got=found; fi
  n=$((n + 1))
  if [[ "$got" == "$want" ]]; then echo "ok   $want: $what"; else echo "FAIL got $got, want $want: $what"; fail=1; fi
}
directive found "no %default total"            'f : Nat'
directive found "%default total only in a block comment" '{-' '%default total' '-}' 'f : Nat'
directive found "%default total only in a line comment"  '-- %default total' 'f : Nat'
directive found "%default covering"            '%default covering' 'f : Nat'
directive found "%default total only in a multi-line string" 's : String' 's = """' '%default total' '"""'
directive clean "%default total in code"       '%default total' 'f : Nat'
directive found "%default total after a declaration" 'loop : Nat -> Nat' 'loop n = loop n' '%default total'
directive clean "imports and directives before %default total" 'import Data.Nat' '%hide Prelude.id' '%default total' 'f : Nat'
# A long module: grep must read to the end, or SIGPIPE under pipefail reads
# as a missing directive.
mapfile -t long < <(for i in $(seq 1 20000); do printf 'v%d : Nat\n' "$i"; done)
directive clean "%default total in a 20,000-line module" '%default total' "${long[@]}"

# import_cone: commented-out imports are not dependencies; indented ones are.
mkdir -p "$work/root/A" "$work/root/B"
printf '%s\n' "module A.Real" "%default total" "import A.Deep" > "$work/root/A/Real.idr"
printf '%s\n' "module A.Deep" "%default total" > "$work/root/A/Deep.idr"
printf '%s\n' "module A.Indented" "%default total" > "$work/root/A/Indented.idr"
printf '%s\n' "module B.Ghost" "%default total" > "$work/root/B/Ghost.idr"
printf '%s\n' "module Top" "%default total" \
  "import A.Real" "  import public A.Indented" "import Data.Nat" \
  "{- import B.Ghost -}" "-- import B.Ghost" > "$work/Top.idr"
cone="$(import_cone "$work/base" "$work/root" -- "$work/Top.idr")"
check_cone() { # check_cone yes|no PATH DESCRIPTION
  n=$((n + 1))
  if grep -qxF "$2" <<< "$cone"; then got=yes; else got=no; fi
  if [[ "$got" == "$1" ]]; then echo "ok   cone $1: $3"; else echo "FAIL cone got $got, want $1: $3"; fail=1; fi
}
check_cone yes "$work/root/A/Real.idr"     "an import"
check_cone yes "$work/root/A/Deep.idr"     "a transitive import"
check_cone yes "$work/root/A/Indented.idr" "an indented import public"
check_cone no  "$work/root/B/Ghost.idr"    "imports inside comments"
n=$((n + 1))
if grep -qxF Data.Nat "$work/base"; then echo "ok   base: unresolved import listed"; else echo "FAIL base: Data.Nat not listed"; fail=1; fi

echo
[[ "$fail" -eq 0 ]] || { echo "ABI SCAN TESTS FAILED"; exit 1; }
echo "OK: abi scan — $n cases"
