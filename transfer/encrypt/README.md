# transfer/encrypt/

LUKS2 encryption tooling for transfer drives.

## Purpose

Scripts and configuration for encrypting/decrypting the physical transfer media:

- Drive formatting with LUKS2 (Argon2id KDF)
- Key management (split-key between courier and recipient)
- Drive preparation (partition, format, mount)
- Secure erasure after ingestion

## Security Requirements

- LUKS2 with Argon2id (not PBKDF2)
- Minimum 256-bit AES-XTS
- Key material never stored on the drive itself
- Tamper-evident sealing procedures documented alongside
