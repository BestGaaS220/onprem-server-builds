# Compute Module Outputs

output "instance_ids" {
  description = "IDs of created instances"
  value       = openstack_compute_instance_v2.main[*].id
}

output "instance_names" {
  description = "Names of created instances"
  value       = openstack_compute_instance_v2.main[*].name
}

output "instance_fixed_ips" {
  description = "Fixed IP addresses of instances"
  value       = [for instance in openstack_compute_instance_v2.main : instance.network[0].fixed_ip_v4]
}

output "instance_floating_ips" {
  description = "Floating IP addresses of instances"
  value       = var.enable_floating_ips ? openstack_compute_floatingip_v2.main[*].address : []
}

output "key_pair_name" {
  description = "Name of the SSH key pair"
  value       = openstack_compute_keypair_v2.main.name
}

output "instances" {
  description = "Complete instance information"
  value = {
    for i, instance in openstack_compute_instance_v2.main : instance.name => {
      id        = instance.id
      fixed_ip  = instance.network[0].fixed_ip_v4
      floating_ip = var.enable_floating_ips ? openstack_compute_floatingip_v2.main[i].address : null
    }
  }
}
