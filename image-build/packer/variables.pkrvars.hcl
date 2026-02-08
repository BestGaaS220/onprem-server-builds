# Packer Variables for Golden Image Build

variable "os_auth_url" {
  type        = string
  description = "OpenStack authentication URL"
  sensitive   = true
}

variable "os_username" {
  type        = string
  description = "OpenStack username"
  sensitive   = true
}

variable "os_password" {
  type        = string
  description = "OpenStack password"
  sensitive   = true
}

variable "os_project" {
  type        = string
  description = "OpenStack project name"
  default     = "admin"
}

variable "os_region" {
  type        = string
  description = "OpenStack region"
  default     = "RegionOne"
}

variable "source_image" {
  type        = string
  description = "Source image name"
  default     = "Ubuntu 20.04 LTS"
}

variable "image_name" {
  type        = string
  description = "Golden image name"
  default     = "Golden-Image-Ubuntu-20.04"
}

variable "version" {
  type        = string
  description = "Image version"
  default     = "dev"
  
  validation {
    condition     = can(regex("^(dev|v?[0-9]+(\\.[0-9]+)*|[0-9]+-[0-9]+-[0-9]{8})$", var.version))
    error_message = "Version must be 'dev', semantic version (v1.0.0), or timestamp (YYYYMMDD-HHMMSS)."
  }
}

variable "environment" {
  type        = string
  description = "Environment (dev, staging, production)"
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "flavor_name" {
  type        = string
  description = "OpenStack instance flavor"
  default     = "m1.large"
}

variable "network" {
  type        = string
  description = "OpenStack network name"
  default     = "private"
}

variable "ssh_username" {
  type        = string
  description = "SSH username for build instance"
  default     = "ubuntu"
}

variable "ssh_timeout" {
  type        = string
  description = "SSH timeout"
  default     = "10m"
}
