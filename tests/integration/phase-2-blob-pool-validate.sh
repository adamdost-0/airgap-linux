#!/usr/bin/env bash
# Validate a blobfuse2-mounted Aptly pool before Phase 2 Aptly operation tests.
#
# Required environment variables:
#   APTLY_CONFIG       - Path to aptly.conf
#   APTLY_POOL_MOUNT   - Expected blobfuse2 mount point (for example /mnt/aptly-pool)
#
# Optional environment variables:
#   RUN_APTLY_CHECKS   - Set to true to run read-only Aptly checks against APTLY_CONFIG
#
# Exit codes:
#   0 - Blob-backed Aptly pool is ready for integration tests
#   1 - Validation failed

set -euo pipefail

readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1

log_info() {
    echo "[INFO] $(date -u +"%Y-%m-%dT%H:%M:%SZ") $*" >&2
}

log_error() {
    echo "[ERROR] $(date -u +"%Y-%m-%dT%H:%M:%SZ") $*" >&2
}

require_env() {
    local missing=()
    for var in "$@"; do
        if [[ -z "${!var:-}" ]]; then
            missing+=("${var}")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required environment variables: ${missing[*]}"
        return "${EXIT_ERROR}"
    fi
}

read_aptly_root_dir() {
    python3 - "$APTLY_CONFIG" <<'PY'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
with config_path.open("r", encoding="utf-8") as handle:
    config = json.load(handle)

root_dir = config.get("rootDir")
if not isinstance(root_dir, str) or not root_dir:
    raise SystemExit("aptly.conf must contain a non-empty rootDir")

print(root_dir.rstrip("/"))
PY
}

main() {
    require_env APTLY_CONFIG APTLY_POOL_MOUNT

    if [[ ! -f "${APTLY_CONFIG}" ]]; then
        log_error "APTLY_CONFIG does not exist: ${APTLY_CONFIG}"
        return "${EXIT_ERROR}"
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        log_error "python3 is required to parse aptly.conf"
        return "${EXIT_ERROR}"
    fi

    local mount_path="${APTLY_POOL_MOUNT%/}"
    local root_dir
    root_dir="$(read_aptly_root_dir)"

    case "${root_dir}" in
        "${mount_path}" | "${mount_path}"/*) ;;
        *)
            log_error "Aptly rootDir (${root_dir}) must be on APTLY_POOL_MOUNT (${mount_path})"
            return "${EXIT_ERROR}"
            ;;
    esac

    if ! mountpoint -q "${mount_path}"; then
        log_error "APTLY_POOL_MOUNT is not an active mount point: ${mount_path}"
        return "${EXIT_ERROR}"
    fi

    local probe_dir="${root_dir}/.phase2-probe"
    local probe_file="${probe_dir}/write-check.txt"
    mkdir -p "${probe_dir}"
    trap 'rm -f "${probe_file}"; rmdir "${probe_dir}" 2>/dev/null || true' EXIT

    log_info "Checking read/write/delete access under ${root_dir}"
    printf 'phase2-blob-pool-check\n' > "${probe_file}"
    if [[ "$(cat "${probe_file}")" != "phase2-blob-pool-check" ]]; then
        log_error "Read-after-write check failed: ${probe_file}"
        return "${EXIT_ERROR}"
    fi
    rm -f "${probe_file}"

    if [[ "${RUN_APTLY_CHECKS:-false}" == "true" ]]; then
        if ! command -v aptly >/dev/null 2>&1; then
            log_error "RUN_APTLY_CHECKS=true but aptly is not installed"
            return "${EXIT_ERROR}"
        fi

        log_info "Running read-only Aptly checks with explicit config"
        aptly -config="${APTLY_CONFIG}" repo list >/dev/null
        aptly -config="${APTLY_CONFIG}" snapshot list >/dev/null
    fi

    log_info "Blob-backed Aptly pool validation passed"
    return "${EXIT_SUCCESS}"
}

main "$@"
