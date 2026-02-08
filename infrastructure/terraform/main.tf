# Terraform Main Configuration - OpenStack Infrastructure
# Orchestrates all modules for complete infrastructure deployment

# 1. Network Module - Create VPC, subnets, and routing
module "network" {
  source = "./modules/network"

  project_name     = var.project_name
  environment      = var.environment
  subnet_cidr      = var.subnet_cidr
  external_network = var.external_network
  dns_servers      = var.dns_servers
  tags             = var.tags
}

# 2. Security Module - Create security groups and firewall rules
module "security" {
  source = "./modules/security"

  project_name      = var.project_name
  environment       = var.environment
  ssh_allowed_cidr  = var.ssh_allowed_cidr
  app_allowed_cidr  = var.app_allowed_cidr
  app_ports         = var.app_ports
  tags              = var.tags
}

# 3. Compute Module - Create instances and key pairs
module "compute" {
  source = "./modules/compute"

  project_name           = var.project_name
  environment            = var.environment
  instance_count         = var.instance_count
  instance_flavor        = var.instance_flavor
  image_name             = var.image_name
  public_key             = var.public_key
  network_id             = module.network.network_id
  security_group_ids     = [module.security.default_security_group_id, module.security.application_security_group_id]
  enable_floating_ips    = var.enable_floating_ips
  external_network_name  = var.external_network
  tags                   = var.tags

  depends_on = [module.network, module.security]
}

# 4. Storage Module - Create and manage volumes
module "storage" {
  source = "./modules/storage"

  project_name          = var.project_name
  environment           = var.environment
  enable_volumes        = var.enable_volumes
  volume_count          = var.volume_count
  volume_size           = var.volume_size
  volume_type           = var.volume_type
  instance_ids          = module.compute.instance_ids
  enable_snapshots      = var.enable_snapshots
  enable_backups        = var.enable_backups
  backup_retention_days = var.backup_retention_days
  backup_schedule       = var.backup_schedule
  tags                  = var.tags

  depends_on = [module.compute]
}

# Locals for convenience
locals {
  infrastructure = {
    network    = module.network.network_config
    security   = module.security.security_group_ids
    compute    = module.compute.instances
    storage    = module.storage.volume_ids
  }
}
