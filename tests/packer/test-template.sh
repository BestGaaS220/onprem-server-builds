#!/bin/bash
# Packer template validation tests
# Tests Packer template syntax and configuration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PACKER_DIR="$PROJECT_ROOT/image-build/packer"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Test counters
PASS=0
FAIL=0
TOTAL=0

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

# Test 1: Validate Packer template syntax
test_packer_validate() {
  local test_name="Packer template syntax validation"
  ((TOTAL++))
  
  log_test "$test_name"
  
  if cd "$PACKER_DIR" && packer validate ubuntu.pkr.hcl; then
    log_success "$test_name"
  else
    log_error "$test_name"
  fi
}

# Test 2: Validate Packer variables files
test_packer_variables() {
  local test_name="Packer variables file validation"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local vars_valid=true
  local environments=("dev" "staging" "prod")
  
  for env in "${environments[@]}"; do
    if [[ ! -f "$PACKER_DIR/${env}.pkrvars.hcl" ]]; then
      log_error "Missing Packer variables: $env.pkrvars.hcl"
      vars_valid=false
    fi
  done
  
  if [[ $vars_valid == true ]]; then
    log_success "$test_name"
  else
    log_error "$test_name"
  fi
}

# Test 3: Check provisioner definitions
test_packer_provisioners() {
  local test_name="Packer provisioner definitions check"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local provisioners_found=0
  
  if grep -q "type = \"shell\"" "$PACKER_DIR/ubuntu.pkr.hcl"; then
    ((provisioners_found++))
  fi
  
  if grep -q "type = \"ansible\"" "$PACKER_DIR/ubuntu.pkr.hcl"; then
    ((provisioners_found++))
  fi
  
  if [[ $provisioners_found -gt 0 ]]; then
    log_success "$test_name (found $provisioners_found provisioners)"
  else
    log_error "$test_name - No provisioners defined"
  fi
}

# Test 4: Check for post-processor definitions
test_packer_post_processors() {
  local test_name="Packer post-processor definitions"
  ((TOTAL++))
  
  log_test "$test_name"
  
  if grep -q "post-processor" "$PACKER_DIR/ubuntu.pkr.hcl"; then
    log_success "$test_name"
  else
    log_error "$test_name - No post-processors configured"
  fi
}

# Test 5: Verify shell scripts exist
test_packer_shell_scripts() {
  local test_name="Packer provisioning shell scripts"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local scripts_valid=true
  local scripts=("update-system.sh" "install-packages.sh" "configure-security.sh" "validate-image.sh")
  
  for script in "${scripts[@]}"; do
    if [[ ! -f "$PROJECT_ROOT/image-build/shell/$script" ]]; then
      log_error "Missing shell script: $script"
      scripts_valid=false
    else
      # Check if script is executable
      if [[ ! -x "$PROJECT_ROOT/image-build/shell/$script" ]]; then
        chmod +x "$PROJECT_ROOT/image-build/shell/$script"
      fi
    fi
  done
  
  if [[ $scripts_valid == true ]]; then
    log_success "$test_name"
  else
    log_error "$test_name"
  fi
}

# Test 6: Check for error handling in shell scripts
test_packer_error_handling() {
  local test_name="Shell script error handling"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local scripts_dir="$PROJECT_ROOT/image-build/shell"
  local error_handling=true
  
  for script in "$scripts_dir"/*.sh; do
    if ! grep -q "set -e\|set -o pipefail" "$script"; then
      log_error "Missing error handling in $(basename $script)"
      error_handling=false
    fi
  done
  
  if [[ $error_handling == true ]]; then
    log_success "$test_name"
  else
    log_error "$test_name"
  fi
}

# Test 7: Check source URLs are HTTPS
test_packer_security() {
  local test_name="Packer security - HTTPS sources"
  ((TOTAL++))
  
  log_test "$test_name"
  
  if grep -q "http://" "$PACKER_DIR/ubuntu.pkr.hcl"; then
    log_error "$test_name - Non-HTTPS URL found"
  else
    log_success "$test_name"
  fi
}

# Test 8: Check timeout configurations
test_packer_timeouts() {
  local test_name="Packer timeout configurations"
  ((TOTAL++))
  
  log_test "$test_name"
  
  if grep -q "timeout" "$PACKER_DIR/ubuntu.pkr.hcl"; then
    log_success "$test_name"
  else
    log_error "$test_name - No timeout configurations"
  fi
}

# Test 9: Verify manifest output generation
test_packer_manifest() {
  local test_name="Packer manifest post-processor"
  ((TOTAL++))
  
  log_test "$test_name"
  
  if grep -q "manifest" "$PACKER_DIR/ubuntu.pkr.hcl"; then
    log_success "$test_name"
  else
    log_error "$test_name - No manifest generation configured"
  fi
}

# Test 10: Check source blocks
test_packer_sources() {
  local test_name="Packer source block definitions"
  ((TOTAL++))
  
  log_test "$test_name"
  
  if grep -q "source \"openstack\"" "$PACKER_DIR/ubuntu.pkr.hcl"; then
    log_success "$test_name"
  else
    log_error "$test_name - OpenStack source not defined"
  fi
}

# Summary
print_summary() {
  local total_tests=$((PASS + FAIL))
  local pass_rate=$((PASS * 100 / total_tests))
  
  echo ""
  echo "================================"
  echo "Packer Test Summary"
  echo "================================"
  echo "Total Tests:  $total_tests"
  echo -e "${GREEN}Passed:       $PASS${NC}"
  echo -e "${RED}Failed:       $FAIL${NC}"
  echo "Pass Rate:    $pass_rate%"
  echo "================================"
  
  return $FAIL
}

# Main
main() {
  echo "========================================"
  echo "Packer Template Validation Tests"
  echo "========================================"
  echo ""
  
  test_packer_validate
  test_packer_variables
  test_packer_provisioners
  test_packer_post_processors
  test_packer_shell_scripts
  test_packer_error_handling
  test_packer_security
  test_packer_timeouts
  test_packer_manifest
  test_packer_sources
  
  print_summary
  exit $?
}

main "$@"
