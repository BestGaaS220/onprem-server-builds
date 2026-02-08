# Staging Environment Packer Variables
# Used for pre-production image builds and testing

# OpenStack Credentials (Set via GitHub Secrets or environment variables)
os_auth_url = ""    # OPENSTACK_AUTH_URL
os_username = ""    # OPENSTACK_USERNAME
os_password = ""    # OPENSTACK_PASSWORD
os_project  = "staging-project"
os_region   = "RegionOne"

# Source Image Configuration
source_image = "Ubuntu 20.04 LTS"

# Golden Image Output Configuration
image_name   = "golden-image-elevatediq-staging"
version      = "staging"
environment  = "staging"

# Instance Configuration for Build
flavor_name = "m1.xlarge"
network     = "staging-network"

# SSH Configuration
ssh_username = "ubuntu"
ssh_timeout  = "15m"
