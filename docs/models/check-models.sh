#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# check-models.sh TLA2TOOLS_JAR — model-check docs/models/Provenance.tla both
# ways (PROOF-POLICY §4: a finite model check is TESTED, with its bounds):
#
#   Provenance.cfg           must find no error (Unforgeable, Linked hold);
#   ProvenanceNoWitness.cfg  must report Unforgeable violated (mutation);
#   ProvenanceReachable.cfg  must report NeverVerified violated (non-vacuity).
#
# The jar must be TLC 2.19 (tlaplus release v1.7.4) with the pinned digest;
# anything else fails. A missing java or jar is a failure, never a skip.
set -uo pipefail
JAR="${1:?usage: check-models.sh TLA2TOOLS_JAR}"
JAR_SHA256="936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88"
cd -- "$(dirname -- "${BASH_SOURCE[0]}")" || exit 1
fail=0
die() { printf 'FAIL: %s\n' "$1"; exit 1; }
command -v java >/dev/null || die "java not on PATH"
[ -f "$JAR" ] || die "no jar at $JAR"
got="$(sha256sum "$JAR" | cut -d' ' -f1)"
[ "$got" = "$JAR_SHA256" ] || die "tla2tools.jar digest $got, expected $JAR_SHA256"
echo "model sha256: $(sha256sum Provenance.tla | cut -d' ' -f1)"
OUT="$(mktemp -d)"

# run CFG LOG: run TLC on Provenance.tla with CFG, output to LOG.
run() {
  java -XX:+UseParallelGC -cp "$JAR" tlc2.TLC -workers auto \
    -metadir "$OUT/meta-$1" -config "$1" Provenance > "$2" 2>&1
}

run Provenance.cfg "$OUT/holds.log"; st=$?
grep -m1 -E '^TLC2 Version' "$OUT/holds.log" || true
grep -q '^TLC2 Version 2\.19 ' "$OUT/holds.log" || die "TLC is not version 2.19"
if [ "$st" -eq 0 ] && grep -q 'Model checking completed. No error has been found' "$OUT/holds.log"; then
  grep -E 'states generated|depth of the complete state graph' "$OUT/holds.log"
  echo "PASS: Provenance.cfg — TypeOK, Unforgeable and Linked hold"
else
  tail -40 "$OUT/holds.log"; echo "FAIL: Provenance.cfg (exit $st)"; fail=1
fi

run ProvenanceNoWitness.cfg "$OUT/nowitness.log"
if grep -q 'Invariant Unforgeable is violated' "$OUT/nowitness.log"; then
  echo "PASS: ProvenanceNoWitness.cfg — forgery found without the witness check"
else
  tail -40 "$OUT/nowitness.log"; echo "FAIL: ProvenanceNoWitness.cfg found no forgery"; fail=1
fi

run ProvenanceReachable.cfg "$OUT/reachable.log"
if grep -q 'Invariant NeverVerified is violated' "$OUT/reachable.log"; then
  echo "PASS: ProvenanceReachable.cfg — a verified state is reachable"
else
  tail -40 "$OUT/reachable.log"; echo "FAIL: ProvenanceReachable.cfg reached no verified state"; fail=1
fi

rm -rf "$OUT"
[ "$fail" -eq 0 ] || { echo "PROVENANCE MODEL CHECK FAILED"; exit 1; }
echo "OK: provenance model checked both ways"
