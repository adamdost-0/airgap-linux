#!/usr/bin/env bash
#
# Open LUKS2 encrypted drive for reading/writing.
#
# Usage: open-drive.sh <device> <passphrase_file> <mount_point>
#
# Opens the LUKS2 volume and mounts it at the specified mount point.
#
# Exit codes:
#   0 = success
#   1 = error
#   2 = missing arguments or file not found

set -euo pipefail

readonly MAPPER_NAME="airgap_transfer"

usage() {
    echo "Usage: $0 <device> <passphrase_file> <mount_point>" >&2
    echo "" >&2
    echo "Arguments:" >&2
    echo "  device          - Block device (e.g., /dev/sdb)" >&2
    echo "  passphrase_file - File containing LUKS passphrase" >&2
    echo "  mount_point     - Directory to mount the filesystem" >&2
    exit 2
}

log_info() {
    echo "[INFO] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

validate_device() {
    local device="$1"

    if [[ ! -b "${device}" ]]; then
        log_error "Not a block device: ${device}"
        exit 2
    fi

    log_info "Device validated: ${device}"
}

open_luks_volume() {
    local device="$1"
    local passphrase_file="$2"

    log_info "Opening LUKS2 volume..."

    if cryptsetup status "${MAPPER_NAME}" &>/dev/null; then
        log_info "Volume already open: ${MAPPER_NAME}"
        return 0
    fi

    if ! cryptsetup open --type luks2 --key-file "${passphrase_file}" "${device}" "${MAPPER_NAME}"; then
        log_error "Failed to open LUKS volume"
        return 1
    fi

    log_info "✓ LUKS volume opened: /dev/mapper/${MAPPER_NAME}"
    return 0
}

mount_filesystem() {
    local mount_point="$1"

    log_info "Mounting filesystem..."

    if ! mkdir -p "${mount_point}"; then
        log_error "Failed to create mount point: ${mount_point}"
        return 1
    fi

    if mountpoint -q "${mount_point}"; then
        log_info "Already mounted: ${mount_point}"
        return 0
    fi

    if ! mount "/dev/mapper/${MAPPER_NAME}" "${mount_point}"; then
        log_error "Failed to mount filesystem"
        return 1
    fi

    log_info "✓ Filesystem mounted: ${mount_point}"
    return 0
}

main() {
    if [[ $# -ne 3 ]]; then
        usage
    fi

    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 2
    fi

    local device="$1"
    local passphrase_file="$2"
    local mount_point="$3"

    if [[ ! -f "${passphrase_file}" ]]; then
        log_error "Passphrase file not found: ${passphrase_file}"
        exit 2
    fi

    validate_device "${device}"
    open_luks_volume "${device}" "${passphrase_file}" || exit 1
    mount_filesystem "${mount_point}" || exit 1

    log_info "✓ Drive ready at: ${mount_point}"
    exit 0
}

main "$@"
