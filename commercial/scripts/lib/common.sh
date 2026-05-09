#!/usr/bin/env bash
# Common functions for commercial-side Aptly pipeline scripts

set -euo pipefail

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1
readonly EXIT_NOTHING_TO_DO=2

# Snapshot naming pattern: ubuntu-noble-{component}-YYYYMMDD
readonly SNAPSHOT_DATE_FORMAT="%Y%m%d"
readonly SNAPSHOT_NAME_PATTERN="ubuntu-noble-%s-%s"

# Logging functions
log_info() {
    echo "[INFO] $(date -u +"%Y-%m-%dT%H:%M:%SZ") $*" >&2
}

log_error() {
    echo "[ERROR] $(date -u +"%Y-%m-%dT%H:%M:%SZ") $*" >&2
}

log_warn() {
    echo "[WARN] $(date -u +"%Y-%m-%dT%H:%M:%SZ") $*" >&2
}

# Generate snapshot name for a component and date
# Args: component (main|security|universe), date (YYYYMMDD)
snapshot_name() {
    local component="${1:?component required}"
    local date="${2:?date required}"
    printf "${SNAPSHOT_NAME_PATTERN}" "${component}" "${date}"
}

# Get current date in snapshot format
snapshot_date() {
    date -u +"${SNAPSHOT_DATE_FORMAT}"
}

# Check if Aptly snapshot exists
# Args: snapshot_name
# Returns: 0 if exists, 1 otherwise
snapshot_exists() {
    local name="${1:?snapshot name required}"
    aptly snapshot show "${name}" &>/dev/null
}

# Check if Aptly mirror exists
# Args: mirror_name
# Returns: 0 if exists, 1 otherwise
mirror_exists() {
    local name="${1:?mirror name required}"
    aptly mirror show "${name}" &>/dev/null
}

# Validate required environment variables
# Args: var_name...
require_env() {
    local missing=()
    for var in "$@"; do
        if [[ -z "${!var:-}" ]]; then
            missing+=("${var}")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required environment variables: ${missing[*]}"
        return 1
    fi
}

# Ensure Aptly config exists and is valid
validate_aptly_config() {
    if [[ ! -f "${APTLY_CONFIG:-}" ]]; then
        log_error "APTLY_CONFIG not set or file does not exist"
        return 1
    fi
}
