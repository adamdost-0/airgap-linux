#!/usr/bin/env bash
# Create Aptly snapshot from mirror
#
# Usage: snapshot-create.sh
#
# Required environment variables:
#   APTLY_CONFIG    - Path to aptly.conf
#   MIRROR_NAME     - Source mirror name (e.g., ubuntu-noble-main)
#   COMPONENT       - Component name (main|security|universe)
#   SNAPSHOT_DATE   - Date in YYYYMMDD format (defaults to today)
#
# Exit codes:
#   0 - Snapshot created successfully
#   1 - Error occurred
#   2 - Snapshot already exists (idempotent)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=commercial/scripts/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

main() {
    require_env APTLY_CONFIG MIRROR_NAME COMPONENT
    validate_aptly_config
    
    local snapshot_date="${SNAPSHOT_DATE:-$(snapshot_date)}"
    local snapshot_name
    snapshot_name=$(snapshot_name "${COMPONENT}" "${snapshot_date}")
    
    log_info "Creating snapshot: ${snapshot_name} from mirror: ${MIRROR_NAME}"
    
    if ! mirror_exists "${MIRROR_NAME}"; then
        log_error "Source mirror does not exist: ${MIRROR_NAME}"
        return "${EXIT_ERROR}"
    fi
    
    if snapshot_exists "${snapshot_name}"; then
        log_warn "Snapshot already exists: ${snapshot_name}"
        return "${EXIT_NOTHING_TO_DO}"
    fi
    
    log_info "Running aptly snapshot create..."
    if aptly snapshot create -config="${APTLY_CONFIG}" "${snapshot_name}" from mirror "${MIRROR_NAME}"; then
        log_info "Snapshot created successfully: ${snapshot_name}"
        
        # Display snapshot info
        aptly snapshot show -config="${APTLY_CONFIG}" "${snapshot_name}"
        
        return "${EXIT_SUCCESS}"
    else
        log_error "Snapshot creation failed"
        return "${EXIT_ERROR}"
    fi
}

main "$@"
