#!/bin/bash
# Ansible playbook validation tests
# Tests Ansible syntax, roles, and best practices

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ANSIBLE_DIR="$PROJECT_ROOT/infrastructure/ansible"

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

# Test 1: Validate main playbook syntax
test_ansible_syntax() {
  local test_name="Ansible playbook syntax validation"
  ((TOTAL++))
  
  log_test "$test_name"
  
  if ansible-playbook --syntax-check "$ANSIBLE_DIR/playbooks/main.yml" > /dev/null 2>&1; then
    log_success "$test_name"
  else
    log_error "$test_name"
  fi
}

# Test 2: Check all roles exist
test_ansible_roles() {
  local test_name="Ansible roles existence check"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local roles=("common" "security" "monitoring" "application")
  local roles_valid=true
  
  for role in "${roles[@]}"; do
    if [[ ! -d "$ANSIBLE_DIR/roles/$role" ]]; then
      log_error "Missing role directory: $role"
      roles_valid=false
    fi
  done
  
  if [[ $roles_valid == true ]]; then
    log_success "$test_name"
  else
    log_error "$test_name"
  fi
}

# Test 3: Verify role structure
test_ansible_role_structure() {
  local test_name="Ansible role structure validation"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local roles=("common" "security" "monitoring" "application")
  local structure_valid=true
  
  for role in "${roles[@]}"; do
    if [[ ! -f "$ANSIBLE_DIR/roles/$role/tasks/main.yml" ]]; then
      log_error "Missing tasks/main.yml for role: $role"
      structure_valid=false
    fi
  done
  
  if [[ $structure_valid == true ]]; then
    log_success "$test_name"
  else
    log_error "$test_name"
  fi
}

# Test 4: Check for role defaults
test_ansible_role_defaults() {
  local test_name="Ansible role defaults definitions"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local roles=("common" "security" "monitoring" "application")
  local defaults_valid=true
  
  for role in "${roles[@]}"; do
    if [[ ! -f "$ANSIBLE_DIR/roles/$role/defaults/main.yml" ]]; then
      log_error "Missing defaults/main.yml for role: $role"
      defaults_valid=false
    fi
  done
  
  if [[ $defaults_valid == true ]]; then
    log_success "$test_name"
  else
    log_error "$test_name"
  fi
}

# Test 5: Verify handlers are defined
test_ansible_handlers() {
  local test_name="Ansible handler definitions check"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local handlers_count=0
  
  if [[ -f "$ANSIBLE_DIR/roles/security/handlers/main.yml" ]]; then
    handlers_count=$(grep -c "^- name:" "$ANSIBLE_DIR/roles/security/handlers/main.yml" || echo 0)
  fi
  
  if [[ $handlers_count -gt 0 ]]; then
    log_success "$test_name (found $handlers_count handlers)"
  else
    log_error "$test_name - No handlers found"
  fi
}

# Test 6: Check for inventory files
test_ansible_inventories() {
  local test_name="Ansible inventory files check"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local environments=("dev" "staging" "prod")
  local inventories_valid=true
  
  for env in "${environments[@]}"; do
    if [[ ! -f "$ANSIBLE_DIR/inventories/${env}.ini" ]]; then
      log_error "Missing inventory: $env.ini"
      inventories_valid=false
    fi
  done
  
  if [[ $inventories_valid == true ]]; then
    log_success "$test_name"
  else
    log_error "$test_name"
  fi
}

# Test 7: Validate playbook structure
test_ansible_playbook_structure() {
  local test_name="Ansible playbook structure validation"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local structure_valid=true
  
  if ! grep -q "pre_tasks:" "$ANSIBLE_DIR/playbooks/main.yml"; then
    log_error "No pre_tasks defined"
    structure_valid=false
  fi
  
  if ! grep -q "roles:" "$ANSIBLE_DIR/playbooks/main.yml"; then
    log_error "No roles defined"
    structure_valid=false
  fi
  
  if ! grep -q "post_tasks:" "$ANSIBLE_DIR/playbooks/main.yml"; then
    log_error "No post_tasks defined"
    structure_valid=false
  fi
  
  if [[ $structure_valid == true ]]; then
    log_success "$test_name"
  else
    log_error "$test_name"
  fi
}

# Test 8: Check for Jinja2 templates
test_ansible_templates() {
  local test_name="Ansible role templates check"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local template_count=$(find "$ANSIBLE_DIR/roles" -name "*.j2" | wc -l)
  
  if [[ $template_count -gt 0 ]]; then
    log_success "$test_name (found $template_count templates)"
  else
    log_error "$test_name - No Jinja2 templates found"
  fi
}

# Test 9: Check for tags in tasks
test_ansible_tags() {
  local test_name="Ansible task tagging check"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local roles=("common" "security" "monitoring" "application")
  local tags_valid=true
  
  for role in "${roles[@]}"; do
    local task_count=$(grep -c "^- name:" "$ANSIBLE_DIR/roles/$role/tasks/main.yml" || echo 0)
    local tag_count=$(grep -c "tags:" "$ANSIBLE_DIR/roles/$role/tasks/main.yml" || echo 0)
    
    # Allow some untagged tasks (like display messages)
    if [[ $task_count -gt 0 && $tag_count -lt $((task_count / 2)) ]]; then
      log_error "Insufficient tagging in role: $role"
      tags_valid=false
    fi
  done
  
  if [[ $tags_valid == true ]]; then
    log_success "$test_name"
  else
    log_error "$test_name"
  fi
}

# Test 10: Check for idempotency indicators
test_ansible_idempotency() {
  local test_name="Ansible idempotency indicators"
  ((TOTAL++))
  
  log_test "$test_name"
  
  local idempotent_modules=("apt:" "service:" "file:" "template:" "lineinfile:")
  local found=false
  
  for module in "${idempotent_modules[@]}"; do
    if grep -q "$module" "$ANSIBLE_DIR/roles/common/tasks/main.yml"; then
      found=true
      break
    fi
  done
  
  if [[ $found == true ]]; then
    log_success "$test_name"
  else
    log_error "$test_name - No idempotent modules found"
  fi
}

# Summary
print_summary() {
  local total_tests=$((PASS + FAIL))
  local pass_rate=$((PASS * 100 / total_tests))
  
  echo ""
  echo "================================"
  echo "Ansible Test Summary"
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
  echo "Ansible Playbook Validation Tests"
  echo "========================================"
  echo ""
  
  test_ansible_syntax
  test_ansible_roles
  test_ansible_role_structure
  test_ansible_role_defaults
  test_ansible_handlers
  test_ansible_inventories
  test_ansible_playbook_structure
  test_ansible_templates
  test_ansible_tags
  test_ansible_idempotency
  
  print_summary
  exit $?
}

main "$@"
