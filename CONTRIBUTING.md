# Contributing to Golden Image

Thank you for contributing to the Golden Image project! This document provides guidelines and instructions for participating in the project.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Workflow](#development-workflow)
4. [Coding Standards](#coding-standards)
5. [Testing Requirements](#testing-requirements)
6. [Commit Messages](#commit-messages)
7. [Pull Request Process](#pull-request-process)
8. [Issue Management](#issue-management)

## Code of Conduct

This project maintains a code of conduct to ensure a respectful, inclusive environment. Contributors are expected to:

- Be respectful and inclusive
- Accept constructive criticism
- Focus on the best interests of the project
- Report concerning behavior to project maintainers

## Getting Started

### Prerequisites

- Git >= 2.30
- Terraform >= 1.0
- Ansible >= 2.14
- Packer >= 1.8
- OpenStack CLI
- Python >= 3.10
- Make >= 4.0

### Setup Development Environment

```bash
# Clone the repository
git clone https://github.com/kushin77/onprem-server-builds.git
cd onprem-server-builds

# Install dependencies
make setup

# Verify setup
make validate
```

## Development Workflow

### 1. Create Feature Branch

```bash
# Update develop branch
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/description-of-feature
# Or for bugfixes:
git checkout -b bugfix/description-of-fix
```

### 2. Make Changes

- Keep commits focused and atomic
- Write clear, descriptive commit messages
- Update documentation as needed
- Add/update tests for new features

### 3. Local Testing

```bash
# Lint and validate
make lint
make validate

# Run tests
make test

# Optional: Build image locally
make image-build ENV=dev
```

### 4. Push and Create PR

```bash
# Push branch
git push origin feature/description-of-feature

# Create Pull Request on GitHub
# Link related issues
# Describe changes clearly
```

### 5. Code Review and Merge

- Address review comments promptly
- Ensure all checks pass
- Request re-review after updates
- Squash commits if requested
- Merge when approved

## Coding Standards

### General Principles

- DRY (Don't Repeat Yourself)
- KISS (Keep It Simple, Stupid)
- Fail fast, fail clearly
- Write code for humans first

### Terraform

```hcl
# Use consistent formatting
terraform fmt

# Valid example:
resource "openstack_compute_instance_v2" "web_server" {
  name            = var.instance_name
  image_name      = data.openstack_images_image_v2.ubuntu.name
  flavor_name     = var.flavor_name
  key_pair        = openstack_compute_keypair_v2.deployer.name
  security_groups = [openstack_networking_secgroup_v2.web.name]

  network {
    uuid = openstack_networking_network_v2.private.id
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

### Ansible

```yaml
# Use consistent formatting and indentation
---
- name: Configure web servers
  hosts: web_servers
  become: true
  vars:
    web_port: 8080
    
  pre_tasks:
    - name: Validate configuration
      assert:
        that:
          - web_port | int > 1024
        fail_msg: "Port must be > 1024"
  
  roles:
    - role: common
    - role: web-server
      vars:
        port: "{{ web_port }}"
  
  post_tasks:
    - name: Verify service
      uri:
        url: "http://localhost:{{ web_port }}/health"
        status_code: 200
```

### Shell Scripts

```bash
#!/bin/bash
set -euo pipefail

# Script description
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${SCRIPT_DIR}/build.log"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

main() {
    log "Starting build process..."
    # Implementation
    log "Build complete"
}

main "$@"
```

### Python

- Follow PEP 8 style guide
- Use type hints
- Add docstrings
- Maintain 80% test coverage

```python
#!/usr/bin/env python3
"""Module documentation."""

from typing import Optional

def validate_configuration(config_path: str) -> bool:
    """Validate configuration file.
    
    Args:
        config_path: Path to configuration file
        
    Returns:
        True if configuration is valid
        
    Raises:
        FileNotFoundError: If config file not found
        ValueError: If configuration is invalid
    """
    # Implementation
    return True
```

## Testing Requirements

### Test Coverage

- Unit tests: ≥ 80% code coverage
- Integration tests: Critical paths
- All changes require test updates

### Running Tests

```bash
# Unit tests
make test-unit

# Integration tests
make test-integration

# All tests
make test

# Coverage report
make test-coverage
```

### Test Structure

```
tests/
├── unit/
│   ├── test_validators.py
│   ├── test_config.py
│   └── test_utils.py
├── integration/
│   ├── test_image_build.py
│   ├── test_deployment.py
│   └── test_end_to_end.py
└── fixtures/
    ├── sample_config.yaml
    └── test_inventory.ini
```

## Commit Messages

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style (formatting, missing semicolons, etc.)
- **refactor**: Code refactoring
- **perf**: Performance improvements
- **test**: Test additions/updates
- **chore**: Build, dependencies, tooling
- **ci**: CI/CD pipeline changes

### Examples

```
feat(packer): add GPU support for image build

This commit adds NVIDIA GPU provisioning to the Packer template,
enabling GPU-accelerated workloads on deployed instances.

- Install NVIDIA drivers
- Configure GPU utilization monitoring
- Update instance type validation

Fixes #42
```

```
fix(ansible): resolve network configuration ordering issue

Network interfaces were configured before routes were available,
causing deployment failures. Reordered playbook tasks.

Closes #85
```

## Pull Request Process

### Before Creating PR

1. ✅ All tests pass locally
2. ✅ Code is linted and formatted
3. ✅ Documentation is updated
4. ✅ Commit messages are clear
5. ✅ Branch is up-to-date with develop

### PR Template

See `.github/pull_request_template.md` for the standardized template.

### PR Checklist

- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] Code follows style guidelines
- [ ] No breaking changes (note if there are)
- [ ] Related issues linked
- [ ] Commits are descriptive

### Review Process

- Minimum 1 approval required
- All conversations resolved
- All checks passing
- Branch updated with main before merge

## Issue Management

### Creating Issues

- Use issue templates
- Provide clear description
- Include steps to reproduce (for bugs)
- Label appropriately
- Link related issues

### Issue Labels

- `bug`: Defects
- `enhancement`: Improvements/features
- `docs`: Documentation
- `infrastructure`: IaC changes
- `image-build`: Image building
- `testing`: Testing
- `deployment`: Deployment
- `security`: Security issues
- `critical`: Blocking/critical
- `good first issue`: Suitable for new contributors

### Issue Workflow

```
[New] → [Triage] → [In Progress] → [Review] → [Closed/Done]
```

## Questions?

- Check existing documentation
- Search closed issues
- Create a discussion or issue
- Contact project maintainers

## Recognition

Contributors are recognized in:
- Release notes
- CONTRIBUTORS.md file
- GitHub contributor graphs

Thank you for contributing! 🙏
