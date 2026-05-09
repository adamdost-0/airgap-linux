#!/usr/bin/env bash
# Update Aptly mirrors from upstream Ubuntu archives
#
# Usage: mirror-update.sh
#
# Required environment variables:
#   APTLY_CONFIG    - Path to aptly.conf
#   MIRROR_NAME     - Name of the Aptly mirror to update (e.g., ubuntu-noble-main)
#
# Exit codes:
#   0 - Mirror updated successfully
#   1 - Error occurred
#   2 - Mirror unchanged (idempotent, nothing to do)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=commercial/scripts/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

main() {
    require_env APTLY_CONFIG MIRROR_NAME
    validate_aptly_config
    
    log_info "Updating Aptly mirror: ${MIRROR_NAME}"
    
    if ! mirror_exists "${MIRROR_NAME}"; then
        log_error "Mirror does not exist: ${MIRROR_NAME}"
        log_error "Create mirror first with: aptly mirror create"
        return "${EXIT_ERROR}"
    fi
    
    log_info "Running aptly mirror update..."
    local update_output
    if update_output=$(aptly mirror update -config="${APTLY_CONFIG}" "${MIRROR_NAME}" 2>&1); then
        if echo "${update_output}" | grep -q "Mirror is up to date"; then
            log_info "Mirror is already up to date"
            return "${EXIT_NOTHING_TO_DO}"
        else
            log_info "Mirror update completed successfully"
            return "${EXIT_SUCCESS}"
        fi
    else
        log_error "Mirror update failed"
        log_error "${update_output}"
        return "${EXIT_ERROR}"
    fi
}

main "$@"
