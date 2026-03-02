#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later

set -euo pipefail

repo=""
output_path=""
logs_dir=""
panic_attack_bin="${PANIC_ATTACK_BIN:-}"
with_bench=false
strict=false
fail_on_warn=false
skip_panic=false
skip_todo=false
skip_perms=false
fix_perms=false
want_rust=false
want_python=false
want_elixir=false
explicit_lang_selection=false

usage() {
    cat <<USAGE
usage: $0 [options]

Run a generic maintenance check flow and emit a JSON report.

Options:
  --repo <path>        Repository path (default: current directory)
  --output <path>      JSON report path (default: /tmp/maintenance-report-<timestamp>.json)
  --logs-dir <path>    Log directory (default: /tmp/maintenance-logs-<timestamp>)
  --panic-bin <path>   panic-attack binary path
  --bench              Run benchmark step (Rust: cargo bench)
  --strict             Exit non-zero if any step fails
  --fail-on-warn       Exit non-zero if any step warns or fails
  --skip-panic         Skip panic-attacker step
  --skip-todo          Skip TODO/FIXME scan
  --skip-perms         Skip permission-policy scan
  --fix-perms          Apply permission fixes (opt-in; audit-only by default)
  --rust               Run Rust checks
  --python             Run Python checks
  --elixir             Run Elixir checks
  -h, --help           Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)
            repo="${2:-}"
            shift 2
            ;;
        --output)
            output_path="${2:-}"
            shift 2
            ;;
        --logs-dir)
            logs_dir="${2:-}"
            shift 2
            ;;
        --panic-bin)
            panic_attack_bin="${2:-}"
            shift 2
            ;;
        --bench)
            with_bench=true
            shift
            ;;
        --strict)
            strict=true
            shift
            ;;
        --fail-on-warn)
            fail_on_warn=true
            shift
            ;;
        --skip-panic)
            skip_panic=true
            shift
            ;;
        --skip-todo)
            skip_todo=true
            shift
            ;;
        --skip-perms)
            skip_perms=true
            shift
            ;;
        --fix-perms)
            fix_perms=true
            shift
            ;;
        --rust)
            want_rust=true
            explicit_lang_selection=true
            shift
            ;;
        --python)
            want_python=true
            explicit_lang_selection=true
            shift
            ;;
        --elixir)
            want_elixir=true
            explicit_lang_selection=true
            shift
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

if [[ -z "$repo" ]]; then
    repo="$(pwd)"
fi
repo="$(cd "$repo" && pwd)"

timestamp_utc="$(date -u +%Y%m%dT%H%M%SZ)"
if [[ -z "$output_path" ]]; then
    output_path="/tmp/maintenance-report-${timestamp_utc}.json"
fi
if [[ -z "$logs_dir" ]]; then
    logs_dir="/tmp/maintenance-logs-${timestamp_utc}"
fi
mkdir -p "$logs_dir"

if ! command -v jq >/dev/null 2>&1; then
    echo "error: jq is required." >&2
    exit 127
fi

if ! command -v git >/dev/null 2>&1; then
    echo "error: git is required." >&2
    exit 127
fi

steps='[]'

