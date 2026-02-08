# Security Module Outputs

output "default_security_group_id" {
  description = "ID of the default security group"
  value       = openstack_networking_secgroup_v2.default.id
}

output "application_security_group_id" {
  description = "ID of the application security group"
  value       = openstack_networking_secgroup_v2.application.id
}

output "security_group_ids" {
  description = "Map of all security group IDs"
  value = {
    default     = openstack_networking_secgroup_v2.default.id
    application = openstack_networking_secgroup_v2.application.id
  }
}
