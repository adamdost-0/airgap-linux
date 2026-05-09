# transfer/encrypt/

LUKS2 encryption tooling for transfer drives.

## Purpose

Scripts and configuration for encrypting/decrypting the physical transfer media:

- Drive formatting with LUKS2 (Argon2id KDF)
- Key management (split-key between courier and recipient)
- Drive preparation (partition, format, mount)
- Secure erasure after ingestion

## Files

- `format-drive.sh` — Initialize LUKS2 encrypted drive (DESTRUCTIVE)
- `open-drive.sh` — Open and mount LUKS2 volume

## Security Requirements

- LUKS2 with Argon2id (not PBKDF2)
- Minimum 256-bit AES-XTS
- Key material never stored on the drive itself
- Tamper-evident sealing procedures documented alongside

## Usage

```bash
# Format new transfer drive (DESTROYS ALL DATA)
sudo ./format-drive.sh /dev/sdb /path/to/passphrase.txt

# Open and mount encrypted drive
sudo ./open-drive.sh /dev/sdb /path/to/passphrase.txt /mnt/airgap-transfer

# Exit codes:
#   0 = success
#   1 = error
#   2 = missing arguments or confirmation rejected
```

## Safety

- Explicit device argument required (no defaults)
- Refuses to format primary system disks (/dev/sda, /dev/nvme0n1)
- Requires exact device name confirmation before formatting
- Passphrase must be supplied via file (not command line)
