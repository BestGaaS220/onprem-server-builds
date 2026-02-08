# Storage Module - OpenStack Block Storage Resources
# Manages volumes, snapshots, and volume attachments

terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.0"
    }
  }
}

# Block Storage Volume
resource "openstack_blockstorage_volume_v3" "main" {
  count             = var.enable_volumes ? var.volume_count : 0
  name              = "${var.project_name}-${var.environment}-volume-${count.index + 1}"
  size              = var.volume_size
  volume_type       = var.volume_type
  availability_zone = var.availability_zone
  description       = "Storage volume for ${var.project_name}"
  
  metadata = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-volume-${count.index + 1}"
      Environment = var.environment
      CreatedBy   = "Terraform"
    }
  )

  lifecycle {
    prevent_destroy = true  # Protect volumes from accidental deletion
  }
}

# Volume Attachment to Instances
resource "openstack_compute_volume_attach_v2" "main" {
  count       = var.enable_volumes ? var.volume_count : 0
  instance_id = var.instance_ids[count.index % length(var.instance_ids)]
  volume_id   = openstack_blockstorage_volume_v3.main[count.index].id
}

# Volume Snapshot for backup
resource "openstack_blockstorage_volume_v3" "snapshot_base" {
  count             = var.enable_snapshots ? 1 : 0
  name              = "${var.project_name}-${var.environment}-snapshot-base"
  size              = 2
  description       = "Snapshot base volume"
  availability_zone = var.availability_zone
  
  lifecycle {
    prevent_destroy = true
  }
}

# Volume backup configuration
locals {
  backup_config = {
    enabled              = var.enable_backups
    retention_days       = var.backup_retention_days
    schedule             = var.backup_schedule
  }
}
