# Staging Environment Terraform Variables
# Used for pre-production validation and testing

# OpenStack Configuration
os_auth_url  = "https://openstack.example.com:5000/v3"
os_username  = ""  # Set via environment variable or GitHub Secret
os_password  = ""  # Set via environment variable or GitHub Secret
os_project_name = "staging-project"
os_region    = "RegionOne"

# Environment
environment  = "staging"
project_name = "elevatediq"

# Networking
network_name      = "staging-network"
subnet_cidr       = "10.0.2.0/24"
external_network  = "external"

# Instance Configuration (Higher availability for testing)
instance_count   = 2
instance_flavor  = "m1.xlarge"
instance_name    = "elevatediq-staging"
key_pair_name    = "staging-key"
ssh_user         = "ubuntu"

# Storage
volume_size      = 100  # GB
volume_type      = "ssd"

# Tags
tags = {
  Environment         = "staging"
  Project            = "elevatediq"
  ManagedBy          = "Terraform"
  CreatedAt          = "2026-02-08"
  CostCenter         = "engineering"
  DataClassification = "confidential"
}

# Security
security_group_names = ["default", "elevatediq-staging"]
enable_security_group_rules = true

# Monitoring
enable_monitoring = true
monitoring_interval = 30
