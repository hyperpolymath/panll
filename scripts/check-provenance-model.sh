#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# check-provenance-model.sh — model-check docs/models/Provenance.tla with TLC,
# both ways:
#
#   Provenance.cfg            author key leaked   -> no error (must pass)
#   ProvenanceWitnessLeak.cfg witness key leaked  -> no error (must pass)
#   ProvenanceBothLeak.cfg    both keys leaked    -> invariant Genuine is
#                                                    violated (must be found)
#
# The third run is what keeps the property honest: if TLC stopped finding
# the both-keys forgery, the model would have become vacuous, and this
# script fails.  A missing toolchain or an unexpected TLC version is a
# failure, never a skip.
#
# Usage: check-provenance-model.sh /path/to/tla2tools.jar
# The jar's version and digest are pinned in build-validation.yml
# (provenance-model job); the deviation record is in PROOF-NEEDS.adoc.
set -uo pipefail
JAR="${1:?usage: check-provenance-model.sh /path/to/tla2tools.jar}"
EXPECT_VERSION="TLC2 Version 2.19 of 08 August 2024"
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../docs/models" || exit 1
command -v java >/dev/null || { echo "FAIL: java not on PATH"; exit 1; }
[ -f "$JAR" ] || { echo "FAIL: $JAR not found"; exit 1; }

work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
fail=0

run() { # run <config> -> log in $work/<config>.log, exit status in $?
  java -XX:+UseParallelGC -cp "$JAR" tlc2.TLC -workers auto -deadlock \
    -metadir "$work/$1.states" -config "$1.cfg" Provenance.tla > "$work/$1.log" 2>&1
}

for cfg in Provenance ProvenanceWitnessLeak; do
  run "$cfg"; st=$?
  grep -qF "$EXPECT_VERSION" "$work/$cfg.log" \
    || { echo "FAIL: $cfg: TLC is not '$EXPECT_VERSION'"; head -5 "$work/$cfg.log"; fail=1; continue; }
  if [ "$st" -eq 0 ] && grep -q '^Model checking completed. No error has been found.' "$work/$cfg.log"; then
    echo "PASS: $cfg — $(grep -E '^[0-9]+ states generated' "$work/$cfg.log")"
  else
    tail -40 "$work/$cfg.log"; echo "FAIL: $cfg (exit $st): expected no error"; fail=1
  fi
done

cfg=ProvenanceBothLeak
run "$cfg"; st=$?
if ! grep -qF "$EXPECT_VERSION" "$work/$cfg.log"; then
  echo "FAIL: $cfg: TLC is not '$EXPECT_VERSION'"; head -5 "$work/$cfg.log"; fail=1
elif [ "$st" -ne 0 ] && grep -q '^Error: Invariant Genuine is violated' "$work/$cfg.log"; then
  echo "PASS: $cfg — TLC found the both-keys forgery, as it must"
else
  tail -40 "$work/$cfg.log"; echo "FAIL: $cfg (exit $st): expected 'Invariant Genuine is violated'"; fail=1
fi

[ "$fail" -eq 0 ] || { echo "PROVENANCE MODEL CHECK FAILED"; exit 1; }
echo "OK: provenance model — Genuine holds with one leaked key, fails with two"
