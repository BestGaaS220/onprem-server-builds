# Security Module - OpenStack Security Groups
# Manages firewall rules and security group enforcement

terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.0"
    }
  }
}

# Default Security Group
resource "openstack_networking_secgroup_v2" "default" {
  name        = "${var.project_name}-${var.environment}-default"
  description = "Default security group for ${var.project_name}"
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-default"
      Type = "security-group"
    }
  )
}

# Application Security Group
resource "openstack_networking_secgroup_v2" "application" {
  name        = "${var.project_name}-${var.environment}-app"
  description = "Application security group for ${var.project_name}"
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-app"
      Type = "security-group"
      Role = "application"
    }
  )
}

# SSH Rule (from allowed CIDR)
resource "openstack_networking_secgroup_rule_v2" "ssh_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.ssh_allowed_cidr
  security_group_id = openstack_networking_secgroup_v2.default.id
  description       = "SSH access"
}

# API/App Ports Rule
resource "openstack_networking_secgroup_rule_v2" "app_ingress" {
  for_each = toset(var.app_ports)
  
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = tonumber(each.value)
  port_range_max    = tonumber(each.value)
  remote_ip_prefix  = var.app_allowed_cidr
  security_group_id = openstack_networking_secgroup_v2.application.id
  description       = "Application port ${each.value}"
}

# Internal Communication Rule
resource "openstack_networking_secgroup_rule_v2" "internal" {
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_group_id   = openstack_networking_secgroup_v2.application.id
  security_group_id = openstack_networking_secgroup_v2.application.id
  description       = "Internal communication"
}

# Egress Rule (allow all outbound)
resource "openstack_networking_secgroup_rule_v2" "egress_all" {
  direction         = "egress"
  ethertype         = "IPv4"
  cidr              = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.application.id
  description       = "Allow all outbound"
}

# DNS Rule for system tasks
resource "openstack_networking_secgroup_rule_v2" "dns_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 53
  port_range_max    = 53
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.default.id
  description       = "DNS queries"
}
