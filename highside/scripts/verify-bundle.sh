#!/usr/bin/env bash
#
# High-side bundle verification wrapper.
#
# Usage: verify-bundle.sh <bundle_root> <gpg_keyring> [--expected-previous-snapshot <snapshot_name>]
#
# This script wraps the shared verification logic from transfer/verify/verify-bundle.sh
# and forwards all arguments including continuity state.
#
# Exit codes:
#   0 = verification passed
#   1 = verification failed
#   2 = missing arguments

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TRANSFER_VERIFIER="${SCRIPT_DIR}/../../transfer/verify/verify-bundle.sh"

usage() {
    echo "Usage: $0 <bundle_root> <gpg_keyring> [--expected-previous-snapshot <snapshot_name>]" >&2
    exit 2
}

log_info() {
    echo "[INFO] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

main() {
    if [[ $# -lt 2 ]]; then
        usage
    fi

    if [[ ! -x "${TRANSFER_VERIFIER}" ]]; then
        log_error "Transfer verifier not found or not executable: ${TRANSFER_VERIFIER}"
        exit 2
    fi

    log_info "Delegating to transfer verifier..."

    # Forward all arguments to shared verification logic
    exec "${TRANSFER_VERIFIER}" "$@"
}

main "$@"
