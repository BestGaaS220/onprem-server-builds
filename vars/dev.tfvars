# Development Environment Terraform Variables
# Used for local development and testing

# OpenStack Configuration
os_auth_url  = "https://openstack.example.com:5000/v3"
os_username  = ""  # Set via environment variable or GitHub Secret
os_password  = ""  # Set via environment variable or GitHub Secret
os_project_name = "dev-project"
os_region    = "RegionOne"

# Environment
environment  = "dev"
project_name = "elevatediq"

# Networking
network_name      = "dev-network"
subnet_cidr       = "10.0.1.0/24"
external_network  = "external"

# Instance Configuration
instance_count   = 1
instance_flavor  = "m1.large"
instance_name    = "elevatediq-dev"
key_pair_name    = "dev-key"
ssh_user         = "ubuntu"

# Storage
volume_size      = 50  # GB
volume_type      = "ssd"

# Tags
tags = {
  Environment         = "dev"
  Project            = "elevatediq"
  ManagedBy          = "Terraform"
  CreatedAt          = "2026-02-08"
  CostCenter         = "engineering"
  DataClassification = "internal"
}

# Security
security_group_names = ["default", "elevatediq-dev"]
enable_security_group_rules = true

# Monitoring
enable_monitoring = true
monitoring_interval = 60
