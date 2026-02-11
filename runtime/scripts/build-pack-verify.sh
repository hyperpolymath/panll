#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

if command -v podman >/dev/null 2>&1; then
  OCI_ENGINE="podman"
elif command -v docker >/dev/null 2>&1; then
  OCI_ENGINE="docker"
else
  echo "ERROR: neither podman nor docker is available."
  exit 1
fi

if ! command -v ct >/dev/null 2>&1; then
  echo "ERROR: ct (Cerro Torre) is required but was not found in PATH."
  exit 1
fi

IMAGE_REF="${PANLL_IMAGE_REF:-localhost/panll-beam:dev}"
BUNDLE_OUT="${PANLL_BUNDLE_OUT:-runtime/out/panll-beam.ctp}"
POLICY="${PANLL_CT_POLICY:-strict}"
POLICY_FILE="${PANLL_CT_POLICY_FILE:-}"

mkdir -p "$(dirname "$BUNDLE_OUT")"

echo "==> Building Chainguard-backed PanLL BEAM image: ${IMAGE_REF}"
"$OCI_ENGINE" build -f runtime/Containerfile -t "$IMAGE_REF" .

echo "==> Packing with Cerro Torre: ${BUNDLE_OUT}"
ct pack "$IMAGE_REF" -o "$BUNDLE_OUT"

echo "==> Verifying bundle"
if [[ -n "$POLICY_FILE" ]]; then
  ct verify "$BUNDLE_OUT" --policy "$POLICY_FILE"
else
  ct verify "$BUNDLE_OUT" --policy "$POLICY"
fi

echo "OK: PanLL bundle built and verified -> ${BUNDLE_OUT}"
