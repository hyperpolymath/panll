#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

if ! command -v selur-compose >/dev/null 2>&1; then
  echo "ERROR: selur-compose is required but was not found in PATH."
  exit 1
fi

if [[ "${PANLL_SKIP_BUILD:-0}" != "1" ]]; then
  "${ROOT_DIR}/runtime/scripts/build-pack-verify.sh"
fi

export SVALINN_URL="${SVALINN_URL:-http://localhost:8080}"
export VORDR_MCP_URL="${VORDR_MCP_URL:-http://localhost:8081}"

COMPOSE_FILE="${SELUR_COMPOSE_FILE:-runtime/compose.toml}"

echo "==> Starting PanLL surrounding stack with selur-compose"
echo "    compose file: ${COMPOSE_FILE}"
echo "    SVALINN_URL=${SVALINN_URL}"
echo "    VORDR_MCP_URL=${VORDR_MCP_URL}"
selur-compose -f "$COMPOSE_FILE" up
