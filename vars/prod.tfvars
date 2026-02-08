# Production Environment Terraform Variables
# Used for production deployment with HA and disaster recovery

# OpenStack Configuration
os_auth_url  = "https://openstack.example.com:5000/v3"
os_username  = ""  # Set via environment variable or GitHub Secret
os_password  = ""  # Set via environment variable or GitHub Secret
os_project_name = "production-project"
os_region    = "RegionOne"

# Environment
environment  = "production"
project_name = "elevatediq"

# Networking (Multi-zone HA)
network_name      = "prod-network"
subnet_cidr       = "10.0.3.0/24"
external_network  = "external"

# Instance Configuration (High Availability)
instance_count   = 3
instance_flavor  = "m1.2xlarge"
instance_name    = "elevatediq-prod"
key_pair_name    = "prod-key"
ssh_user         = "ubuntu"

# Storage
volume_size      = 200  # GB
volume_type      = "ssd"

# Tags
tags = {
  Environment         = "production"
  Project            = "elevatediq"
  ManagedBy          = "Terraform"
  CreatedAt          = "2026-02-08"
  CostCenter         = "operations"
  DataClassification = "restricted"
  BackupRequired     = "true"
  DisasterRecovery   = "true"
}

# Security (Enhanced for production)
security_group_names = ["default", "elevatediq-prod", "elevatediq-prod-internal"]
enable_security_group_rules = true

# Monitoring (Real-time monitoring)
enable_monitoring = true
monitoring_interval = 10

# High Availability Settings
enable_load_balancing = true
enable_auto_scaling   = true
min_instances         = 3
max_instances         = 6

# Backup and Disaster Recovery
enable_backups = true
backup_retention_days = 30
enable_replication = true
