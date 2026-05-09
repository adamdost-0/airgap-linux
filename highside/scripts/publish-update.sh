#!/usr/bin/env bash
# Update published repository endpoint
#
# Usage: publish-update.sh
#
# Required environment variables:
#   APTLY_CONFIG    - Path to aptly.conf
#   REPO_NAME       - Aptly repository name
#   DISTRIBUTION    - Distribution name (e.g., noble)
#
# Exit codes:
#   0 - Publish updated successfully
#   1 - Error occurred

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=highside/scripts/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

main() {
    require_env APTLY_CONFIG REPO_NAME DISTRIBUTION
    validate_aptly_config
    
    log_info "Updating published repository: ${DISTRIBUTION}"
    
    if ! repo_exists "${REPO_NAME}"; then
        log_error "Repository does not exist: ${REPO_NAME}"
        return "${EXIT_ERROR}"
    fi
    
    log_info "Running aptly publish update..."
    if aptly publish update -config="${APTLY_CONFIG}" "${DISTRIBUTION}"; then
        log_info "Publish update completed successfully"
        
        # Display publish info
        aptly publish show -config="${APTLY_CONFIG}" "${DISTRIBUTION}"
        
        return "${EXIT_SUCCESS}"
    else
        log_error "Publish update failed"
        return "${EXIT_ERROR}"
    fi
}

main "$@"
