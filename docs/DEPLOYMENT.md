# Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying golden images to production on-premise infrastructure.

## Pre-Deployment Checklist

### Infrastructure Preparation

- [ ] OpenStack cluster is operational
- [ ] Network connectivity verified
- [ ] Security credentials configured
- [ ] Storage backend available
- [ ] Resource quotas adjusted
- [ ] DNS records prepared
- [ ] SSL certificates ready (if needed)

### Image Verification

- [ ] Image successfully built and tested
- [ ] All automated tests passed
- [ ] Security scan completed
- [ ] Performance benchmarks acceptable
- [ ] Version tagged and documented
- [ ] Change log updated

### Access Control

- [ ] Deployment credentials available
- [ ] SSH keys distributed
- [ ] VPN/Network access verified
- [ ] Firewall rules updated
- [ ] RBAC permissions configured

## Deployment Environments

### Development Deployment

**Purpose**: Developer testing and validation

```bash
# Build and deploy
ENV=dev make image-build deploy

# Tear down when done
ENV=dev make destroy
```

**Resource Sizing:**
- Instances: Single node
- CPU: 2-4 cores
- RAM: 4-8 GB
- Storage: 20 GB

**Timeline**: Can be redeployed daily

### Staging Deployment

**Purpose**: Final testing before production

```bash
# Full validation pipeline
ENV=staging make validate test image-build test-image plan

# Review plan output
# If approved:
ENV=staging make deploy configure

# Run final acceptance tests
make test-image
```

**Resource Sizing:**
- Instances: 2-3 nodes
- CPU: 4 cores per node
- RAM: 16 GB per node
- Storage: 50 GB per node

**Timeline**: Stable for 1-2 weeks before prod release

### Production Deployment

**Purpose**: Customer-facing environment

```bash
# Requires version tag
VERSION=v1.2.3 ENV=prod make validate test image-build

# Manual plan review CRITICAL
ENV=prod make plan

# Manual approval required
ENV=prod make deploy
ENV=prod make configure

# Production acceptance tests
ENV=prod make test-image
```

**Resource Sizing:**
- Instances: 3+ nodes (HA)
- CPU: 8+ cores per node
- RAM: 32+ GB per node
- Storage: 100+ GB per node

**Timeline**: Long-term stability

## Step-by-Step Deployment

### 1. Infrastructure Provisioning

```bash
# Navigate to infrastructure directory
cd infrastructure/terraform

# Initialize
terraform init -upgrade

# Plan which resources will be created
terraform plan \
  -var-file=../../vars/prod.tfvars \
  -out=../../build/prod-tfplan

# Review the plan carefully
cat ../../build/prod-tfplan

# Apply the plan
terraform apply ../../build/prod-tfplan
```

**Verify infrastructure creation:**

```bash
# List created instances
openstack server list

# Verify network setup
openstack network list
openstack subnet list

# Check security groups
openstack security group list

# Verify floating IPs
openstack floating ip list
```

### 2. Configuration Management

```bash
# Navigate to Ansible directory
cd infrastructure/ansible

# Create/update inventory
# File: inventories/prod.ini
[prod:vars]
ansible_user = ubuntu
ansible_become = true
ansible_ssh_private_key_file = ~/.ssh/prod-key.pem

[web_servers]
server1.prod.example.com
server2.prod.example.com

[database_servers]
db1.prod.example.com

# Verify SSH access
ansible all -i inventories/prod.ini -m ping

# Dry-run playbook (check mode)
ansible-playbook playbooks/main.yml \
  -i inventories/prod.ini \
  --check

# Execute playbook
ansible-playbook playbooks/main.yml \
  -i inventories/prod.ini \
  -v
```

**Verify configuration deployment:**

```bash
# Check service status
ansible all -i inventories/prod.ini \
  -m service \
  -a "name=elevatediq"

# Verify application health
ansible web_servers -i inventories/prod.ini \
  -m uri \
  -a "url=http://localhost:8080/health"

# Collect system information
ansible all -i inventories/prod.ini -m setup
```

### 3. Post-Deployment Verification

#### Health Checks

```bash
# Database connectivity
ansible database_servers -i inventories/prod.ini \
  -m shell \
  -a "psql -U elevatediq -d elevatediq -c 'SELECT 1'"

# Application startup
ansible web_servers -i inventories/prod.ini \
  -m shell \
  -a "systemctl status elevatediq"

# Log verification
ansible web_servers -i inventories/prod.ini \
  -m shell \
  -a "tail -20 /var/log/elevatediq/application.log"

# Port accessibility
ansible localhost \
  -m uri \
  -a "url=https://prod.example.com/health"
```

#### Performance Baseline

```bash
# CPU and memory utilization
ansible all -i inventories/prod.ini \
  -m shell \
  -a "free -h && lscpu"

# Disk I/O performance
ansible all -i inventories/prod.ini \
  -m shell \
  -a "fio --name=randread-test --ioengine=libaio --iodepth=16"

# Network throughput
ansible all -i inventories/prod.ini \
  -m shell \
  -a "iperf3 -c <target> -t 30"
```

#### Security Verification

