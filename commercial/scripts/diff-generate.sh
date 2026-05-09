#!/usr/bin/env bash
# Generate diff between two Aptly snapshots
#
# Usage: diff-generate.sh
#
# Required environment variables:
#   APTLY_CONFIG        - Path to aptly.conf
#   PREVIOUS_SNAPSHOT   - Name of previous snapshot (baseline)
#   CURRENT_SNAPSHOT    - Name of current snapshot (target)
#   OUTPUT_FILE         - Path to write diff output (JSON format)
#
# Exit codes:
#   0 - Diff generated successfully
#   1 - Error occurred
#   2 - Snapshots are identical (no diff)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=commercial/scripts/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

main() {
    require_env APTLY_CONFIG PREVIOUS_SNAPSHOT CURRENT_SNAPSHOT OUTPUT_FILE
    validate_aptly_config
    
    log_info "Generating diff: ${PREVIOUS_SNAPSHOT} -> ${CURRENT_SNAPSHOT}"
    
    if ! snapshot_exists "${PREVIOUS_SNAPSHOT}"; then
        log_error "Previous snapshot does not exist: ${PREVIOUS_SNAPSHOT}"
        return "${EXIT_ERROR}"
    fi
    
    if ! snapshot_exists "${CURRENT_SNAPSHOT}"; then
        log_error "Current snapshot does not exist: ${CURRENT_SNAPSHOT}"
        return "${EXIT_ERROR}"
    fi
    
    log_info "Running aptly snapshot diff..."
    local diff_output
    if diff_output=$(aptly snapshot diff -config="${APTLY_CONFIG}" "${PREVIOUS_SNAPSHOT}" "${CURRENT_SNAPSHOT}" 2>&1); then
        if echo "${diff_output}" | grep -q "Snapshots are identical"; then
            log_info "Snapshots are identical, no changes to transfer"
            return "${EXIT_NOTHING_TO_DO}"
        fi
        
        # Write diff output to file
        echo "${diff_output}" > "${OUTPUT_FILE}"
        log_info "Diff written to: ${OUTPUT_FILE}"
        
        # Parse and summarize
        local added removed upgraded
        added=$(echo "${diff_output}" | grep -c "^  +.*" || true)
        removed=$(echo "${diff_output}" | grep -c "^  -.*" || true)
        upgraded=$(echo "${diff_output}" | grep -c "^  \*.*" || true)
        
        log_info "Summary: ${added} added, ${removed} removed, ${upgraded} upgraded"
        
        return "${EXIT_SUCCESS}"
    else
        log_error "Diff generation failed"
        log_error "${diff_output}"
        return "${EXIT_ERROR}"
    fi
}

main "$@"
