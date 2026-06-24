#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

if ! command -v selur-compose >/dev/null 2>&1; then
  echo "ERROR: selur-compose is required but was not found in PATH."
  exit 1
fi

export SVALINN_URL="${SVALINN_URL:-http://localhost:8080}"
export VORDR_MCP_URL="${VORDR_MCP_URL:-http://localhost:8081}"

COMPOSE_FILE="${SELUR_COMPOSE_FILE:-runtime/compose.toml}"

echo "==> Stopping PanLL surrounding stack"
selur-compose -f "$COMPOSE_FILE" down -v
