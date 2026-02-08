# Golden Image Build Process

## Overview

This document provides a detailed guide for building, testing, and deploying the golden image.

## Prerequisites

### System Requirements

- 4+ CPU cores
- 8+ GB RAM
- 50+ GB free disk space
- Gigabit network connection
- OpenStack credentials and CLI access

### Software Requirements

Check versions:
```bash
terraform --version      # >= 1.0
ansible --version       # >= 2.14
packer --version        # >= 1.8
openstack --version     # >= 5.8
```

## Build Workflow

### Phase 1: Configuration Validation

```bash
# Validate all configurations
make validate

# Validate specific component
make validate-terraform
make validate-ansible
make validate-packer
```

**Checks performed:**
- HCL syntax validation
- YAML syntax validation
- Configuration schema compliance
- Variable definition verification

### Phase 2: Image Building

#### 2.1 Using Packer

```bash
# Build for development environment
make image-build ENV=dev

# Build for staging
make image-build ENV=staging

# Build for production
make image-build ENV=prod VERSION=v1.2.3
```

**What happens during build:**
1. Packer downloads base OS image
2. Launches temporary instance
3. Executes provisioners (scripts, files, Ansible)
4. Applies configuration management
5. Optimizes image (cleanup, compression)
6. Creates snapshot on OpenStack
7. Tags image with metadata

#### 2.2 Build Variables

Key variables in `image-build/packer/variables.pkrvars.hcl`:

```hcl
# Environment (dev, staging, prod)
environment = "dev"

# Image version
version = "1.0.0"

# OpenStack settings
openstack_username = var.os_username
openstack_password = var.os_password
openstack_auth_url = var.os_auth_url

# Instance sizing
flavor_name = "m1.large"  # 4 CPU, 8GB RAM

# Image configuration
image_name = "Golden-Image-Ubuntu-20.04"
```

### Phase 3: Image Testing

#### 3.1 Automated Testing

```bash
# Run all tests
make test

# Run unit tests
make test-unit

# Run integration tests
make test-integration

# Test built image
make test-image
```

**Test categories:**

- **Configuration Validation**: Syntax, schema, policies
- **Functionality Tests**: Service status, API endpoints
- **Performance Tests**: Benchmark results
- **Security Tests**: Vulnerability scans, hardening verification

#### 3.2 Manual Testing

```bash
# Launch instance from image
openstack server create \
  --image "Golden-Image-Ubuntu-20.04" \
  --flavor m1.large \
  --key-name deployer-key \
  test-instance

# SSH into instance
ssh -i deployer-key.pem ubuntu@<instance-ip>

# Verify services
sudo systemctl status elevatediq
sudo journalctl -u elevatediq -n 50

# Test application
curl http://localhost:8080/health
```

### Phase 4: Image Registry

#### 4.1 Tagging and Metadata

```bash
# Tag image in OpenStack
openstack image set \
  "Golden-Image-Ubuntu-20.04-v1.0.0" \
  --tag production \
  --property environment=prod \
  --property version=1.0.0 \
  --property build_date=2024-02-08
```

#### 4.2 Image Lifecycle

- **Active**: Production-ready images
- **Staging**: Candidate images for promotion
- **Archived**: Previous versions (backup)
- **Deprecated**: No longer used (can be deleted)

## Infrastructure Provisioning (Terraform)

### Phase 1: Initialization

```bash
# Initialize Terraform working directory
cd infrastructure/terraform
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive
```

### Phase 2: Planning

```bash
# Plan for specific environment
make plan ENV=staging

# Show detailed diff
cd infrastructure/terraform
terraform plan -var-file=../../vars/staging.tfvars
```

**Plan review checklist:**
- [ ] Correct environment (dev/staging/prod)
- [ ] Expected resource changes
- [ ] No unintended deletions
- [ ] Correct sizing (CPU, RAM, storage)

### Phase 3: Deployment

```bash
# Deploy infrastructure
make deploy ENV=staging

# Or manually
cd infrastructure/terraform
terraform apply -var-file=../../vars/staging.tfvars

# Show current state
terraform show
```

**Resources created:**
- Compute instances
- Network interfaces
- Security groups
- Storage volumes
- Load balancers

## Configuration Management (Ansible)

