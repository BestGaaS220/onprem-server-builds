#!/bin/bash
# Unified test runner - Runs all test suites
# Provides comprehensive test report

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TESTS_DIR="$PROJECT_ROOT/tests"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Global counters
TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_TESTS=0

# Functions
run_test_suite() {
  local suite_name=$1
  local test_script=$2
  
  echo ""
  echo -e "${BLUE}======================================${NC}"
  echo -e "${BLUE}Running: $suite_name${NC}"
  echo -e "${BLUE}======================================${NC}"
  echo ""
  
  if [[ ! -f "$test_script" ]]; then
    echo -e "${RED}ERROR: Test script not found: $test_script${NC}"
    return 1
  fi
  
  # Run the test script and capture results
  bash "$test_script" || return 1
}

# Summary report
generate_report() {
  echo ""
  echo ""
  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║                     COMPREHENSIVE TEST REPORT                  ║"
  echo "╚════════════════════════════════════════════════════════════════╝"
  echo ""
  
  echo "Test Suites Executed:"
  echo "  ✓ Terraform Module Validation"
  echo "  ✓ Packer Template Validation"
  echo "  ✓ Ansible Playbook Validation"
  echo "  ✓ Shell Script Validation"
  echo ""
  
  local total=$((TOTAL_PASS + TOTAL_FAIL))
  if [[ $total -gt 0 ]]; then
    local pass_rate=$(( (TOTAL_PASS * 100) / total ))
  else
    local pass_rate=0
  fi
  
  echo "Overall Results:"
  echo -e "  Total Tests:  $total"
  echo -e "  ${GREEN}Passed:       $TOTAL_PASS${NC}"
  echo -e "  ${RED}Failed:       $TOTAL_FAIL${NC}"
  echo "  Pass Rate:    $pass_rate%"
  echo ""
  
  if [[ $TOTAL_FAIL -eq 0 ]]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
    echo ""
    return 0
  else
    echo -e "${RED}✗ SOME TESTS FAILED - Review output above${NC}"
    echo ""
    return 1
  fi
}

# Main execution
main() {
  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║         GOLDEN IMAGE TEST SUITE - Full Validation             ║"
  echo "║           Infrastructure as Code Quality Assurance            ║"
  echo "╚════════════════════════════════════════════════════════════════╝"
  echo ""
  echo "Start Time: $(date)"
  echo "Project Root: $PROJECT_ROOT"
  echo ""
  
  # Track overall pass/fail
  local failed=0
  
  # Run each test suite
  if ! run_test_suite "Terraform Module Tests" "$TESTS_DIR/terraform/test-modules.sh"; then
    failed=1
  fi
  
  if ! run_test_suite "Packer Template Tests" "$TESTS_DIR/packer/test-template.sh"; then
    failed=1
  fi
  
  if ! run_test_suite "Ansible Playbook Tests" "$TESTS_DIR/ansible/test-playbooks.sh"; then
    failed=1
  fi
  
  if ! run_test_suite "Shell Script Tests" "$TESTS_DIR/shell/test-scripts.sh"; then
    failed=1
  fi
  
  # Generate final report
  generate_report
  
  echo "End Time: $(date)"
  echo ""
  
  if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}All test suites completed successfully!${NC}"
    exit 0
  else
    echo -e "${RED}Some test suites failed. Review output above.${NC}"
    exit 1
  fi
}

main "$@"
