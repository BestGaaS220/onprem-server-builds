# Network Module - OpenStack Network Resources
# Manages VPC, subnets, routers, and network connectivity

terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.0"
    }
  }
}

# Network (Virtual Private Cloud)
resource "openstack_networking_network_v2" "main" {
  name            = "${var.project_name}-${var.environment}-network"
  admin_state_up  = true
  port_security_enabled = true
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-network"
      Type = "network"
    }
  )
}

# Subnet
resource "openstack_networking_subnet_v2" "main" {
  name            = "${var.project_name}-${var.environment}-subnet"
  network_id      = openstack_networking_network_v2.main.id
  cidr            = var.subnet_cidr
  ip_version      = 4
  dns_nameservers = var.dns_servers
  
  enable_dhcp      = true
  gateway_ip       = cidrhost(var.subnet_cidr, 1)
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-subnet"
      Type = "subnet"
    }
  )
}

# Router
resource "openstack_networking_router_v2" "main" {
  name            = "${var.project_name}-${var.environment}-router"
  admin_state_up  = true
  external_gateway_info {
    network_id = data.openstack_networking_network_v2.external.id
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-router"
      Type = "router"
    }
  )
}

# Router Interface (connect subnet to router)
resource "openstack_networking_router_interface_v2" "main" {
  router_id = openstack_networking_router_v2.main.id
  subnet_id = openstack_networking_subnet_v2.main.id
}

# Data source for external network
data "openstack_networking_network_v2" "external" {
  name           = var.external_network
  external       = true
  admin_state_up = true
}

# Output network information
locals {
  network_config = {
    network_id    = openstack_networking_network_v2.main.id
    subnet_id     = openstack_networking_subnet_v2.main.id
    router_id     = openstack_networking_router_v2.main.id
    cidr          = var.subnet_cidr
    gateway_ip    = cidrhost(var.subnet_cidr, 1)
  }
}