### Phase 1: Inventory Preparation

Edit `infrastructure/ansible/inventories/staging.ini`:

```ini
[all:vars]
ansible_user = ubuntu
ansible_ssh_private_key_file = ~/.ssh/deployer-key.pem
ansible_python_interpreter = /usr/bin/python3

[web_servers]
server1.example.com
server2.example.com

[database_servers]
db1.example.com
```

### Phase 2: Playbook Execution

```bash
# Validate playbook
ansible-playbook --syntax-check \
  -i infrastructure/ansible/inventories/staging.ini \
  infrastructure/ansible/playbooks/main.yml

# Run playbook in check mode (dry-run)
ansible-playbook \
  -i infrastructure/ansible/inventories/staging.ini \
  infrastructure/ansible/playbooks/main.yml \
  --check

# Execute playbook
make configure ENV=staging
```

### Phase 3: Verify Deployment

```bash
# Check if services are running
ansible all -i inventories/staging.ini \
  -m service \
  -a "name=elevatediq state=started"

# Verify application connectivity
ansible web_servers -i inventories/staging.ini \
  -m uri \
  -a "url=http://localhost:8080/health method=GET"

# Collect facts
ansible all -i inventories/staging.ini -m setup
```

## Complete Build Pipeline

### One-Command Build

```bash
# Full build for environment
make setup && \
make validate && \
make lint && \
make test && \
make image-build ENV=staging && \
make test-image && \
make plan ENV=staging && \
make deploy ENV=staging && \
make configure ENV=staging
```

### Environment-Specific Examples

#### Development Build

```bash
# Quick build for testing
ENV=dev make clean validate image-build test-image
```

#### Staging Build

```bash
# Full validation and testing
ENV=staging make validate lint test image-build test-image

# Manual review of plan
ENV=staging make plan

# Deploy when ready
ENV=staging make deploy
```

#### Production Build

```bash
# Full pipeline with version
VERSION=v1.2.3 ENV=prod make validate lint test

# Build production image
VERSION=v1.2.3 ENV=prod make image-build

# Production deployment requires manual approval
ENV=prod make plan  # Review carefully
terraform apply      # Manual approval required
```

## Troubleshooting Common Issues

### Build Failures

```bash
# Check recent logs
make logs

# Rebuild with verbose output
make image-build ENV=dev --debug

# Check Packer cache
rm -rf packer_cache/
```

### Configuration Issues

```bash
# Validate YAML syntax
yamllint infrastructure/ansible/playbooks/*.yml

# Validate Jinja2 templates
ansible-playbook --syntax-check playbooks/main.yml
```

### Deployment Issues

```bash
# Check Terraform state
terraform show

# Verify infrastructure
openstack server list
openstack image list

# Check instance logs
openstack console log show <instance-id>
```

## Performance Optimization

### Build Time Optimization

1. **Use cached images**: Packer caches downloaded files
2. **Parallel provisioning**: Use Ansible handlers efficiently
3. **Minimize dependencies**: Install only required packages
4. **Pre-download artifacts**: Include in build, not post-deploy

### Image Optimization

1. **Reduce image size**: Remove unnecessary packages
2. **Compress disk**: `fstrim` for sparse files
3. **Optimize startup**: Systemd parallel startup
4. **Cache management**: Configure apt/yum caching

## Post-Build Activities

### Health Checks

```bash
# Verify services
systemctl status elevatediq
systemctl status monitoring-agent

# Check resource utilization
free -h
df -h
top -n 1
```

### Documentation Updates

- [ ] Update version numbers
- [ ] Document any configuration changes
- [ ] Update deployment runbook
- [ ] Tag git repository

### Archival and Cleanup

```bash
# Archive previous images
openstack image set old-image --tag archived

# Delete outdated images
openstack image delete old-image-v1.0.0
```

## Release Checklist

- [ ] All tests passing
- [ ] Code review complete
- [ ] Documentation updated
- [ ] Changelog updated
- [ ] Version number bumped
- [ ] Git tag created
- [ ] Image built successfully
- [ ] Image tested
- [ ] Deployment plan reviewed
- [ ] Staging deployment successful
- [ ] Production approval obtained
- [ ] Production deployment successful
- [ ] Post-deployment verification done
- [ ] Monitoring and alerting configured
