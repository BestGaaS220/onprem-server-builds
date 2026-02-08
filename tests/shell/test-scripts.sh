#!/bin/bash
# Shell script validation tests
# Uses ShellCheck and tests shell scripts for best practices

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

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

# Test 1: Check for ShellCheck availability
test_shellcheck_available() {
  local test_name="ShellCheck availability"
  ((TOTAL++))
  
  log_test "$test_name"
  
  if command -v shellcheck &> /dev/null; then
    log_success "$test_name"
  else
    log_error "$test_name - ShellCheck not installed"
  fi
}

# Test 2: Validate provisioning scripts with ShellCheck
test_provisioning_scripts() {
  local test_name="Provisioning scripts ShellCheck validation"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local scripts_dir="$PROJECT_ROOT/image-build/shell"
  local scripts_valid=true
  
  for script in "$scripts_dir"/*.sh; do
    if ! shellcheck "$script" 2>/dev/null; then
      log_error "ShellCheck failed for $(basename $script)"
      scripts_valid=false
    fi
  done
  
  if [[ $scripts_valid == true ]]; then
    log_success "$test_name"
  else
    log_error "$test_name"
  fi
}

# Test 3: Check for set -e in shell scripts
test_error_handling_set_e() {
  local test_name="Shell script error handling (set -e)"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local scripts_dir="$PROJECT_ROOT/image-build/shell"
  local error_handling=true
  
  for script in "$scripts_dir"/*.sh; do
    if ! grep -q "^set -e" "$script"; then
      log_error "Missing 'set -e' in $(basename $script)"
      error_handling=false
    fi
  done
  
  if [[ $error_handling == true ]]; then
    log_success "$test_name"
  else
    log_error "$test_name"
  fi
}

# Test 4: Check for pipefail in shell scripts
test_error_handling_pipefail() {
  local test_name="Shell script error handling (pipefail)"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local scripts_dir="$PROJECT_ROOT/image-build/shell"
  local pipefail_found=true
  
  for script in "$scripts_dir"/*.sh; do
    if ! grep -q "pipefail" "$script"; then
      log_error "Missing 'pipefail' in $(basename $script)"
      pipefail_found=false
    fi
  done
  
  if [[ $pipefail_found == true ]]; then
    log_success "$test_name"
  else
    log_error "$test_name"
  fi
}

# Test 5: Validate bootstrap script
test_bootstrap_script() {
  local test_name="Bootstrap script validation"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local bootstrap="$PROJECT_ROOT/scripts/bootstrap.sh"
  
  if [[ ! -f "$bootstrap" ]]; then
    log_error "Bootstrap script not found"
  elif ! shellcheck "$bootstrap"; then
    log_error "Bootstrap script ShellCheck failed"
  else
    log_success "$test_name"
  fi
}

# Test 6: Check for logging functions
test_logging_functions() {
  local test_name="Shell script logging function"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local scripts_dir="$PROJECT_ROOT/image-build/shell"
  local logging_found=true
  
  for script in "$scripts_dir"/*.sh; do
    if ! grep -q "log\|echo\|log_message" "$script"; then
      log_error "No logging found in $(basename $script)"
      logging_found=false
    fi
  done
  
  if [[ $logging_found == true ]]; then
    log_success "$test_name"
  else
    log_error "$test_name"
  fi
}

# Test 7: Check script executability
test_script_permissions() {
  local test_name="Shell script permissions check"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local scripts_dir="$PROJECT_ROOT/image-build/shell"
  local permissions_valid=true
  
  for script in "$scripts_dir"/*.sh; do
    if [[ ! -x "$script" ]]; then
      chmod +x "$script"
    fi
  done
  
  if [[ $permissions_valid == true ]]; then
    log_success "$test_name"
  else
    log_error "$test_name"
  fi
}

# Test 8: Check for undef variable handling
test_undefined_variables() {
  local test_name="Shell script undefined variable handling"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local scripts_dir="$PROJECT_ROOT/image-build/shell"
  local undef_found=true
  
  for script in "$scripts_dir"/*.sh; do
    if ! grep -q "set -u\|set -o nounset" "$script"; then
      log_error "Missing undefined variable check in $(basename $script)"
      undef_found=false
    fi
  done
  
  if [[ $undef_found == true ]]; then
    log_success "$test_name"
  else
    log_error "$test_name"
  fi
}

# Test 9: Validate Makefile targets
test_makefile_targets() {
  local test_name="Makefile targets validation"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local makefile="$PROJECT_ROOT/Makefile"
  
  if [[ ! -f "$makefile" ]]; then
    log_error "Makefile not found"
  elif ! grep -q "^\.PHONY:" "$makefile"; then
    log_error "No .PHONY targets found in Makefile"
  else
    log_success "$test_name"
  fi
}

# Test 10: Check for documentation
test_documentation_comments() {
  local test_name="Shell script documentation comments"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local scripts_dir="$PROJECT_ROOT/image-build/shell"
  local doc_count=0
  
  for script in "$scripts_dir"/*.sh; do
    if head -n 3 "$script" | grep -q "^#"; then
      ((doc_count++))
    fi
  done
  
  if [[ $doc_count -eq $(ls -1 "$scripts_dir"/*.sh | wc -l) ]]; then
    log_success "$test_name"
  else
    log_error "$test_name - Missing documentation headers"
  fi
}

# Summary
print_summary() {
  local total_tests=$((PASS + FAIL))
  local pass_rate=$((PASS * 100 / total_tests))
  
  echo ""
  echo "================================"
  echo "Shell Script Test Summary"
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
  echo "Shell Script Validation Tests"
  echo "========================================"
  echo ""
  
  test_shellcheck_available
  test_provisioning_scripts
  test_error_handling_set_e
  test_error_handling_pipefail
  test_bootstrap_script
  test_logging_functions
  test_script_permissions
  test_undefined_variables
  test_makefile_targets
  test_documentation_comments
  
  print_summary
  exit $?
}

main "$@"
