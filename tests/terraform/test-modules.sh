#!/bin/bash
# Terraform module validation tests
# Tests all Terraform modules and configurations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/infrastructure/terraform"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Test counters
PASS=0
FAIL=0
TOTAL=0

# Logging
log_test() {
  echo -e "${YELLOW}[TEST]${NC} $*"
}

log_success() {
  echo -e "${GREEN}[PASS]${NC} $*"
  ((PASS++))
}

log_error() {
  echo -e "${RED}[FAIL]${NC} $*"
  ((FAIL++))
}

# Test 1: Validate main Terraform configuration
test_terraform_validate_main() {
  local test_name="Terraform validate main configuration"
  ((TOTAL++))
  
  log_test "$test_name"
  
  if cd "$TERRAFORM_DIR" && terraform validate; then
    log_success "$test_name"
  else
    log_error "$test_name"
  fi
}

# Test 2: Validate all Terraform modules
test_terraform_validate_modules() {
  local test_name="Terraform validate all modules"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local modules=("network" "security" "compute" "storage")
  local module_valid=true
  
  for module in "${modules[@]}"; do
    if ! terraform validate "$TERRAFORM_DIR/modules/$module"; then
      log_error "Module validation failed: $module"
      module_valid=false
    fi
  done
  
  if [[ $module_valid == true ]]; then
    log_success "$test_name"
  else
    log_error "$test_name"
  fi
}

# Test 3: Check Terraform formatting
test_terraform_format() {
  local test_name="Terraform code formatting check"
  ((TOTAL++))
  
  log_test "$test_name"
  
  cd "$TERRAFORM_DIR"
  if terraform fmt -recursive -check .; then
    log_success "$test_name"
  else
    log_error "$test_name - Run 'terraform fmt -recursive' to fix formatting"
  fi
}

# Test 4: Verify Terraform provider requirements
test_terraform_providers() {
  local test_name="Terraform provider requirements check"
  ((TOTAL++))
  
  log_test "$test_name"
  
  if cd "$TERRAFORM_DIR" && terraform providers; then
    log_success "$test_name"
  else
    log_error "$test_name"
  fi
}

# Test 5: Check for required tfvars files
test_terraform_variables() {
  local test_name="Terraform variables files existence"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local vars_valid=true
  local environments=("dev" "staging" "prod")
  
  for env in "${environments[@]}"; do
    if [[ ! -f "$TERRAFORM_DIR/../vars/${env}.tfvars" ]]; then
      log_error "Missing tfvars file: $env.tfvars"
      vars_valid=false
    fi
  done
  
  if [[ $vars_valid == true ]]; then
    log_success "$test_name"
  else
    log_error "$test_name"
  fi
}

# Test 6: Validate Terraform outputs
test_terraform_outputs() {
  local test_name="Terraform outputs definition check"
  ((TOTAL++))
  
  log_test "$test_name"
  
  if grep -q "output" "$TERRAFORM_DIR/outputs.tf"; then
    log_success "$test_name"
  else
    log_error "$test_name - No outputs defined"
  fi
}

# Test 7: Check for sensitive variable handling
test_terraform_sensitive() {
  local test_name="Terraform sensitive variable handling"
  ((TOTAL++))
  
  log_test "$test_name"
  
  if grep -q "sensitive = true" "$TERRAFORM_DIR/variables.tf" || \
     grep -q "sensitive = true" "$TERRAFORM_DIR/outputs.tf"; then
    log_success "$test_name"
  else
    log_error "$test_name - No sensitive variables marked"
  fi
}

# Test 8: Terraform module dependency check
test_terraform_dependencies() {
  local test_name="Terraform module dependencies check"
  ((TOTAL++))
  
  log_test "$test_name"
  
  if grep -q "depends_on" "$TERRAFORM_DIR/main.tf"; then
    log_success "$test_name"
  else
    log_error "$test_name - No explicit dependencies defined"
  fi
}

# Test 9: Check for variable validation
test_terraform_validation() {
  local test_name="Terraform variable validation rules"
  ((TOTAL++))
  
  log_test "$test_name"
  
  if grep -q "validation {" "$TERRAFORM_DIR/variables.tf"; then
    log_success "$test_name"
  else
    log_error "$test_name - No validation blocks found"
  fi
}

# Test 10: Check tagging strategy
test_terraform_tags() {
  local test_name="Terraform resource tagging strategy"
  ((TOTAL++))
  
  log_test "$test_name"
  
  if grep -q "tags" "$TERRAFORM_DIR/modules/compute/main.tf" || \
     grep -q "tags" "$TERRAFORM_DIR/modules/storage/main.tf"; then
    log_success "$test_name"
  else
    log_error "$test_name - No tagging strategy found"
  fi
}

# Summary
print_summary() {
  local total_tests=$((PASS + FAIL))
  local pass_rate=$((PASS * 100 / total_tests))
  
  echo ""
  echo "================================"
  echo "Terraform Test Summary"
  echo "================================"
  echo -e "Total Tests:  $total_tests"
  echo -e "${GREEN}Passed:       $PASS${NC}"
  echo -e "${RED}Failed:       $FAIL${NC}"
  echo "Pass Rate:    $pass_rate%"
  echo "================================"
  
  return $FAIL
}

# Run all tests
main() {
  echo "========================================"
  echo "Terraform Module Validation Tests"
  echo "========================================"
  echo ""
  
  test_terraform_validate_main
  test_terraform_validate_modules
  test_terraform_format
  test_terraform_providers
  test_terraform_variables
  test_terraform_outputs
  test_terraform_sensitive
  test_terraform_dependencies
  test_terraform_validation
  test_terraform_tags
  
  print_summary
  exit $?
}

main "$@"
