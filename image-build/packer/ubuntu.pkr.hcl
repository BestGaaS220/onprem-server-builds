packer {
  required_version = ">= 1.8"
  
  required_plugins {
    openstack = {
      version = ">= 1.1"
      source  = "github.com/hashicorp/openstack"
    }
  }
}

source "openstack" "ubuntu_golden_image" {
  auth_url            = var.os_auth_url
  username            = var.os_username
  password            = var.os_password
  tenant_name         = var.os_project
  region              = var.os_region
  
  # Source image  
  source_image_name   = var.source_image
  
  # Instance configuration
  flavor               = var.flavor_name
  network              = var.network
  
  # Image configuration
  image_name           = "${var.image_name}-${var.version}"
  image_visibility     = "private"
  image_disk_format    = "qcow2"
  
  # SSH configuration
  ssh_username        = var.ssh_username
  ssh_timeout         = var.ssh_timeout
  
  # Metadata
  metadata = {
    Version     = var.version
    Environment = var.environment
    BuildDate   = timestamp()
  }
  
  # Timeout settings
  timeout = "1h"
  
  # Cleanup
  use_floating_ip = false
}

build {
  name = "golden-image-${var.environment}"
  
  sources = [
    "source.openstack.ubuntu_golden_image"
  ]
  
  # Wait for system to be ready
  provisioner "shell" {
    inline = [
      "cloud-init status --wait",
      "sleep 10"
    ]
  }
  
  # Update system packages
  provisioner "shell" {
    script = "${path.root}/../shell/update-system.sh"
  }
  
  # Install base packages
  provisioner "shell" {
    script = "${path.root}/../shell/install-packages.sh"
  }
  
  # Configure security
  provisioner "shell" {
    script = "${path.root}/../shell/configure-security.sh"
  }
  
  # Apply Ansible configuration
  provisioner "ansible-local" {
    playbook_file = "${path.root}/../../infrastructure/ansible/playbooks/main.yml"
    
    # Ensure Ansible is available
    command = "ansible-playbook"
    
    # Increase timeout
    extra_arguments = [
      "--timeout=300"
    ]
  }
  
  # Cleanup for image optimization
  provisioner "shell" {
    inline = [
      "echo 'Cleaning up for image optimization...'",
      "sudo apt-get autoremove -y",
      "sudo apt-get clean -y",
      "sudo rm -rf /tmp/*",
      "sudo rm -rf /var/lib/apt/lists/*",
      "sudo fstrim -v /"
    ]
  }
  
  # Run final validation
  provisioner "shell" {
    script = "${path.root}/../shell/validate-image.sh"
  }
  
  # Post-processor for image optimization
  post-processor "manifest" {
    output = "manifest.json"
    strip_path = true
  }
}
