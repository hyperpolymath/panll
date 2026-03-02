#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later

set -euo pipefail

command_name="$(basename "$0")"
action="${1:-}"
shift || true

repo="."
snapshot=".maintenance-perms-state.tsv"

usage() {
    cat <<USAGE
usage: ${command_name} <snapshot|lock|restore|audit> [options]

Manage repository permission hardening with reversible snapshots.

Actions:
  snapshot              Write current file/dir modes to snapshot file
  lock                  Apply restrictive policy (audit-safe defaults)
  restore               Restore modes from snapshot file
  audit                 Run permission-policy audit via run-maintenance.sh

Options:
  --repo <path>         Repository path (default: current directory)
  --snapshot <path>     Snapshot file path (default: .maintenance-perms-state.tsv)
  --output <path>       Only for audit: JSON report path
  -h, --help            Show this help
USAGE
}

audit_output=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)
            repo="${2:-}"
            shift 2
            ;;
        --snapshot)
            snapshot="${2:-}"
            shift 2
            ;;
        --output)
            audit_output="${2:-}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "error: unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [[ -z "${action}" ]]; then
    usage >&2
    exit 2
fi

repo="$(cd "${repo}" && pwd)"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
run_maint="${script_dir}/run-maintenance.sh"

if [[ ! -d "${repo}" ]]; then
    echo "error: repo path not found: ${repo}" >&2
    exit 2
fi

if [[ "${snapshot}" != /* ]]; then
    snapshot="${repo}/${snapshot}"
fi

prune_expr=(
    -name .git -o -name target -o -name node_modules -o -name .venv -o
    -name _build -o -name build -o -name dist -o -name .zig-cache -o
    -name .mypy_cache -o -name .pytest_cache -o -name .ruff_cache -o
    -name vendor -o -name deps
)

write_snapshot() {
    local out="$1"
    local tmp
    tmp="$(mktemp)"

    (
        cd "${repo}"
        find . \
            \( -type d \( "${prune_expr[@]}" \) -prune \) -o \
            \( \( -type f -o -type d \) -print0 \)
    ) | while IFS= read -r -d '' path; do
        rel="${path#./}"
        mode="$(stat -c '%a' "${repo}/${rel}")"
        if [[ -d "${repo}/${rel}" ]]; then
            type="d"
        else
            type="f"
        fi
        printf '%s\t%s\t%s\n' "${mode}" "${type}" "${rel}"
    done >"${tmp}"

    mkdir -p "$(dirname "${out}")"
    mv "${tmp}" "${out}"
}

lock_permissions() {
    local writable_files=0
    local writable_dirs=0
    local removed_exec=0
    local added_exec=0

    while IFS= read -r -d '' path; do
        chmod go-w "${path}" 2>/dev/null || true
        writable_files=$((writable_files + 1))
    done < <(
        find "${repo}" \
            \( -type d \( "${prune_expr[@]}" \) -prune \) -o \
            \( -type f -perm /022 -print0 \)
    )

    while IFS= read -r -d '' path; do
        chmod go-w "${path}" 2>/dev/null || true
        writable_dirs=$((writable_dirs + 1))
    done < <(
        find "${repo}" \
            \( -type d \( "${prune_expr[@]}" \) -prune \) -o \
            \( -type d -perm /022 -print0 \)
    )

    while IFS= read -r -d '' path; do
        rel="${path#"${repo}/"}"
        first_two="$(head -c 2 "${path}" 2>/dev/null || true)"
        if [[ "${first_two}" == "#!" ]]; then
            continue
        fi
        if [[ "${rel}" =~ \.(sh|bash|zsh|fish|py|pl|rb|ps1)$ ]]; then
            continue
        fi
        chmod a-x "${path}" 2>/dev/null || true
        removed_exec=$((removed_exec + 1))
    done < <(
        find "${repo}" \
            \( -type d \( "${prune_expr[@]}" \) -prune \) -o \
            \( -type f -perm /111 -print0 \)
    )

    while IFS= read -r -d '' path; do
        first_two="$(head -c 2 "${path}" 2>/dev/null || true)"
        if [[ "${first_two}" == "#!" ]]; then
            chmod u+x "${path}" 2>/dev/null || true
            added_exec=$((added_exec + 1))
        fi
    done < <(
        find "${repo}" \
            \( -type d \( "${prune_expr[@]}" \) -prune \) -o \
            \( -type f \
                \( -name '*.sh' -o -name '*.bash' -o -name '*.zsh' -o -name '*.fish' -o -name '*.py' -o -name '*.pl' -o -name '*.rb' -o -name '*.ps1' \) \
                ! -perm /111 \
                -print0 \)
    )

    echo "lock complete"
    echo "  tightened files (go-w): ${writable_files}"
    echo "  tightened dirs  (go-w): ${writable_dirs}"
    echo "  removed accidental exec: ${removed_exec}"
    echo "  restored script exec: ${added_exec}"
    echo "  snapshot: ${snapshot}"
}

restore_permissions() {
    if [[ ! -f "${snapshot}" ]]; then
        echo "error: snapshot not found: ${snapshot}" >&2
        exit 2
    fi

    local restored=0
    local missing=0
    local mismatched=0

    while IFS=$'\t' read -r mode type rel; do
        [[ -z "${mode}" || -z "${type}" || -z "${rel}" ]] && continue
        path="${repo}/${rel}"
        if [[ ! -e "${path}" ]]; then
            missing=$((missing + 1))
            continue
        fi
        if [[ "${type}" == "d" && ! -d "${path}" ]]; then
            mismatched=$((mismatched + 1))
            continue
        fi
        if [[ "${type}" == "f" && ! -f "${path}" ]]; then
            mismatched=$((mismatched + 1))
            continue
        fi
        chmod "${mode}" "${path}" 2>/dev/null || true
        restored=$((restored + 1))
    done < "${snapshot}"

    echo "restore complete"
    echo "  restored: ${restored}"
    echo "  missing: ${missing}"
    echo "  type mismatches: ${mismatched}"
}

case "${action}" in
    snapshot)
        write_snapshot "${snapshot}"
        echo "snapshot written: ${snapshot}"
        ;;
    lock)
        if [[ ! -f "${snapshot}" ]]; then
            write_snapshot "${snapshot}"
            echo "snapshot written: ${snapshot}"
        fi
        lock_permissions
        ;;
    restore)
        restore_permissions
        ;;
    audit)
        if [[ ! -x "${run_maint}" ]]; then
            echo "error: missing executable: ${run_maint}" >&2
            exit 2
        fi
        audit_args=(--repo "${repo}" --skip-panic --skip-todo)
        if [[ -n "${audit_output}" ]]; then
            audit_args+=(--output "${audit_output}")
        fi
        "${run_maint}" "${audit_args[@]}"
        ;;
    *)
        echo "error: unknown action: ${action}" >&2
        usage >&2
        exit 2
        ;;
esac
