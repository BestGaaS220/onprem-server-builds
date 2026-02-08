# Security Module Variables

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

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed for SSH access"
  type        = string
  default     = "10.0.0.0/8"
  validation {
    condition     = can(cidrhost(var.ssh_allowed_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "app_allowed_cidr" {
  description = "CIDR block allowed for application ports"
  type        = string
  default     = "10.0.0.0/8"
}

variable "app_ports" {
  description = "Application ports to allow inbound"
  type        = list(number)
  default     = [80, 443]
  validation {
    condition = alltrue([
      for port in var.app_ports : port >= 1 && port <= 65535
    ])
    error_message = "Port numbers must be between 1 and 65535."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
