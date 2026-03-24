# SPDX-License-Identifier: PMPL-1.0-or-later
# PanLL Justfile — Project shortcut for eNSAID development

set shell := ["bash", "-uc"]
set dotenv-load := true

project := "PanLL"
version := "0.1.0-alpha"

# Default: list all recipes
default:
    @just --list --unsorted

# Start full development environment (Tauri app + watchers)
dev:
    @echo "🚀 Starting PanLL eNSAID Development Environment..."
    @# Start watchers in background and run tauri dev in foreground
    @(deno task res:watch) & 
    (deno task css:watch) & 
    deno task dev; 
    echo "Stopping background processes..."; 
    pkill -P $$ 2>/dev/null || true

# Start web-only development environment (Browser + watchers)
serve:
    @echo "🌐 Starting PanLL Web-only Development Environment..."
    @(deno task res:watch) & 
    (deno task css:watch) & 
    deno task serve:dev; 
    echo "Stopping background processes..."; 
    pkill -P $$ 2>/dev/null || true

# Run mock ECHIDNA theorem prover advisor
mock:
    @echo "🦄 Starting Mock ECHIDNA server..."
    deno task mock:echidna

# Build the project for production (Tauri)
build:
    @echo "🏗️  Building PanLL for production..."
    deno task res:build
    deno task css:build
    deno task build

# Run all tests
test *args:
    @echo "🧪 Running PanLL test suite..."
    deno task test {{args}}

# Clean build artifacts
clean:
    @echo "🧹 Cleaning build artifacts..."
    deno task res:clean
    rm -f public/styles.css
    rm -rf src-tauri/target/

# ═══════════════════════════════════════════════════════════════════════════════
# RUNTIME & CONTAINERS
# ═══════════════════════════════════════════════════════════════════════════════

# Start the PanLL runtime environment (compose)
runtime *args:
    @echo "🐳 Starting PanLL runtime stack..."
    cd runtime && selur-compose up {{args}}

# Stop the PanLL runtime environment
runtime-down:
    @echo "🛑 Stopping PanLL runtime stack..."
    cd runtime && selur-compose down

# ═══════════════════════════════════════════════════════════════════════════════
# LINT & FORMAT
# ═══════════════════════════════════════════════════════════════════════════════

# Lint and format
lint:
    deno task lint
    deno task fmt --check

fmt:
    deno task fmt

# Run panic-attacker pre-commit scan
assail:
    @command -v panic-attack >/dev/null 2>&1 && panic-attack assail . || echo "panic-attack not found — install from https://github.com/hyperpolymath/panic-attacker"

# ═══════════════════════════════════════════════════════════════════════════════
# ONBOARDING & DIAGNOSTICS
# ═══════════════════════════════════════════════════════════════════════════════

# Check all required toolchain dependencies and report health
doctor:
    #!/usr/bin/env bash
    echo "═══════════════════════════════════════════════════"
    echo "  PanLL Doctor — Toolchain Health Check"
    echo "═══════════════════════════════════════════════════"
    echo ""
    PASS=0; FAIL=0; WARN=0
    check() {
        local name="$1" cmd="$2" min="$3"
        if command -v "$cmd" >/dev/null 2>&1; then
            VER=$("$cmd" --version 2>&1 | head -1)
            echo "  [OK]   $name — $VER"
            PASS=$((PASS + 1))
        else
            echo "  [FAIL] $name — not found (need $min+)"
            FAIL=$((FAIL + 1))
        fi
    }
    check "Deno"              deno      "2.0"
    check "Rust (cargo)"      cargo     "1.80"
    check "Zig"               zig       "0.13"
    check "just"              just      "1.25"
    # ReScript via deno
    if deno run -A npm:rescript --version >/dev/null 2>&1; then
        RESVER=$(deno run -A npm:rescript --version 2>&1 | head -1)
        echo "  [OK]   ReScript — $RESVER"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] ReScript — not available via deno (need 12.0+)"
        FAIL=$((FAIL + 1))
    fi
    # Optional tools
    if command -v elixir >/dev/null 2>&1; then
        echo "  [OK]   Elixir (optional) — $(elixir --version 2>&1 | grep Elixir | head -1)"
        PASS=$((PASS + 1))
    else
        echo "  [WARN] Elixir (optional) — not found (needed for beam/ middleware)"
        WARN=$((WARN + 1))
    fi
    if command -v panic-attack >/dev/null 2>&1; then
        echo "  [OK]   panic-attack — available"
        PASS=$((PASS + 1))
    else
        echo "  [WARN] panic-attack — not found (pre-commit scanner)"
        WARN=$((WARN + 1))
    fi
    echo ""
    echo "  Result: $PASS passed, $FAIL failed, $WARN warnings"
    if [ "$FAIL" -gt 0 ]; then
        echo "  Run 'just heal' to attempt automatic repair."
        exit 1
    fi
    echo "  All required tools present."

