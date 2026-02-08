# Production Environment Variables
environment            = "production"
instance_count         = 3
instance_flavor        = "m1.xlarge"
image_name             = "Golden-Image-Ubuntu-20.04"
instance_name_prefix   = "prod-elevatediq"

# Networking
subnet_cidr         = "10.30.0.0/24"
allowed_ssh_cidr    = ["10.0.0.0/8"]
allowed_app_cidr    = ["0.0.0.0/0"]

# Features
enable_monitoring  = true
enable_backup      = true
backup_retention_days = 30
enable_ha          = true

# Storage
volume_size = 100
monitoring_agent = "prometheus"

# High Availability
tags = {
  ManagedBy   = "Terraform"
  Module      = "Golden-Image"
  CostCenter  = "Enterprise"
  Environment = "Production"
  SLA         = "99.99%"
}
