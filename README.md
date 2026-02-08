# On-Premise Server Golden Image

Enterprise-grade golden image build and deployment system for ElevatedIQ on-premise physical servers.

## Overview

This repository manages the complete lifecycle of golden image creation, validation, and deployment for on-premise ElevatedIQ deployments. It includes:

- **Image Building**: Packer configurations for creating reproducible golden images
- **Infrastructure as Code**: Terraform and Ansible for cloud/infrastructure automation
- **Configuration Management**: Centralized server configurations and policy enforcement
- **Build Automation**: CI/CD pipelines for automated image validation and release
- **Testing Framework**: Comprehensive test suites for image validation
- **Documentation**: Architecture decisions, runbooks, and operational guides

## Quick Start

### Prerequisites

- Terraform >= 1.0
- Ansible >= 2.14
- Packer >= 1.8
- OpenStack CLI (openstack)
- Make >= 4.0
- Python >= 3.10

### Building a Golden Image

```bash
# Validate configuration
make validate

# Build golden image
make image-build ENV=prod

# Test image
make test-image

# Deploy image
make deploy ENV=prod
```

## Repository Structure

```
├── .github/                          # GitHub configuration
│   ├── workflows/                    # CI/CD pipelines
│   └── ISSUE_TEMPLATE/              # Issue templates
├── docs/                            # Documentation
│   ├── ARCHITECTURE.md              # System architecture
│   ├── BUILD_PROCESS.md             # Build process guide
│   ├── DEPLOYMENT.md                # Deployment runbook
│   └── TROUBLESHOOTING.md           # Troubleshooting guide
├── scripts/                         # Utility scripts
│   ├── validate.sh                  # Configuration validation
│   ├── test.sh                      # Testing framework
│   └── deploy.sh                    # Deployment automation
├── configs/                         # Server configurations
│   ├── network/                     # Network configuration
│   ├── storage/                     # Storage configuration
│   ├── security/                    # Security policies
│   └── monitoring/                  # Monitoring config
├── infrastructure/                  # IaC configurations
│   ├── terraform/                   # Terraform modules
│   │   ├── openstack/              # OpenStack infrastructure
│   │   └── modules/                # Reusable modules
│   └── ansible/                     # Ansible playbooks
│       ├── playbooks/              # Deployment playbooks
│       ├── roles/                  # Ansible roles
│       └── inventories/            # Host inventories
├── image-build/                    # Image building configurations
│   ├── packer/                     # Packer templates
│   │   ├── ubuntu.pkr.hcl          # Ubuntu image config
│   │   └── variables.pkr.hcl       # Packer variables
│   └── cloud-init/                 # Cloud-init configurations
│       ├── user-data               # User data scripts
│       └── network-config          # Network configuration
├── tests/                          # Test suites
│   ├── unit/                       # Unit tests
│   ├── integration/                # Integration tests
│   └── validation/                 # Image validation tests
├── Makefile                        # Build automation
├── LICENSE                         # Apache 2.0 License
└── .gitignore                      # Git ignore rules
```

## Development Workflow

### Branching Strategy

- `main`: Production-ready code (protected)
- `develop`: Integration branch
- `feature/*`: Feature branches
- `bugfix/*`: Bugfix branches
- `release/*`: Release branches

### Creating a Feature

1. Create a feature branch: `git checkout -b feature/my-feature`
2. Make changes and commit with clear messages
3. Create a Pull Request with reference to GitHub issue
4. Pass all automated checks (linting, tests, security scans)
5. Obtain code review approval
6. Merge to develop

### Building and Testing

```bash
# Lint and validate
make lint
make validate

# Run unit tests
make test-unit

# Run integration tests
make test-integration

# Build golden image
make image-build ENV=staging

# Full test suite
make test
```

## CI/CD Pipelines

### Automated Workflows

- **PR Validation**: Linting, security scanning, syntax validation
- **Image Build**: Automated golden image creation on merge to main
- **Testing**: Automated test suite execution
- **Deployment**: Automated deployment to staging/production

## Documentation

- [Architecture](docs/ARCHITECTURE.md) - System design and decisions
- [Build Process](docs/BUILD_PROCESS.md) - Detailed build guide
- [Deployment Guide](docs/DEPLOYMENT.md) - Deployment procedures
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Contributing](CONTRIBUTING.md) - Contribution guidelines

## Issues and Project Management

All tasks and issues are tracked in [GitHub Issues](https://github.com/kushin77/onprem-server-builds/issues).

### Issue Labels

- `bug`: Defects requiring fixes
- `enhancement`: New features or improvements
- `docs`: Documentation updates
- `infrastructure`: Infrastructure/IaC changes
- `image-build`: Image building changes
- `testing`: Test-related issues
- `deployment`: Deployment-related issues
- `security`: Security-related issues
- `critical`: Critical/blocking issues
- `in-progress`: Currently being worked on
- `blocked`: Blocked by another issue

## Support and Troubleshooting

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues.

For security issues, please contact the security team rather than creating a public issue.

## License

This project is licensed under the Apache License 2.0 - see [LICENSE](LICENSE) file for details.

## Related Projects

- [ElevatedIQ Mono Repo](https://github.com/kushin77/ElevatedIQ-Mono-Repo) - Main application repository

## Version History

### [Unreleased]

- Initial project setup and documentation
- Core directory structure
- CI/CD pipeline templates
- Packer configuration templates
- Terraform module structure
