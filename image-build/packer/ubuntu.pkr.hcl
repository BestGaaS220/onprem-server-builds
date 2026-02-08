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
  image_name           = "${var.image_name}-${var.version}-${var.environment}"
  image_visibility     = "private"
  image_disk_format    = "qcow2"
  
  # SSH configuration
  ssh_username        = var.ssh_username
  ssh_timeout         = var.ssh_timeout
  ssh_wait_timeout    = "30m"
  ssh_clear_authorized_keys = true
  
  # Metadata and tags
  metadata = {
    Version     = var.version
    Environment = var.environment
    BuildDate   = timestamp()
    BuildTool   = "Packer"
    Project     = "elevatediq"
  }
  
  # Timeout settings
  timeout = "2h"
  
  # Instance settings
  use_floating_ip = false
  reuse_ips       = false
  
  # Volume protection
  skip_create_image = false
}

# Local variables for build configuration
locals {
  build_timestamp = timestamp()
  build_date      = regex_replace(local.build_timestamp, "[- TZ:]", "")
}

build {
  name = "golden-image-${var.environment}"
  
  sources = [
    "source.openstack.ubuntu_golden_image"
  ]
  
  ################################################################################
  # Phase 1: System Initialization & Readiness
  ################################################################################
  
  provisioner "shell" {
    inline = [
      "set -e",
      "echo '=== Waiting for cloud-init to complete ===' ",
      "cloud-init status --wait",
      "sleep 15",
      "echo '=== System ready ===' "
    ]
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]
  }
  
  ################################################################################
  # Phase 2: System Updates & Package Management
  ################################################################################
  
  provisioner "shell" {
    script = "${path.root}/../shell/update-system.sh"
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
      "PACKER_BUILD_NAME=${build.name}",
      "PACKER_VERSION=${var.version}"
    ]
  }
  
  provisioner "shell" {
    script = "${path.root}/../shell/install-packages.sh"
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
      "ENVIRONMENT=${var.environment}"
    ]
  }
  
  ################################################################################
  # Phase 3: Security Hardening
  ################################################################################
  
  provisioner "shell" {
    script = "${path.root}/../shell/configure-security.sh"
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
      "ENVIRONMENT=${var.environment}"
    ]
  }
  
  # Upload SSH configuration template (if needed)
  provisioner "file" {
    source      = "${path.root}/../templates/"
    destination = "/tmp/packer-templates"
    when        = "build"
  }
  
  ################################################################################
  # Phase 4: Configuration Management (Ansible)
  ################################################################################
  
  provisioner "ansible-local" {
    playbook_file      = "${path.root}/../../infrastructure/ansible/playbooks/main.yml"
    command            = "ansible-playbook"
    inventory_file     = "${path.root}/../../infrastructure/ansible/inventories/dev.ini"
    
    extra_arguments = [
      "--timeout=300",
      "-e", "environment=${var.environment}",
      "-e", "packer_build=true",
      "-v"  # Verbose output for debugging
    ]
    
    staging_directory  = "/tmp/packer-ansible"
  }
  
  ################################################################################
  # Phase 5: Image Validation
  ################################################################################
  
  provisioner "shell" {
    inline = [
      "echo '=== Running pre-optimization validation ===' ",
      "systemctl status ssh",
      "python3 --version",
      "echo '✓ Validation passed' "
    ]
  }
  
  ################################################################################
  # Phase 6: System Cleanup & Optimization
  ################################################################################
  
  provisioner "shell" {
    inline = [
      "set -e",
      "echo '=== Cleaning up for image optimization ===' ",
      "sudo apt-get update",
      "sudo apt-get autoremove -y",
      "sudo apt-get autoclean -y",
      "sudo apt-get clean -y",
      "sudo rm -rf /tmp/*",
      "sudo rm -rf /var/lib/apt/lists/*",
      "sudo rm -rf /var/tmp/*",
      "sudo rm -rf /var/cache/apt/*.bin",
      "sudo fstrim -v /",
      "echo '✓ Cleanup complete' "
    ]
  }
  
  # Clear SSH host keys (will be regenerated)
  provisioner "shell" {
    inline = [
      "echo '=== Clearing host keys for fresh generation ===' ",
      "sudo rm -f /etc/ssh/ssh_host_*",
      "echo '✓ Host keys cleared' "
    ]
  }
  
  # Clear cloud-init
  provisioner "shell" {
    inline = [
      "echo '=== Clearing cloud-init ===' ",
      "sudo cloud-init clean --logs --seed",
      "echo '✓ cloud-init cleared' "
    ]
  }
  
  ################################################################################
  # Phase 7: Final Validation & Image Generation
  ################################################################################
  
  # Final validation
  provisioner "shell" {
    script = "${path.root}/../shell/validate-image.sh"
    environment_vars = [
      "PACKER_VERSION=${var.version}",
      "ENVIRONMENT=${var.environment}",
      "BUILD_DATE=${local.build_timestamp}"
    ]
  }
  
  ################################################################################
  # Post-Processors
  ################################################################################
  
  # Generate manifest for tracking
  post-processor "manifest" {
    output = "manifest.json"
    strip_path = true
    
    custom_data = {
      version      = var.version
      environment  = var.environment
      build_date   = local.build_timestamp
      source_image = var.source_image
      flavor       = var.flavor_name
    }
  }
  
  # Compress image (optional, for distribution)
  post-processor "compress" {
    compression_level = 6
    output            = "{{.BuildName}}-{{timestamp}}.tar.gz"
    only              = []  # Disable by default
  }
}