```bash
# Verify hardening
ansible all -i inventories/prod.ini \
  -m shell \
  -a "audit2allow -a | head -20"

# Check firewall rules
ansible all -i inventories/prod.ini \
  -m shell \
  -a "sudo ufw status"

# Verify failed login attempts
ansible all -i inventories/prod.ini \
  -m shell \
  -a "sudo grep 'Failed password' /var/log/auth.log | wc -l"
```

### 4. Monitoring and Alerting Setup

```bash
# Deploy monitoring agent
ansible all -i inventories/prod.ini \
  -m ansible.builtin.package \
  -a "name=prometheus-node-exporter state=present"

# Configure monitoring dashboards
# (via Prometheus/Grafana UI or Ansible playbooks)

# Set up alerting thresholds
# Example: CPU > 80%, Memory > 90%, Disk > 85%
```

## Rollback Procedures

### Planned Rollback

If issues detected post-deployment:

```bash
# Option 1: Redeploy previous version
VERSION=v1.2.2 ENV=prod make image-build deploy

# Option 2: Restore from previous infrastructure
# Keeping terraform state backed up
cd infrastructure/terraform
terraform state push backup/prod-20240208.tfstate
terraform apply -var-file=../../vars/prod.tfvars
```

### Emergency Rollback

```bash
# Immediate instance termination
openstack server delete <instance-id>

# Revert to previous golden image
openstack server create \
  --image Golden-Image-Ubuntu-20.04-v1.2.2 \
  --flavor m1.xlarge \
  --key-name prod-key \
  <server-name>

# Restore database from backup
mysql -u root < /backups/elevatediq-prod-20240208.sql
```

## Deployment Environments Configuration

### Development Variables

File: `vars/dev.tfvars`

```hcl
environment       = "dev"
instance_count    = 1
instance_flavor   = "m1.small"
image_name        = "Golden-Image-Ubuntu-20.04-dev"
enable_monitoring = false
enable_backup     = false
```

### Staging Variables

File: `vars/staging.tfvars`

```hcl
environment       = "staging"
instance_count    = 2
instance_flavor   = "m1.large"
image_name        = "Golden-Image-Ubuntu-20.04-staging"
enable_monitoring = true
enable_backup     = true
backup_retention  = 7
```

### Production Variables

File: `vars/prod.tfvars`

```hcl
environment       = "production"
instance_count    = 3
instance_flavor   = "m1.xlarge"
image_name        = "Golden-Image-Ubuntu-20.04-v1.2.3"
enable_monitoring = true
enable_backup     = true
backup_retention  = 30
enable_ha         = true
```

## Network Configuration

### Firewall Rules

Ensure these rules are configured:

```
Inbound:
  - SSH: 22 (from admin networks only)
  - HTTP: 80 (from load balancers)
  - HTTPS: 443 (from load balancers)
  - Application: 8080 (from internal networks)

Outbound:
  - All (or restricted to required destinations)
```

### DNS Configuration

```bash
# Add DNS records for all instances
prod1.example.com -> 192.168.1.10
prod2.example.com -> 192.168.1.11
prod3.example.com -> 192.168.1.12

# Load balancer
prod.example.com -> <VIP>
```

## Monitoring and Logging

### Logs to Review

```bash
# Application logs
/var/log/elevatediq/application.log

# System logs
/var/log/syslog
/var/log/auth.log

# Ansible deployment logs
/var/log/ansible.log
```

### Key Metrics to Monitor

- CPU utilization
- Memory usage
- Disk I/O
- Network throughput
- Application response time
- Error rates
- Failed authentication attempts

## Post-Deployment Documentation

After successful deployment:

1. **Update Deployment Records**
   - Date and time
   - Version deployed
   - Deployed by (user)
   - Approval from (manager)
   - Changes from previous version

2. **Update Network Documentation**
   - IP addresses assigned
   - Hostname mappings
   - Security group configurations
   - Firewall rules

3. **Update Monitoring**
   - Configure dashboards
   - Set alert thresholds
   - Configure log aggregation

4. **Team Notification**
   - Deployment completion announcement
   - Known issues or limitations
   - Rollback procedures if needed

## Troubleshooting Deployment Issues

### Instance Creation Failures

```bash
# Check quota
openstack quota show

# Check available flavors
openstack flavor list

# Check image availability
openstack image list | grep Golden

# Check network availability
openstack network list
```

### Ansible Execution Issues

```bash
# Verify SSH connectivity
ansible all -i inventories/prod.ini -m ping

# Check Python availability
ansible all -i inventories/prod.ini -m setup

# Enable verbose logging
ansible-playbook playbooks/main.yml \
  -i inventories/prod.ini \
  -vvv
```

### Application Startup Issues

```bash
# Check service status
systemctl status elevatediq

# View service logs
journalctl -u elevatediq -n 100 -f

# Manual startup for debugging
/opt/elevatediq/bin/start.sh

# Check configuration
cat /etc/elevatediq/config.yml
```

## Success Criteria

Deployment is successful when:

- [ ] All instances created and accessible
- [ ] All services started and responding
- [ ] Application health checks passing
- [ ] Monitoring and alerting operational
- [ ] Security scan results acceptable
- [ ] Performance meets baseline expectations
- [ ] Team notified of changes
- [ ] Documentation updated
