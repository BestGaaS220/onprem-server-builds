# Golden Image Testing Framework

This directory contains comprehensive tests for the golden image infrastructure as code.

## Test Structure

### `terraform/test-modules.sh`
Validates Terraform configuration and modules:
- Terraform syntax validation
- Module structure verification
- Provider compatibility checks
- Variable definitions and validation
- Dependency management
- Tagging strategy
- Output definitions

**Tests**: 10 validation checks
**Coverage**: All 4 modules + main configuration
**Run**: `./tests/terraform/test-modules.sh`

### `packer/test-template.sh`
Validates Packer template and provisioning:
- HCL2 syntax validation
- Provisioner definitions
- Post-processor configuration
- Shell script availability
- Error handling verification
- Security checks (HTTPS sources)
- Timeout configurations
- Manifest generation

**Tests**: 10 validation checks
**Coverage**: Packer template + 4 provisioning scripts
**Run**: `./tests/packer/test-template.sh`

### `ansible/test-playbooks.sh`
Validates Ansible playbooks and roles:
- Playbook syntax validation
- Role structure verification
- Handler definitions
- Inventory files
- Jinja2 template validation
- Task tagging strategy
- Idempotency indicators
- Default variables

**Tests**: 10 validation checks
**Coverage**: Main playbook + 4 roles
**Run**: `./tests/ansible/test-playbooks.sh`

### `shell/test-scripts.sh`
Validates shell scripts and best practices:
- ShellCheck linting (SC2xxx checks)
- Error handling (`set -e`, `pipefail`)
- Undefined variable detection
- Logging function presence
- Script executability
- Documentation headers
- Makefile validation

**Tests**: 10 validation checks
**Coverage**: All shell scripts in image-build/shell
**Run**: `./tests/shell/test-scripts.sh`

### `run-all-tests.sh`
Unified test runner executing all test suites with:
- Centralized reporting
- Pass/fail aggregation
- Execution timing
- Summary statistics
- Color-coded output

**Run**: `./tests/run-all-tests.sh`

## Running Tests

### Run All Tests
```bash
./tests/run-all-tests.sh
```

### Run Individual Test Suites
```bash
./tests/terraform/test-modules.sh
./tests/packer/test-template.sh
./tests/ansible/test-playbooks.sh
./tests/shell/test-scripts.sh
```

### Run from Makefile
```bash
make test           # Run all tests
make test-tf        # Terraform only
make test-packer    # Packer only
make test-ansible   # Ansible only
make test-shell     # Shell scripts only
```

## Test Coverage

| Component | Tests | Categories | Pass Req |
|-----------|-------|-----------|----------|
| Terraform | 10 | Syntax, Modules, Format, Variables, Tags | 100% |
| Packer | 10 | Template, Provisioners, Scripts, Security | 100% |
| Ansible | 10 | Syntax, Roles, Structure, Tags, Handlers | 100% |
| Shell | 10 | Linting, Error Handling, Permissions, Docs | 100% |
| **Total** | **40** | **Comprehensive IaC Validation** | **100%** |

## Test Categories

### Syntax Validation (10 tests)
- Terraform validate
- Packer validate
- Ansible --syntax-check
- ShellCheck

### Structure Validation (10 tests)
- Role directories
- File existence
- Module organization
- Directory hierarchy

### Best Practices (15 tests)
- Error handling
- Logging
- Documentation
- Tagging strategy
- Security hardening

### Configuration (5 tests)
- Variable definitions
- Handler setup
- Provisioner configuration
- Default values

## Success Criteria

All tests must pass with 100% pass rate for:
1. **Development (dev environment)**
   - All 40 tests pass
   - No warnings or style issues

2. **Staging (staging environment)**
   - All 40 tests pass
   - Code review completed
   - No security issues

3. **Production (prod environment)**
   - All 40 tests pass
   - Load testing completed
   - Documentation verified
   - Disaster recovery plan validated

## Continuous Integration

These tests are designed to run in CI/CD pipelines:

```yaml
# Example GitHub Actions
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
    - name: Install tools
      run: |
        sudo apt-get install -y ansible terraform packer shellcheck
    - name: Run tests
      run: ./tests/run-all-tests.sh
```

## Dependencies

### Required Tools
- `terraform` >= 1.0
- `packer` >= 1.8
- `ansible` >= 2.10
- `shellcheck` >= 0.8

### Installation
```bash
# Ubuntu/Debian
sudo apt-get install -y terraform packer ansible shellcheck

# macOS
brew install terraform packer ansible shellcheck
```

## Exit Codes

- `0`: All tests passed
- `1`: One or more tests failed
- `2`: Test script not found
- `3`: Required tool not available

## Troubleshooting

### ShellCheck Warnings
```bash
shellcheck image-build/shell/*.sh -x
```

### Terraform Issues
```bash
terraform validate -json
terraform plan -out=tfplan
```

### Ansible Syntax
```bash
ansible-playbook playbooks/main.yml --syntax-check -vv
```

### Packer Issues
```bash
packer validate -syntax-only ubuntu.pkr.hcl
```

## Contributing

When adding new tests:
1. Follow naming convention: `test_<description>()`
2. Add to appropriate test file
3. Update this README
4. Ensure 100% pass rate
5. Document in commit message

## Maintenance

- **Weekly**: Run full test suite in CI/CD
- **Monthly**: Update ShellCheck rules
- **Quarterly**: Review test coverage
- **Annually**: Audit and refactor tests