# Attempt to automatically install missing tools
heal:
    #!/usr/bin/env bash
    echo "═══════════════════════════════════════════════════"
    echo "  PanLL Heal — Automatic Tool Installation"
    echo "═══════════════════════════════════════════════════"
    echo ""
    if ! command -v deno >/dev/null 2>&1; then
        echo "Installing Deno..."
        curl -fsSL https://deno.land/install.sh | sh
    fi
    if ! command -v cargo >/dev/null 2>&1; then
        echo "Installing Rust via rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    if ! command -v zig >/dev/null 2>&1; then
        echo "Zig not found. Install with: asdf install zig latest"
        echo "  or download from https://ziglang.org/download/"
    fi
    if ! command -v just >/dev/null 2>&1; then
        echo "Installing just..."
        cargo install just
    fi
    # Install Deno deps (including ReScript)
    echo "Installing Deno dependencies..."
    deno install
    echo ""
    echo "Heal complete. Run 'just doctor' to verify."

# Guided tour of the project structure and key concepts
tour:
    #!/usr/bin/env bash
    echo "═══════════════════════════════════════════════════"
    echo "  PanLL eNSAID — Guided Tour"
    echo "═══════════════════════════════════════════════════"
    echo ""
    echo "PanLL is a neurosymbolic AI development environment with three panels:"
    echo ""
    echo "  Panel-L (Symbolic)  Formal constraints, proof editor"
    echo "  Panel-N (Neural)    Inference tokens, ECHIDNA advisor"
    echo "  Panel-W (World)     Task canvas, VeriSimDB, security"
    echo ""
    echo "Architecture: ReScript TEA (The Elm Architecture)"
    echo "  Model.res    → State composition root"
    echo "  Msg.res      → Message variants"
    echo "  Update.res   → State transition kernel (~7500 lines)"
    echo "  View.res     → Root view renderer"
    echo ""
    echo "Backend: Gossamer (Rust + WebKitGTK)"
    echo "  src-gossamer/  → Rust commands and native window"
    echo ""
    echo "Key engines in src/core/:"
    echo "  AntiCrash.res       Circuit breaker (validates neural tokens)"
    echo "  OrbitalSync.res     Cross-panel synchronisation"
    echo "  Contractiles.res    Elastic state contracts"
    echo "  TypeLLEngine.res    Cross-panel type intelligence"
    echo "  VabEngine.res       Verified Assembly Building"
    echo ""
    echo "Quick commands:"
    echo "  just dev       Start full dev environment"
    echo "  just serve     Browser-only dev (no native window)"
    echo "  just test      Run 979 tests"
    echo "  just mock      Start mock ECHIDNA prover (port 9000)"
    echo "  just build     Production build"
    echo ""
    echo "Tests: 979 tests in 41 suites (deno test)"
    echo "Panels: 106 across three panes"
    echo ""
    echo "Read more: docs/TEA_GUIDE.md, QUICKSTART-USER.adoc"

# Show help for common workflows
help-me:
    #!/usr/bin/env bash
    echo "═══════════════════════════════════════════════════"
    echo "  PanLL — Common Workflows"
    echo "═══════════════════════════════════════════════════"
    echo ""
    echo "FIRST TIME SETUP:"
    echo "  deno install          Install dependencies"
    echo "  just doctor           Check toolchain"
    echo "  just heal             Fix missing tools"
    echo ""
    echo "DEVELOPMENT:"
    echo "  just dev              Full dev environment (Gossamer + watchers)"
    echo "  just serve            Browser-only dev (no native window)"
    echo "  just mock             Start mock ECHIDNA server (port 9000)"
    echo ""
    echo "BUILD & TEST:"
    echo "  just build            Production build"
    echo "  just test             Run all tests"
    echo "  just lint             Lint and format check"
    echo "  just fmt              Auto-format"
    echo ""
    echo "PRE-COMMIT:"
    echo "  just assail           Run panic-attacker scan"
    echo ""
    echo "INFRASTRUCTURE:"
    echo "  just runtime          Start compose stack"
    echo "  just runtime-down     Stop compose stack"
    echo "  just clean            Clean build artifacts"
    echo ""
    echo "LEARN:"
    echo "  just tour             Guided project tour"
    echo "  just default          List all recipes"
