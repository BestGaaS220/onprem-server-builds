# Compute Module Variables

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

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "instance_flavor" {
  description = "OpenStack instance flavor name"
  type        = string
  default     = "m1.large"
}

variable "image_name" {
  description = "OpenStack image name"
  type        = string
  default     = "Ubuntu 20.04 LTS"
}

variable "public_key" {
  description = "Public SSH key for instance access"
  type        = string
  sensitive   = true
}

variable "network_id" {
  description = "Network ID for instances"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "enable_floating_ips" {
  description = "Enable floating IPs for external access"
  type        = bool
  default     = true
}

variable "external_network_name" {
  description = "External network name for floating IPs"
  type        = string
  default     = "external"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
