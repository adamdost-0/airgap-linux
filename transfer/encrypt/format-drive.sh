#!/usr/bin/env bash
#
# Format drive with LUKS2 encryption for secure transfer.
#
# Usage: format-drive.sh <device> <passphrase_file>
#
# WARNING: This will DESTROY all data on the device. Requires explicit confirmation.
#
# Security:
#   - LUKS2 with Argon2id KDF
#   - 256-bit AES-XTS cipher
#   - Key material never stored on the drive
#   - Passphrase must be supplied via file (not command line)
#
# Exit codes:
#   0 = success
#   1 = error
#   2 = missing arguments or confirmation rejected

set -euo pipefail

readonly CIPHER="aes-xts-plain64"
readonly KEY_SIZE="512"  # 512 bits = 256-bit AES-XTS (2x256 for XTS)
readonly HASH="sha256"
readonly PBKDF="argon2id"
readonly ITER_TIME="5000"  # 5 seconds

usage() {
    echo "Usage: $0 <device> <passphrase_file>" >&2
    echo "" >&2
    echo "Arguments:" >&2
    echo "  device          - Block device (e.g., /dev/sdb)" >&2
    echo "  passphrase_file - File containing LUKS passphrase" >&2
    echo "" >&2
    echo "WARNING: This will DESTROY all data on the device!" >&2
    exit 2
}

log_info() {
    echo "[INFO] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

confirm_destructive_operation() {
    local device="$1"

    echo "" >&2
    echo "╔════════════════════════════════════════════════════════════╗" >&2
    echo "║              DESTRUCTIVE OPERATION WARNING                 ║" >&2
    echo "╠════════════════════════════════════════════════════════════╣" >&2
    echo "║  This will PERMANENTLY ERASE all data on:                 ║" >&2
    echo "║  ${device}                                                  ║" >&2
    echo "║                                                            ║" >&2
    echo "║  Type the device name exactly to confirm:                 ║" >&2
    echo "╚════════════════════════════════════════════════════════════╝" >&2
    echo "" >&2

    read -r confirmation

    if [[ "${confirmation}" != "${device}" ]]; then
        log_error "Confirmation rejected. Aborting."
        exit 2
    fi

    log_info "Confirmation accepted"
}

validate_device() {
    local device="$1"

    if [[ ! -b "${device}" ]]; then
        log_error "Not a block device: ${device}"
        exit 2
    fi

    if [[ "${device}" == "/dev/sda" ]] || [[ "${device}" == "/dev/nvme0n1" ]]; then
        log_error "Refusing to format primary system disk: ${device}"
        exit 2
    fi

    log_info "Device validated: ${device}"
}

format_luks2() {
    local device="$1"
    local passphrase_file="$2"

    log_info "Formatting ${device} with LUKS2..."

    if ! cryptsetup luksFormat \
        --type luks2 \
        --cipher "${CIPHER}" \
        --key-size "${KEY_SIZE}" \
        --hash "${HASH}" \
        --pbkdf "${PBKDF}" \
        --iter-time "${ITER_TIME}" \
        --use-random \
        --key-file "${passphrase_file}" \
        "${device}"; then
        log_error "LUKS2 format failed"
        return 1
    fi

    log_info "✓ LUKS2 format complete"
    return 0
}

create_filesystem() {
    local device="$1"
    local passphrase_file="$2"
    local mapper_name="airgap_transfer"

    log_info "Opening LUKS volume..."

    if ! cryptsetup open --type luks2 --key-file "${passphrase_file}" "${device}" "${mapper_name}"; then
        log_error "Failed to open LUKS volume"
        return 1
    fi

    log_info "Creating ext4 filesystem..."

    if ! mkfs.ext4 -L "airgap-transfer" "/dev/mapper/${mapper_name}"; then
        cryptsetup close "${mapper_name}"
        log_error "Failed to create filesystem"
        return 1
    fi

    cryptsetup close "${mapper_name}"
    log_info "✓ Filesystem created"
    return 0
}

main() {
    if [[ $# -ne 2 ]]; then
        usage
    fi

    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 2
    fi

    local device="$1"
    local passphrase_file="$2"

    if [[ ! -f "${passphrase_file}" ]]; then
        log_error "Passphrase file not found: ${passphrase_file}"
        exit 2
    fi

    validate_device "${device}"
    confirm_destructive_operation "${device}"

    format_luks2 "${device}" "${passphrase_file}" || exit 1
    create_filesystem "${device}" "${passphrase_file}" || exit 1

    log_info "✓ Drive preparation complete: ${device}"
    log_info "Drive is ready for transfer bundle"
    exit 0
}

main "$@"
