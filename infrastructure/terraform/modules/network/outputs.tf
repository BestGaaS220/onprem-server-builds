# Network Module Outputs

output "network_id" {
  description = "ID of the created network"
  value       = openstack_networking_network_v2.main.id
}

output "network_name" {
  description = "Name of the created network"
  value       = openstack_networking_network_v2.main.name
}

output "subnet_id" {
  description = "ID of the created subnet"
  value       = openstack_networking_subnet_v2.main.id
}

output "subnet_cidr" {
  description = "CIDR block of the subnet"
  value       = openstack_networking_subnet_v2.main.cidr
}

output "subnet_gateway_ip" {
  description = "Gateway IP address of the subnet"
  value       = openstack_networking_subnet_v2.main.gateway_ip
}

output "router_id" {
  description = "ID of the main router"
  value       = openstack_networking_router_v2.main.id
}

output "network_config" {
  description = "Complete network configuration"
  value       = local.network_config
}
