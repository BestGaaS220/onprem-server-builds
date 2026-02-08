# Terraform Outputs - Expose infrastructure components

################################################################################
# Network Outputs
################################################################################

output "network_id" {
  description = "ID of the created network"
  value       = module.network.network_id
  sensitive   = false
}

output "network_name" {
  description = "Name of the created network"
  value       = module.network.network_name
}

output "subnet_id" {
  description = "ID of the created subnet"
  value       = module.network.subnet_id
}

output "subnet_cidr" {
  description = "CIDR block of the subnet"
  value       = module.network.subnet_cidr
}

output "gateway_ip" {
  description = "Gateway IP of the subnet"
  value       = module.network.subnet_gateway_ip
}

output "router_id" {
  description = "ID of the main router"
  value       = module.network.router_id
}

################################################################################
# Security Outputs
################################################################################

output "security_group_ids" {
  description = "IDs of security groups"
  value       = module.security.security_group_ids
}

output "default_security_group_id" {
  description = "ID of default security group"
  value       = module.security.default_security_group_id
}

output "application_security_group_id" {
  description = "ID of application security group"
  value       = module.security.application_security_group_id
}

################################################################################
# Compute Outputs
################################################################################

output "instance_ids" {
  description = "IDs of created instances"
  value       = module.compute.instance_ids
}

output "instance_names" {
  description = "Names of created instances"
  value       = module.compute.instance_names
}

output "instance_fixed_ips" {
  description = "Private IP addresses of instances"
  value       = module.compute.instance_fixed_ips
}

output "instance_floating_ips" {
  description = "Floating (public) IP addresses of instances"
  value       = module.compute.instance_floating_ips
}

output "key_pair_name" {
  description = "Name of SSH key pair for instances"
  value       = module.compute.key_pair_name
}

output "instances" {
  description = "Complete instance information"
  value       = module.compute.instances
}

################################################################################
# Storage Outputs
################################################################################

output "volume_ids" {
  description = "IDs of created volumes"
  value       = module.storage.volume_ids
}

output "volume_attachments" {
  description = "Volume attachment information"
  value       = module.storage.volume_attachments
}

output "backup_config" {
  description = "Backup configuration settings"
  value       = module.storage.backup_config
}

################################################################################
# Summary Output
################################################################################

output "infrastructure_summary" {
  description = "Complete infrastructure summary"
  value = {
    environment      = var.environment
    project_name     = var.project_name
    network_config   = module.network.network_config
    security_groups  = module.security.security_group_ids
    instances        = module.compute.instances
    volumes          = module.storage.volume_ids
    region           = var.os_region
    created_at       = timestamp()
  }
}