add_step() {
    local name="$1"
    local status="$2"
    local duration="$3"
    local log_path="$4"
    local details='{}'
    if [[ $# -ge 5 ]]; then
        details="$5"
    fi
    steps="$(jq -c \
        --arg name "$name" \
        --arg status "$status" \
        --argjson duration "$duration" \
        --arg log_path "$log_path" \
        --argjson details "$details" \
        '. + [{name: $name, status: $status, duration_seconds: $duration, log: $log_path, details: $details}]' \
        <<<"$steps")"
}

run_step() {
    local name="$1"
    shift
    local log_path="${logs_dir}/${name}.log"
    local start end duration status

    start="$(date +%s)"
    if "$@" >"$log_path" 2>&1; then
        status="pass"
    else
        status="fail"
    fi
    end="$(date +%s)"
    duration="$((end - start))"
    add_step "$name" "$status" "$duration" "$log_path"
    [[ "$status" == "pass" ]]
}

run_repo_cmd() {
    (
        cd "$repo"
        "$@"
    )
}

git_commit=""
git_branch=""
if git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git_commit="$(git -C "$repo" rev-parse HEAD)"
    git_branch="$(git -C "$repo" rev-parse --abbrev-ref HEAD)"
    run_step "git_status" git -C "$repo" status --porcelain || true
else
    add_step "git_status" "skipped" 0 "${logs_dir}/git_status.log" '{"reason":"not a git worktree"}'
fi

if [[ "$skip_todo" == true ]]; then
    add_step "todo_scan" "skipped" 0 "${logs_dir}/todo_scan.log" '{"reason":"disabled by --skip-todo"}'
else
    todo_log="${logs_dir}/todo_scan.log"
    start="$(date +%s)"
    todo_hits="$(rg -n "TODO|FIXME|XXX|HACK|STUB|PARTIAL" \
        -g '!**/.git/**' \
        -g '!**/target/**' \
        "$repo" || true)"
    printf '%s\n' "$todo_hits" >"$todo_log"
    end="$(date +%s)"
    duration="$((end - start))"
    todo_count="$(printf '%s\n' "$todo_hits" | sed '/^$/d' | wc -l | tr -d ' ')"
    todo_details="$(jq -nc --argjson count "$todo_count" '{matches: $count}')"
    if (( todo_count == 0 )); then
        add_step "todo_scan" "pass" "$duration" "$todo_log" "$todo_details"
    else
        add_step "todo_scan" "warn" "$duration" "$todo_log" "$todo_details"
    fi
fi

if [[ "$skip_perms" == true ]]; then
    add_step "permission_policy" "skipped" 0 "${logs_dir}/permission_policy.log" '{"reason":"disabled by --skip-perms"}'
else
    perms_log="${logs_dir}/permission_policy.log"
    start="$(date +%s)"

    ignore_file="${repo}/.maintenance-perms-ignore"
    ignore_patterns=()
    if [[ -f "${ignore_file}" ]]; then
        while IFS= read -r line; do
            [[ -z "${line}" || "${line}" =~ ^[[:space:]]*# ]] && continue
            ignore_patterns+=("${line}")
        done < "${ignore_file}"
    fi

    is_ignored_path() {
        local rel="$1"
        local pat
        for pat in "${ignore_patterns[@]}"; do
            if [[ "${rel}" =~ ${pat} ]]; then
                return 0
            fi
        done
        return 1
    }

    prune_expr=(
        -name .git -o -name target -o -name node_modules -o -name .venv -o
        -name _build -o -name build -o -name dist -o -name .zig-cache -o
        -name .mypy_cache -o -name .pytest_cache -o -name .ruff_cache -o
        -name vendor -o -name deps
    )

    writable_files=()
    while IFS= read -r -d '' path; do
        rel="${path#./}"
        if ! is_ignored_path "${rel}"; then
            writable_files+=("${rel}")
        fi
    done < <(
        cd "${repo}" &&
            find . \
                \( -type d \( "${prune_expr[@]}" \) -prune \) -o \
                \( -type f -perm /022 -print0 \)
    )

    writable_dirs=()
    while IFS= read -r -d '' path; do
        rel="${path#./}"
        if ! is_ignored_path "${rel}"; then
            writable_dirs+=("${rel}")
        fi
    done < <(
        cd "${repo}" &&
            find . \
                \( -type d \( "${prune_expr[@]}" \) -prune \) -o \
                \( -type d -perm /022 -print0 \)
    )

    suspicious_exec=()
    while IFS= read -r -d '' path; do
        rel="${path#./}"
        if is_ignored_path "${rel}"; then
            continue
        fi

        abs="${repo}/${rel}"
        first_two="$(head -c 2 "${abs}" 2>/dev/null || true)"
        if [[ "${first_two}" == "#!" ]]; then
            continue
        fi
        if [[ "${rel}" =~ \.(sh|bash|zsh|fish|py|pl|rb|ps1)$ ]]; then
            continue
        fi
        suspicious_exec+=("${rel}")
    done < <(
        cd "${repo}" &&
            find . \
                \( -type d \( "${prune_expr[@]}" \) -prune \) -o \
                \( -type f -perm /111 -print0 \)
    )

    shebang_not_exec=()
    while IFS= read -r -d '' path; do
        rel="${path#./}"
        if is_ignored_path "${rel}"; then
            continue
        fi

        abs="${repo}/${rel}"
        first_two="$(head -c 2 "${abs}" 2>/dev/null || true)"
        if [[ "${first_two}" == "#!" ]]; then
            shebang_not_exec+=("${rel}")
        fi
    done < <(
        cd "${repo}" &&
            find . \
                \( -type d \( "${prune_expr[@]}" \) -prune \) -o \
                \( -type f \
                    \( -name '*.sh' -o -name '*.bash' -o -name '*.zsh' -o -name '*.fish' -o -name '*.py' -o -name '*.pl' -o -name '*.rb' -o -name '*.ps1' \) \
                    ! -perm /111 \
                    -print0 \)
    )

    if [[ "$fix_perms" == true ]]; then
        for rel in "${writable_files[@]}"; do
            chmod go-w "${repo}/${rel}" 2>/dev/null || true
        done

        for rel in "${writable_dirs[@]}"; do
            chmod go-w "${repo}/${rel}" 2>/dev/null || true
        done

        for rel in "${suspicious_exec[@]}"; do
            chmod a-x "${repo}/${rel}" 2>/dev/null || true
        done

        for rel in "${shebang_not_exec[@]}"; do
            chmod u+x "${repo}/${rel}" 2>/dev/null || true
        done
    fi

    {
        echo "Permission policy scan"
        echo "Repo: ${repo}"
        echo
        if [[ -f "${ignore_file}" ]]; then
            echo "Ignore file: ${ignore_file}"
        else
            echo "Ignore file: <none>"
        fi
        echo
        echo "Writable files (g+w or o+w): ${#writable_files[@]}"
        printf '%s\n' "${writable_files[@]}"
        echo
        echo "Writable directories (g+w or o+w): ${#writable_dirs[@]}"
        printf '%s\n' "${writable_dirs[@]}"
        echo
        echo "Executable files without shebang/ext allowlist: ${#suspicious_exec[@]}"
        printf '%s\n' "${suspicious_exec[@]}"
        echo
        echo "Shebang scripts missing executable bit: ${#shebang_not_exec[@]}"
        printf '%s\n' "${shebang_not_exec[@]}"
        echo
        echo "Fix mode: ${fix_perms}"
    } >"${perms_log}"

    end="$(date +%s)"
    duration="$((end - start))"

    perms_details="$(jq -nc \
        --arg ignore_file "${ignore_file}" \
        --argjson writable_files "${#writable_files[@]}" \
        --argjson writable_dirs "${#writable_dirs[@]}" \
        --argjson suspicious_exec "${#suspicious_exec[@]}" \
        --argjson shebang_not_exec "${#shebang_not_exec[@]}" \
        --arg fix_mode "${fix_perms}" \
        '{
            ignore_file: $ignore_file,
            writable_files: $writable_files,
            writable_dirs: $writable_dirs,
            suspicious_exec: $suspicious_exec,
            shebang_not_exec: $shebang_not_exec,
            fix_mode: $fix_mode
        }')"

    if (( ${#writable_files[@]} == 0 && ${#writable_dirs[@]} == 0 && ${#suspicious_exec[@]} == 0 && ${#shebang_not_exec[@]} == 0 )); then
        add_step "permission_policy" "pass" "${duration}" "${perms_log}" "${perms_details}"
    else
        add_step "permission_policy" "warn" "${duration}" "${perms_log}" "${perms_details}"
    fi
fi

if [[ "$skip_panic" == true ]]; then
    add_step "panic_assail" "skipped" 0 "${logs_dir}/panic_assail.log" '{"reason":"disabled by --skip-panic"}'
else
    if [[ -z "$panic_attack_bin" ]]; then
        panic_candidates=(
            "${repo}/target/release/panic-attack"
            "${repo}/tools/panic-attack"
            "${repo}/bin/panic-attack"
        )
        for candidate in "${panic_candidates[@]}"; do
            if [[ -x "$candidate" ]]; then
                panic_attack_bin="$candidate"
                break
            fi
        done
    fi
    if [[ -z "$panic_attack_bin" ]]; then
        panic_attack_bin="panic-attack"
    fi

    if command -v "$panic_attack_bin" >/dev/null 2>&1; then
        panic_log="${logs_dir}/panic_assail.log"
        panic_report="${logs_dir}/panic_assail.json"
        : >"${panic_log}"

        panic_scope="full_repo"
        analysis_target="${repo}"
        panic_source_builder="${repo}/scripts/ci/build-panic-assail-source.sh"
        panic_baseline_file="${repo}/scripts/ci/panic-assail-baseline.json"
        baseline_weak_points=-1
        panic_tmp_dir=""

        if [[ -x "${panic_source_builder}" ]]; then
            panic_tmp_dir="$(mktemp -d)"
            if "${panic_source_builder}" "${panic_tmp_dir}/source" >>"${panic_log}" 2>&1; then
                analysis_target="${panic_tmp_dir}/source"
                panic_scope="production_source"
            else
                rm -rf "${panic_tmp_dir}"
                panic_tmp_dir=""
                add_step "panic_assail" "fail" 0 "${panic_log}" '{"reason":"panic source builder failed"}'
                analysis_target=""
            fi
        fi

        if [[ -n "${analysis_target}" ]]; then
            if [[ -f "${panic_baseline_file}" ]]; then
                baseline_weak_points="$(jq -r '.metrics.weak_points // -1' "${panic_baseline_file}" 2>/dev/null || echo -1)"
            else
                panic_baseline_file=""
            fi

            start="$(date +%s)"
            if "$panic_attack_bin" assail "$analysis_target" --output "$panic_report" --output-format json --quiet >>"$panic_log" 2>&1; then
                weak_points="$(jq -r '.weak_points | length' "$panic_report" 2>/dev/null || echo 0)"
                end="$(date +%s)"
                duration="$((end - start))"
                panic_details="$(jq -nc \
                    --argjson weak_points "$weak_points" \
                    --arg report "$panic_report" \
                    --arg scope "$panic_scope" \
                    --arg target "$analysis_target" \
                    --arg baseline_file "$panic_baseline_file" \
                    --argjson baseline_weak_points "$baseline_weak_points" \
                    '{
                        weak_points: $weak_points,
                        report: $report,
                        scope: $scope,
                        target: $target,
                        baseline_file: $baseline_file,
                        baseline_weak_points: $baseline_weak_points
                    }')"
                if (( baseline_weak_points >= 0 )); then
                    if (( weak_points <= baseline_weak_points )); then
                        add_step "panic_assail" "pass" "$duration" "$panic_log" "$panic_details"
                    else
                        add_step "panic_assail" "warn" "$duration" "$panic_log" "$panic_details"
                    fi
                elif (( weak_points == 0 )); then
                    add_step "panic_assail" "pass" "$duration" "$panic_log" "$panic_details"
                else
                    add_step "panic_assail" "warn" "$duration" "$panic_log" "$panic_details"
                fi
            else
                end="$(date +%s)"
                duration="$((end - start))"
                add_step "panic_assail" "fail" "$duration" "$panic_log" '{"reason":"panic-assail command failed"}'
            fi
        fi

        if [[ -n "${panic_tmp_dir}" ]]; then
            rm -rf "${panic_tmp_dir}"
        fi
    else
        add_step "panic_assail" "skipped" 0 "${logs_dir}/panic_assail.log" '{"reason":"panic-attack not found"}'
    fi
fi

has_rust=false
has_python=false
has_elixir=false

[[ -f "$repo/Cargo.toml" ]] && has_rust=true
[[ -f "$repo/mix.exs" ]] && has_elixir=true
if [[ -f "$repo/pyproject.toml" || -f "$repo/requirements.txt" || -f "$repo/setup.py" ]]; then
    has_python=true
fi

if [[ "$explicit_lang_selection" == false ]]; then
    want_rust="$has_rust"
    want_python="$has_python"
    want_elixir="$has_elixir"
fi

if [[ "$want_rust" == true ]]; then
    if command -v cargo >/dev/null 2>&1; then
        run_step "rust_fmt_check" run_repo_cmd cargo fmt --all --check || true
        run_step "rust_clippy" run_repo_cmd cargo clippy --workspace --all-targets -- -D warnings || true
        run_step "rust_test" run_repo_cmd cargo test --workspace || true
        if [[ "$with_bench" == true ]]; then
            run_step "rust_bench" run_repo_cmd cargo bench || true
        else
            add_step "rust_bench" "skipped" 0 "${logs_dir}/rust_bench.log" '{"reason":"disabled by default; use --bench"}'
        fi
    else
        add_step "rust_checks" "skipped" 0 "${logs_dir}/rust_checks.log" '{"reason":"cargo not found"}'
    fi
else
    add_step "rust_checks" "skipped" 0 "${logs_dir}/rust_checks.log" '{"reason":"not selected"}'
fi

if [[ "$want_python" == true ]]; then
    if command -v python >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1; then
        if command -v ruff >/dev/null 2>&1; then
            run_step "python_ruff_check" run_repo_cmd ruff check . || true
            run_step "python_ruff_format_check" run_repo_cmd ruff format --check . || true
        else
            add_step "python_ruff" "skipped" 0 "${logs_dir}/python_ruff.log" '{"reason":"ruff not found"}'
        fi

        if command -v mypy >/dev/null 2>&1; then
            run_step "python_mypy" run_repo_cmd mypy . || true
        else
            add_step "python_mypy" "skipped" 0 "${logs_dir}/python_mypy.log" '{"reason":"mypy not found"}'
        fi

        if command -v pytest >/dev/null 2>&1; then
            run_step "python_pytest" run_repo_cmd pytest -q || true
        else
            add_step "python_pytest" "skipped" 0 "${logs_dir}/python_pytest.log" '{"reason":"pytest not found"}'
        fi
    else
        add_step "python_checks" "skipped" 0 "${logs_dir}/python_checks.log" '{"reason":"python not found"}'
    fi
else
    add_step "python_checks" "skipped" 0 "${logs_dir}/python_checks.log" '{"reason":"not selected"}'
fi

if [[ "$want_elixir" == true ]]; then
    if command -v mix >/dev/null 2>&1; then
        run_step "elixir_format_check" run_repo_cmd mix format --check-formatted || true
        run_step "elixir_test" run_repo_cmd mix test || true
        if run_repo_cmd mix help credo >/dev/null 2>&1; then
            run_step "elixir_credo" run_repo_cmd mix credo --strict || true
        else
            add_step "elixir_credo" "skipped" 0 "${logs_dir}/elixir_credo.log" '{"reason":"credo task not available"}'
        fi
    else
        add_step "elixir_checks" "skipped" 0 "${logs_dir}/elixir_checks.log" '{"reason":"mix not found"}'
    fi
else
    add_step "elixir_checks" "skipped" 0 "${logs_dir}/elixir_checks.log" '{"reason":"not selected"}'
fi

pass_count="$(jq -r '[.[] | select(.status == "pass")] | length' <<<"$steps")"
warn_count="$(jq -r '[.[] | select(.status == "warn")] | length' <<<"$steps")"
fail_count="$(jq -r '[.[] | select(.status == "fail")] | length' <<<"$steps")"
skip_count="$(jq -r '[.[] | select(.status == "skipped")] | length' <<<"$steps")"

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
mkdir -p "$(dirname "$output_path")"

jq -n \
    --arg generated_at "$generated_at" \
    --arg repo "$repo" \
    --arg git_branch "$git_branch" \
    --arg git_commit "$git_commit" \
    --arg logs_dir "$logs_dir" \
    --argjson pass_count "$pass_count" \
    --argjson warn_count "$warn_count" \
    --argjson fail_count "$fail_count" \
    --argjson skip_count "$skip_count" \
    --argjson steps "$steps" \
    '{
        generated_at: $generated_at,
        repo: $repo,
        git: {
            branch: $git_branch,
            commit: $git_commit
        },
        summary: {
            pass: $pass_count,
            warn: $warn_count,
            fail: $fail_count,
            skipped: $skip_count
        },
        logs_dir: $logs_dir,
        steps: $steps
    }' >"$output_path"

echo "maintenance report: $output_path"

if [[ "$strict" == true && "$fail_count" -gt 0 ]]; then
    exit 1
fi

if [[ "$fail_on_warn" == true && "$((fail_count + warn_count))" -gt 0 ]]; then
    exit 1
fi
