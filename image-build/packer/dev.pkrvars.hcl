# Development Environment Packer Variables
# Used for local development and testing golden image builds

# OpenStack Credentials (Set via GitHub Secrets or environment variables)
os_auth_url = ""    # OPENSTACK_AUTH_URL
os_username = ""    # OPENSTACK_USERNAME
os_password = ""    # OPENSTACK_PASSWORD
os_project  = "dev-project"
os_region   = "RegionOne"

# Source Image Configuration
source_image = "Ubuntu 20.04 LTS"

# Golden Image Output Configuration
image_name   = "golden-image-elevatediq-dev"
version      = "dev"
environment  = "dev"

# Instance Configuration for Build
flavor_name = "m1.large"
network     = "dev-network"

# SSH Configuration
ssh_username = "ubuntu"
ssh_timeout  = "10m"
