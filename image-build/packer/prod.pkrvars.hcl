# Production Environment Packer Variables
# Used for production golden image builds with enterprise standards

# OpenStack Credentials (Set via GitHub Secrets or environment variables)
os_auth_url = ""    # OPENSTACK_AUTH_URL
os_username = ""    # OPENSTACK_USERNAME
os_password = ""    # OPENSTACK_PASSWORD
os_project  = "production-project"
os_region   = "RegionOne"

# Source Image Configuration
source_image = "Ubuntu 20.04 LTS"

# Golden Image Output Configuration
image_name   = "golden-image-elevatediq-prod"
version      = ""  # Must be set via environment or command line for production builds
environment  = "production"

# Instance Configuration for Build
flavor_name = "m1.2xlarge"
network     = "prod-network"

# SSH Configuration
ssh_username = "ubuntu"
ssh_timeout  = "20m"
