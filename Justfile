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
