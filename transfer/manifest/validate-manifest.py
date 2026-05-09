#!/usr/bin/env python3
"""
Validate transfer manifest structure and internal consistency.

This validator uses only Python standard library. It checks:
1. JSON schema conformance (manual, since jsonschema is not stdlib)
2. Checksum format validity
3. Package count consistency
4. Transfer size calculation accuracy
5. Semantic version validation

Exit codes:
  0 = valid
  1 = validation failed
  2 = file not found or JSON parse error
"""

import sys
import json
import re
from pathlib import Path


def validate_semver(version: str) -> bool:
    """Validate semantic version format."""
    pattern = r"^[0-9]+\.[0-9]+\.[0-9]+$"
    return bool(re.match(pattern, version))


def validate_transfer_id(transfer_id: str) -> bool:
    """Validate transfer ID format: transfer-YYYYMMDD-NNN."""
    pattern = r"^transfer-[0-9]{8}-[0-9]{3}$"
    return bool(re.match(pattern, transfer_id))


def validate_sha256(checksum: str) -> bool:
    """Validate SHA-256 checksum format: 64 lowercase hex chars."""
    pattern = r"^[a-f0-9]{64}$"
    return bool(re.match(pattern, checksum))


def validate_filename(filename: str) -> bool:
    """Validate filename is relative (no leading slash)."""
    return not filename.startswith("/")


def validate_manifest(manifest: dict) -> tuple[bool, list[str]]:
    """
    Validate manifest structure and consistency.

    Returns:
        (is_valid, error_messages)
    """
    errors = []

    # Required top-level fields
    required_fields = [
        "manifest_version", "transfer_id", "generated_at",
        "source_snapshot", "previous_snapshot", "component",
        "distribution", "architecture", "packages_added",
        "packages_removed", "packages_upgraded", "transfer_size_bytes",
        "package_count", "gpg_signature", "checksum_algorithm"
    ]

    for field in required_fields:
        if field not in manifest:
            errors.append(f"Missing required field: {field}")

    if errors:
        return False, errors

    # Validate manifest_version
    if not validate_semver(manifest["manifest_version"]):
        errors.append(f"Invalid manifest_version format: {manifest['manifest_version']}")

    # Validate transfer_id
    if not validate_transfer_id(manifest["transfer_id"]):
        errors.append(f"Invalid transfer_id format: {manifest['transfer_id']}")

    # Validate source_snapshot
    snapshot = manifest["source_snapshot"]
    if not isinstance(snapshot, dict):
        errors.append("source_snapshot must be an object")
    else:
        for field in ["name", "id", "created_at"]:
            if field not in snapshot:
                errors.append(f"source_snapshot missing field: {field}")

    # Validate previous_snapshot (null or object)
    prev = manifest["previous_snapshot"]
    if prev is not None:
        if not isinstance(prev, dict):
            errors.append("previous_snapshot must be null or an object")
        else:
            for field in ["name", "id", "created_at"]:
                if field not in prev:
                    errors.append(f"previous_snapshot missing field: {field}")

    # Validate component
    valid_components = ["main", "universe", "security"]
    if manifest["component"] not in valid_components:
        errors.append(f"Invalid component: {manifest['component']}")

    # Validate checksum_algorithm
    if manifest["checksum_algorithm"] != "sha256":
        errors.append(f"Unsupported checksum_algorithm: {manifest['checksum_algorithm']}")

    # Validate packages_added
    added = manifest["packages_added"]
    if not isinstance(added, list):
        errors.append("packages_added must be an array")
    else:
        for idx, pkg in enumerate(added):
            for field in ["name", "version", "arch", "filename", "size_bytes", "sha256", "section", "priority"]:
                if field not in pkg:
                    errors.append(f"packages_added[{idx}] missing field: {field}")
            if "sha256" in pkg and not validate_sha256(pkg["sha256"]):
                errors.append(f"packages_added[{idx}] invalid sha256: {pkg['sha256']}")
            if "filename" in pkg and not validate_filename(pkg["filename"]):
                errors.append(f"packages_added[{idx}] filename must be relative: {pkg['filename']}")

    # Validate packages_removed
    removed = manifest["packages_removed"]
    if not isinstance(removed, list):
        errors.append("packages_removed must be an array")
    else:
        for idx, pkg in enumerate(removed):
            for field in ["name", "version", "arch", "reason"]:
                if field not in pkg:
                    errors.append(f"packages_removed[{idx}] missing field: {field}")

    # Validate packages_upgraded
    upgraded = manifest["packages_upgraded"]
    if not isinstance(upgraded, list):
        errors.append("packages_upgraded must be an array")
    else:
        for idx, pkg in enumerate(upgraded):
            for field in ["name", "old_version", "new_version", "arch", "filename", "size_bytes", "sha256", "is_security_update"]:
                if field not in pkg:
                    errors.append(f"packages_upgraded[{idx}] missing field: {field}")
            if "sha256" in pkg and not validate_sha256(pkg["sha256"]):
                errors.append(f"packages_upgraded[{idx}] invalid sha256: {pkg['sha256']}")
            if "filename" in pkg and not validate_filename(pkg["filename"]):
                errors.append(f"packages_upgraded[{idx}] filename must be relative: {pkg['filename']}")

    # Validate package_count consistency
    pkg_count = manifest["package_count"]
    if not isinstance(pkg_count, dict):
        errors.append("package_count must be an object")
    else:
        if pkg_count.get("added") != len(added):
            errors.append(f"package_count.added ({pkg_count.get('added')}) does not match packages_added length ({len(added)})")
        if pkg_count.get("removed") != len(removed):
            errors.append(f"package_count.removed ({pkg_count.get('removed')}) does not match packages_removed length ({len(removed)})")
        if pkg_count.get("upgraded") != len(upgraded):
            errors.append(f"package_count.upgraded ({pkg_count.get('upgraded')}) does not match packages_upgraded length ({len(upgraded)})")

    # Validate transfer_size_bytes consistency
    calculated_size = sum(pkg.get("size_bytes", 0) for pkg in added)
    calculated_size += sum(pkg.get("size_bytes", 0) for pkg in upgraded)
    if manifest["transfer_size_bytes"] != calculated_size:
        errors.append(f"transfer_size_bytes ({manifest['transfer_size_bytes']}) does not match sum of package sizes ({calculated_size})")

    # Validate gpg_signature
    gpg = manifest["gpg_signature"]
    if not isinstance(gpg, dict):
        errors.append("gpg_signature must be an object")
    else:
        for field in ["signer_key_id", "signature_file", "algorithm"]:
            if field not in gpg:
                errors.append(f"gpg_signature missing field: {field}")

    return len(errors) == 0, errors


def main():
    if len(sys.argv) != 2:
        print("Usage: validate-manifest.py <manifest.json>", file=sys.stderr)
        sys.exit(2)

    manifest_path = Path(sys.argv[1])

    if not manifest_path.exists():
        print(f"Error: File not found: {manifest_path}", file=sys.stderr)
        sys.exit(2)

    try:
        with open(manifest_path, "r") as f:
            manifest = json.load(f)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON: {e}", file=sys.stderr)
        sys.exit(2)

    is_valid, errors = validate_manifest(manifest)

    if is_valid:
        print(f"✓ Manifest valid: {manifest_path}")
        sys.exit(0)
    else:
        print(f"✗ Manifest validation failed: {manifest_path}", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
