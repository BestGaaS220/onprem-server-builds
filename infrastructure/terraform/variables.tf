# OpenStack Provider Variables
variable "os_auth_url" {
  description = "OpenStack authentication URL"
  type        = string
  sensitive   = true
}

variable "os_username" {
  description = "OpenStack username"
  type        = string
  sensitive   = true
}

variable "os_password" {
  description = "OpenStack password"
  type        = string
  sensitive   = true
}

variable "os_project_name" {
  description = "OpenStack project name"
  type        = string
}

variable "os_region" {
  description = "OpenStack region"
  type        = string
  default     = "RegionOne"
}

# Environment Variables
variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "elevatediq"
}

# Networking Variables
variable "network_name" {
  description = "Network name"
  type        = string
  default     = "private"
}

variable "subnet_cidr" {
  description = "Subnet CIDR block"
  type        = string
  default     = "10.0.0.0/24"
}

variable "external_network" {
  description = "External/public network name"
  type        = string
  default     = "external"
}

# Instance Variables
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
  description = "Golden image name"
  type        = string
  default     = "Golden-Image-Ubuntu-20.04"
}

variable "instance_name_prefix" {
  description = "Prefix for instance names"
  type        = string
  default     = "elevatediq-server"
}

# Storage Variables
variable "volume_size" {
  description = "Volume size in GB"
  type        = number
  default     = 50
  
  validation {
    condition     = var.volume_size >= 20 && var.volume_size <= 1000
    error_message = "Volume size must be between 20 and 1000 GB."
  }
}

variable "enable_backup" {
  description = "Enable automated backups"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

# Monitoring Variables
variable "enable_monitoring" {
  description = "Enable monitoring and observability"
  type        = bool
  default     = false
}

variable "monitoring_agent" {
  description = "Monitoring agent (prometheus, datadog, none)"
  type        = string
  default     = "prometheus"
  
  validation {
    condition     = contains(["prometheus", "datadog", "none"], var.monitoring_agent)
    error_message = "Monitoring agent must be prometheus, datadog, or none."
  }
}

# Security Variables
variable "enable_ha" {
  description = "Enable high availability"
  type        = bool
  default     = false
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_app_cidr" {
  description = "CIDR block allowed for application access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  
  default = {
    ManagedBy   = "Terraform"
    Module      = "Golden-Image"
    CostCenter  = "Engineering"
  }
}
