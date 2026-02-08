#!/bin/bash
# Golden Image Build Script
# Automated build process for golden images

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="${SCRIPT_DIR}/.."

# Configuration
readonly ENVIRONMENT="${1:-dev}"
readonly VERSION="${2:-dev-$(date +%Y%m%d-%H%M%S)}"
readonly PACKER_DIR="${PROJECT_ROOT}/image-build/packer"
readonly LOG_FILE="${PROJECT_ROOT}/logs/build-${ENVIRONMENT}-$(date +%Y%m%d-%H%M%S).log"

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

log "╔════════════════════════════════════════════╗"
log "║    Golden Image Build Process Started      ║"
log "╚════════════════════════════════════════════╝"
log "Environment: ${ENVIRONMENT}"
log "Version: ${VERSION}"

# Validation
log "Running pre-build validation..."
if ! bash "${SCRIPT_DIR}/validate.sh" >> "${LOG_FILE}" 2>&1; then
    error "Pre-build validation failed"
fi
success "Pre-build validation passed"

# Build
log "Starting image build in Packer..."
cd "${PACKER_DIR}"

log "Initializing Packer..."
if ! packer init . >> "${LOG_FILE}" 2>&1; then
    error "Packer initialization failed"
fi

log "Building golden image..."
if packer build \
    -var-file=variables.pkrvars.hcl \
    -var="environment=${ENVIRONMENT}" \
    -var="version=${VERSION}" \
    ubuntu.pkr.hcl >> "${LOG_FILE}" 2>&1; then
    success "Golden image build completed"
else
    error "Golden image build failed"
fi

cd "${PROJECT_ROOT}"

log "╔════════════════════════════════════════════╗"
log "║    Golden Image Build Process Completed    ║"
log "╚════════════════════════════════════════════╝"
log "Image Version: ${VERSION}"
log "Build Log: ${LOG_FILE}"
