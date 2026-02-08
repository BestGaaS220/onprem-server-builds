# Storage Module Outputs

output "volume_ids" {
  description = "IDs of created volumes"
  value       = openstack_blockstorage_volume_v3.main[*].id
}

output "volume_attachments" {
  description = "Volume attachment information"
  value = {
    for i, attachment in openstack_compute_volume_attach_v2.main :
    i => {
      volume_id   = attachment.volume_id
      instance_id = attachment.instance_id
    }
  }
}

output "backup_config" {
  description = "Backup configuration"
  value       = local.backup_config
}
