#!/bin/bash
# Output Terraform configurations

output "instance_ids" {
  description = "IDs of created instances"
  value       = try(openstack_compute_instance_v2.server[*].id, [])
}

output "instance_ips" {
  description = "Private IP addresses of created instances"
  value       = try(openstack_compute_instance_v2.server[*].access_ip_v4, [])
}

output "instance_hostnames" {
  description = "Hostnames of created instances"
  value       = try(openstack_compute_instance_v2.server[*].name, [])
}

output "network_id" {
  description = "ID of created network"
  value       = try(openstack_networking_network_v2.private.id, "")
}

output "subnet_id" {
  description = "ID of created subnet"
  value       = try(openstack_networking_subnet_v2.private_subnet.id, "")
}

output "security_group_id" {
  description = "ID of security group"
  value       = try(openstack_networking_secgroup_v2.web.id, "")
}
