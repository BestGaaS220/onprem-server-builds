# Compute Module - OpenStack Compute Resources
# Manages instances, key pairs, and floating IPs

terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.0"
    }
  }
}

# Key Pair for SSH access
resource "openstack_compute_keypair_v2" "main" {
  name       = "${var.project_name}-${var.environment}-key"
  public_key = var.public_key

  tags = [
    "${var.project_name}-${var.environment}",
    var.environment
  ]
}

# Compute Instances
resource "openstack_compute_instance_v2" "main" {
  count          = var.instance_count
  name           = "${var.project_name}-${var.environment}-instance-${count.index + 1}"
  flavor_name    = var.instance_flavor
  image_name     = var.image_name
  key_pair       = openstack_compute_keypair_v2.main.name
  security_groups = var.security_group_ids
  
  metadata = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-instance-${count.index + 1}"
      Index       = count.index
      Environment = var.environment
      CreatedBy   = "Terraform"
    }
  )

  network {
    uuid = var.network_id
  }

  depends_on = [openstack_compute_keypair_v2.main]

  lifecycle {
    create_before_destroy = true
    ignore_changes = [image_name]
  }
}

# Floating IPs for external access
resource "openstack_compute_floatingip_v2" "main" {
  count = var.enable_floating_ips ? var.instance_count : 0
  
  pool = var.external_network_name

  tags = [
    "${var.project_name}-${var.environment}",
    "floating-ip"
  ]
}

# Associate Floating IPs with instances
resource "openstack_compute_floatingip_associate_v2" "main" {
  count                = var.enable_floating_ips ? var.instance_count : 0
  floating_ip          = openstack_compute_floatingip_v2.main[count.index].address
  instance_id          = openstack_compute_instance_v2.main[count.index].id
  fixed_ip             = openstack_compute_instance_v2.main[count.index].network[0].fixed_ip_v4

  depends_on = [openstack_compute_floatingip_v2.main]
}
