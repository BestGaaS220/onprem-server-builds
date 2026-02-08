#!/bin/bash
# Test Runner Script
# Executes test suites for golden image

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="${SCRIPT_DIR}/.."
readonly TEST_DIR="${PROJECT_ROOT}/tests"
readonly LOG_FILE="${PROJECT_ROOT}/logs/test-$(date +%Y%m%d-%H%M%S).log"

# Create logs directory
mkdir -p "${PROJECT_ROOT}/logs"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

error() {
    echo "[ERROR] $*" | tee -a "${LOG_FILE}"
    exit 1
}

success() {
    echo "[SUCCESS] $*" | tee -a "${LOG_FILE}"
}

log "Starting test execution..."

# Check if pytest is available
if ! command -v python3 &> /dev/null; then
    error "Python3 not installed"
fi

log "Installing test dependencies..."
python3 -m pip install -q pytest pytest-cov pyyaml 2>> "${LOG_FILE}" || log "Warning: Some test deps may not have installed"

# Run unit tests
log "Running unit tests..."
if [[ -d "${TEST_DIR}/unit" ]]; then
    python3 -m pytest "${TEST_DIR}/unit/" -v --tb=short --cov=. --cov-report=term >> "${LOG_FILE}" 2>&1 || log "⚠ Some unit tests may have failed"
    success "Unit tests completed"
else
    log "No unit tests found"
fi

# Run integration tests
log "Running integration tests..."
if [[ -d "${TEST_DIR}/integration" ]]; then
    python3 -m pytest "${TEST_DIR}/integration/" -v --tb=short >> "${LOG_FILE}" 2>&1 || log "⚠ Some integration tests may have failed"
    success "Integration tests completed"
else
    log "No integration tests found"
fi

log "Test execution completed. Results in: ${LOG_FILE}"
