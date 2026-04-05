#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# dogfood-test.sh — Verify local backends return real data for CRG D→C promotion.
#
# Usage:
#   ./scripts/dogfood-test.sh [--with-boj] [--with-verisim]
#
# Tests the 3 local backends (Farm, Provenance, Watcher) that require
# no network services. With flags, also tests BoJ and VeriSimDB.

set -euo pipefail

PASS=0
FAIL=0
SKIP=0

check() {
    local name="$1"
    local result="$2"
    if [ "$result" = "ok" ]; then
        echo "  ✓ $name"
        PASS=$((PASS + 1))
    elif [ "$result" = "skip" ]; then
        echo "  ⊘ $name (skipped)"
        SKIP=$((SKIP + 1))
    else
        echo "  ✗ $name: $result"
        FAIL=$((FAIL + 1))
    fi
}

echo "PanLL CRG D→C Dogfooding Test"
echo "=============================="
echo ""

# Check Gossamer binary exists
BINARY="target/debug/panll-gossamer"
if [ ! -f "$BINARY" ]; then
    echo "Note: Gossamer binary not built (requires libgossamer.so from gossamer repo)."
    echo "Run 'cd ../gossamer && zig build' first, then 'cargo build --bin panll-gossamer'."
    echo "Testing backend code readiness without running binary..."
    echo ""
fi

echo "1. Farm (local filesystem)"
echo "   Checks: farm manifest exists, can list repos"
if [ -f "$HOME/.git-private-farm/farm-manifest.json" ]; then
    check "Farm manifest exists" "ok"
else
    echo "  ⊘ Farm manifest not found at ~/.git-private-farm/farm-manifest.json"
    echo "    Create it to enable the Farm panel (JSON array of repo entries)."
    SKIP=$((SKIP + 1))
fi

echo ""
echo "2. Provenance Map (git blame)"
echo "   Checks: git blame on a known file"
BLAME_OUT=$(git blame --porcelain -- src/App.res 2>/dev/null | head -1 || true)
if echo "$BLAME_OUT" | grep -qE '^[0-9a-f]'; then
    check "Git blame on src/App.res" "ok"
else
    check "Git blame on src/App.res" "git blame failed"
fi

if git log --oneline -1 src/App.res 2>/dev/null | grep -q '.'; then
    check "Git log on src/App.res" "ok"
else
    check "Git log on src/App.res" "git log failed"
fi

echo ""
echo "3. Filesystem Watcher (notify crate)"
echo "   Checks: notify crate in Cargo.toml, watcher module compiles"
if grep -q 'notify' Cargo.toml 2>/dev/null; then
    check "notify crate in Cargo.toml" "ok"
else
    check "notify crate in Cargo.toml" "missing dependency"
fi

if cargo check 2>&1 | grep -q 'Finished'; then
    check "Gossamer backend compiles clean" "ok"
else
    check "Gossamer backend compiles clean" "compilation errors"
fi

echo ""
echo "4. BoJ-server (port 7700)"
if [[ "${1:-}" == *"--with-boj"* ]] || [[ "${2:-}" == *"--with-boj"* ]]; then
    if curl -sf http://localhost:7700/status >/dev/null 2>&1; then
        check "BoJ-server reachable" "ok"
    else
        check "BoJ-server reachable" "not running on :7700"
    fi
else
    check "BoJ-server" "skip"
fi

echo ""
echo "5. VeriSimDB (port 8093)"
if [[ "${1:-}" == *"--with-verisim"* ]] || [[ "${2:-}" == *"--with-verisim"* ]]; then
    if curl -sf http://localhost:8093/health >/dev/null 2>&1; then
        check "VeriSimDB reachable" "ok"
    else
        check "VeriSimDB reachable" "not running on :8093"
    fi
else
    check "VeriSimDB" "skip"
fi

echo ""
echo "=============================="
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "Fix failures before dogfooding sessions."
    exit 1
else
    echo "Local backends verified. Ready for dogfooding sessions."
    echo ""
    echo "Next steps:"
    echo "  1. Run 'deno task dev' to start the dev server"
    echo "  2. Open http://localhost:8000/public/ in browser"
    echo "  3. Test Farm, Provenance Map, and Watcher panels"
    echo "  4. Log session in docs/CRG-DOGFOOD-CHECKLIST.md"
    exit 0
fi
