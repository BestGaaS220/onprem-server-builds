# Storage Module Variables

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, production)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "enable_volumes" {
  description = "Enable block storage volumes"
  type        = bool
  default     = true
}

variable "volume_count" {
  description = "Number of volumes to create"
  type        = number
  default     = 1
  validation {
    condition     = var.volume_count >= 0 && var.volume_count <= 10
    error_message = "Volume count must be between 0 and 10."
  }
}

variable "volume_size" {
  description = "Size of volumes in GB"
  type        = number
  default     = 50
  validation {
    condition     = var.volume_size >= 1 && var.volume_size <= 1000
    error_message = "Volume size must be between 1 and 1000 GB."
  }
}

variable "volume_type" {
  description = "Volume type (ssd, ceph, etc.)"
  type        = string
  default     = "ssd"
}

variable "availability_zone" {
  description = "Availability zone for volumes"
  type        = string
  default     = "nova"
}

variable "instance_ids" {
  description = "List of instance IDs to attach volumes to"
  type        = list(string)
  default     = []
}

variable "enable_snapshots" {
  description = "Enable volume snapshots"
  type        = bool
  default     = false
}

variable "enable_backups" {
  description = "Enable automated backups"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Backup retention in days"
  type        = number
  default     = 30
}

variable "backup_schedule" {
  description = "Backup schedule (cron)"
  type        = string
  default     = "0 2 * * *"  # Daily at 2 AM
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
