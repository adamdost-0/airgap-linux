#!/usr/bin/env bash
# Import packages from transfer bundle into Aptly repo
#
# Usage: import-packages.sh
#
# Required environment variables:
#   APTLY_CONFIG    - Path to aptly.conf
#   REPO_NAME       - Aptly repository name (e.g., highside-noble-main)
#   PACKAGE_DIR     - Directory containing .deb files to import
#   MANIFEST_FILE   - Path to verified transfer manifest
#
# Exit codes:
#   0 - Packages imported successfully
#   1 - Error occurred

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=highside/scripts/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

main() {
    require_env APTLY_CONFIG REPO_NAME PACKAGE_DIR MANIFEST_FILE
    validate_aptly_config
    
    log_info "Importing packages into repository: ${REPO_NAME}"
    
    if ! repo_exists "${REPO_NAME}"; then
        log_error "Repository does not exist: ${REPO_NAME}"
        log_error "Create repository first with: aptly repo create"
        return "${EXIT_ERROR}"
    fi
    
    if [[ ! -d "${PACKAGE_DIR}" ]]; then
        log_error "Package directory not found: ${PACKAGE_DIR}"
        return "${EXIT_ERROR}"
    fi
    
    if [[ ! -f "${MANIFEST_FILE}" ]]; then
        log_error "Manifest file not found: ${MANIFEST_FILE}"
        return "${EXIT_ERROR}"
    fi
    
    # TODO: Parse manifest and verify checksums before import
    # TODO: Import packages atomically (all or none)
    
    log_info "Adding packages to repository..."
    if aptly repo add -config="${APTLY_CONFIG}" "${REPO_NAME}" "${PACKAGE_DIR}"/*.deb; then
        log_info "Package import completed successfully"
        
        # Display repo info
        aptly repo show -config="${APTLY_CONFIG}" "${REPO_NAME}"
        
        return "${EXIT_SUCCESS}"
    else
        log_error "Package import failed"
        return "${EXIT_ERROR}"
    fi
}

main "$@"
