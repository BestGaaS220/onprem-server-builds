# Staging Environment Variables
environment            = "staging"
instance_count         = 2
instance_flavor        = "m1.large"
image_name             = "Golden-Image-Ubuntu-20.04-staging"
instance_name_prefix   = "staging-elevatediq"

# Networking
subnet_cidr         = "10.20.0.0/24"
allowed_ssh_cidr    = ["10.0.0.0/8", "203.0.113.0/24"]
allowed_app_cidr    = ["10.0.0.0/8", "203.0.113.0/24"]

# Features
enable_monitoring  = true
enable_backup      = true
backup_retention_days = 7
enable_ha          = false

# Storage
volume_size = 50
monitoring_agent = "prometheus"
