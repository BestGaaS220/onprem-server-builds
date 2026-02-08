# Development Environment Variables
environment            = "dev"
instance_count         = 1
instance_flavor        = "m1.small"
image_name             = "Golden-Image-Ubuntu-20.04-dev"
instance_name_prefix   = "dev-elevatediq"

# Networking
subnet_cidr         = "10.10.0.0/24"
allowed_ssh_cidr    = ["10.0.0.0/8"]
allowed_app_cidr    = ["10.0.0.0/8"]

# Features
enable_monitoring = false
enable_backup     = false
enable_ha         = false

# Storage
volume_size = 30
