#!/usr/bin/env bash
# Common functions for high-side Aptly pipeline scripts

set -euo pipefail

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1
readonly EXIT_NOTHING_TO_DO=2

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

# Check if Aptly repo exists
# Args: repo_name
# Returns: 0 if exists, 1 otherwise
repo_exists() {
    local name="${1:?repo name required}"
    aptly repo show "${name}" &>/dev/null
}

# Verify GPG signature of a file
# Args: file_path signature_path
# Returns: 0 if valid, 1 otherwise
verify_gpg_signature() {
    local file="${1:?file path required}"
    local sig="${2:?signature path required}"
    
    if [[ ! -f "${file}" ]]; then
        log_error "File not found: ${file}"
        return 1
    fi
    
    if [[ ! -f "${sig}" ]]; then
        log_error "Signature file not found: ${sig}"
        return 1
    fi
    
    log_info "Verifying GPG signature for ${file}"
    if gpg --verify "${sig}" "${file}" 2>&1 | grep -q "Good signature"; then
        log_info "GPG signature verification succeeded"
        return 0
    else
        log_error "GPG signature verification failed"
        return 1
    fi
}

# Verify SHA-256 checksum
# Args: file_path expected_checksum
# Returns: 0 if matches, 1 otherwise
verify_sha256() {
    local file="${1:?file path required}"
    local expected="${2:?expected checksum required}"
    
    if [[ ! -f "${file}" ]]; then
        log_error "File not found: ${file}"
        return 1
    fi
    
    local actual
    actual=$(sha256sum "${file}" | awk '{print $1}')
    
    if [[ "${actual}" == "${expected}" ]]; then
        return 0
    else
        log_error "Checksum mismatch for ${file}"
        log_error "  Expected: ${expected}"
        log_error "  Actual:   ${actual}"
        return 1
    fi
}
