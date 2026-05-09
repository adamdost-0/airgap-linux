#!/usr/bin/env bash
# Smoke test for high-side Aptly repository endpoint
#
# Usage: smoke-test.sh
#
# Required environment variables:
#   APT_REPO_URL    - APT repository URL (e.g., http://localhost:8080)
#   DISTRIBUTION    - Distribution name (e.g., noble)
#   COMPONENT       - Component name (e.g., main)
#
# Exit codes:
#   0 - All smoke tests passed
#   1 - One or more tests failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=highside/scripts/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

main() {
    require_env APT_REPO_URL DISTRIBUTION COMPONENT
    
    log_info "Running smoke tests for APT repository"
    log_info "  URL: ${APT_REPO_URL}"
    log_info "  Distribution: ${DISTRIBUTION}"
    log_info "  Component: ${COMPONENT}"
    
    local failed=0
    
    # Test 1: Check Release file availability
    log_info "Test 1: Checking Release file..."
    if curl -fsS "${APT_REPO_URL}/dists/${DISTRIBUTION}/Release" > /dev/null; then
        log_info "✓ Release file accessible"
    else
        log_error "✗ Release file not accessible"
        ((failed++))
    fi
    
    # Test 2: Check InRelease file
    log_info "Test 2: Checking InRelease file..."
    if curl -fsS "${APT_REPO_URL}/dists/${DISTRIBUTION}/InRelease" > /dev/null; then
        log_info "✓ InRelease file accessible"
    else
        log_error "✗ InRelease file not accessible"
        ((failed++))
    fi
    
    # Test 3: Check Packages.gz for component
    log_info "Test 3: Checking Packages.gz..."
    if curl -fsS "${APT_REPO_URL}/dists/${DISTRIBUTION}/${COMPONENT}/binary-amd64/Packages.gz" > /dev/null; then
        log_info "✓ Packages.gz accessible"
    else
        log_error "✗ Packages.gz not accessible"
        ((failed++))
    fi
    
    # Test 4: Validate Packages.gz is valid gzip
    log_info "Test 4: Validating Packages.gz format..."
    if curl -fsS "${APT_REPO_URL}/dists/${DISTRIBUTION}/${COMPONENT}/binary-amd64/Packages.gz" | gunzip > /dev/null 2>&1; then
        log_info "✓ Packages.gz is valid gzip"
    else
        log_error "✗ Packages.gz is not valid gzip"
        ((failed++))
    fi
    
    # Test 5: Check if Packages.gz contains package entries
    log_info "Test 5: Checking for package entries..."
    local package_count
    package_count=$(curl -fsS "${APT_REPO_URL}/dists/${DISTRIBUTION}/${COMPONENT}/binary-amd64/Packages.gz" | gunzip | grep -c "^Package:" || true)
    if [[ ${package_count} -gt 0 ]]; then
        log_info "✓ Found ${package_count} packages"
    else
        log_error "✗ No packages found"
        ((failed++))
    fi
    
    # Summary
    if [[ ${failed} -eq 0 ]]; then
        log_info "All smoke tests passed"
        return "${EXIT_SUCCESS}"
    else
        log_error "${failed} smoke test(s) failed"
        return "${EXIT_ERROR}"
    fi
}

main "$@"
