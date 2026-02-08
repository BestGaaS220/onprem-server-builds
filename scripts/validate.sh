#!/bin/bash
# Golden Image Validation Script
# Validates Packer, Terraform, and Ansible configurations

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="${SCRIPT_DIR}/.."
readonly LOG_FILE="${PROJECT_ROOT}/logs/validation-$(date +%Y%m%d-%H%M%S).log"

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

log "Starting validation..."

# Check prerequisites
log "Checking prerequisites..."
command -v packer &> /dev/null || error "Packer not installed"
command -v terraform &> /dev/null || error "Terraform not installed"
command -v ansible &> /dev/null || error "Ansible not installed"
command -v ansible-playbook &> /dev/null || error "ansible-playbook not installed"
log "✓ All prerequisites installed"

# Validate Packer
log "Validating Packer configurations..."
cd "${PROJECT_ROOT}/image-build/packer"
if packer validate -var-file=variables.pkrvars.hcl ubuntu.pkr.hcl >> "${LOG_FILE}" 2>&1; then
    success "Packer validation passed"
else
    error "Packer validation failed"
fi
cd "${PROJECT_ROOT}"

# Validate Terraform
log "Validating Terraform configurations..."
cd "${PROJECT_ROOT}/infrastructure/terraform"
if terraform init -upgrade -backend=false >> "${LOG_FILE}" 2>&1; then
    if terraform validate >> "${LOG_FILE}" 2>&1; then
        success "Terraform initialization and validation passed"
    else
        error "Terraform validation failed"
    fi
else
    error "Terraform initialization failed"
fi

# Check formatting
log "Checking Terraform formatting..."
if terraform fmt -check -recursive >> "${LOG_FILE}" 2>&1; then
    success "Terraform formatting is correct"
else
    log "Terraform files need formatting. Running: terraform fmt -recursive"
    terraform fmt -recursive
fi
cd "${PROJECT_ROOT}"

# Validate Ansible
log "Validating Ansible playbooks..."
cd "${PROJECT_ROOT}/infrastructure/ansible"
if ansible-playbook --syntax-check playbooks/main.yml >> "${LOG_FILE}" 2>&1; then
    success "Ansible playbook syntax validation passed"
else
    error "Ansible playbook validation failed"
fi
cd "${PROJECT_ROOT}"

# Validate YAML files
log "Validating YAML syntax..."
if command -v yamllint &> /dev/null; then
    if yamllint -c "${PROJECT_ROOT}/.yamllint" infrastructure/ansible/ >> "${LOG_FILE}" 2>&1; then
        success "YAML validation passed"
    else
        log "⚠ YAML linting warnings found (non-blocking)"
    fi
else
    log "yamllint not installed, skipping YAML validation"
fi

# Validate shell scripts
log "Validating shell scripts..."
if command -v shellcheck &> /dev/null; then
    if find "${PROJECT_ROOT}/scripts" -name "*.sh" -exec shellcheck {} \; >> "${LOG_FILE}" 2>&1; then
        success "Shell script validation passed"
    else
        log "⚠ Shell script issues found (check logs)"
    fi
else
    log "shellcheck not installed, skipping shell script validation"
fi

# Check for required variables
log "Checking required configuration files..."
[[ -f "${PROJECT_ROOT}/vars/dev.tfvars" ]] || error "Missing vars/dev.tfvars"
[[ -f "${PROJECT_ROOT}/image-build/packer/variables.pkrvars.hcl" ]] || error "Missing packer variables file"
success "Required configuration files found"

log "╔════════════════════════════════════════════╗"
log "║   All validations passed successfully!     ║"
log "╚════════════════════════════════════════════╝"
log "Validation log: ${LOG_FILE}"
