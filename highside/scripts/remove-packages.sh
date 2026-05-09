#!/usr/bin/env bash
# Remove packages from Aptly repo based on transfer manifest
#
# Usage: remove-packages.sh
#
# Required environment variables:
#   APTLY_CONFIG    - Path to aptly.conf
#   REPO_NAME       - Aptly repository name
#   MANIFEST_FILE   - Path to verified transfer manifest
#
# Exit codes:
#   0 - Packages removed successfully
#   1 - Error occurred
#   2 - No packages to remove

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=highside/scripts/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

main() {
    require_env APTLY_CONFIG REPO_NAME MANIFEST_FILE
    validate_aptly_config
    
    log_info "Processing package removals for repository: ${REPO_NAME}"
    
    if ! repo_exists "${REPO_NAME}"; then
        log_error "Repository does not exist: ${REPO_NAME}"
        return "${EXIT_ERROR}"
    fi
    
    if [[ ! -f "${MANIFEST_FILE}" ]]; then
        log_error "Manifest file not found: ${MANIFEST_FILE}"
        return "${EXIT_ERROR}"
    fi
    
    # TODO: Parse manifest.packages_removed array
    # TODO: Remove each package with: aptly repo remove ${REPO_NAME} 'Name (= package-name), Version (= version)'
    
    log_warn "TODO: Implement package removal from manifest"
    
    return "${EXIT_NOTHING_TO_DO}"
}

main "$@"
