# Common configuration and naming conventions
locals {
  # Environment-specific configuration
  environment_config = {
    dev = {
      enable_prometheus = false
      rds_multi_az      = false
      backup_retention  = 7
      instance_class    = "db.t3.micro"
    }
    staging = {
      enable_prometheus = false
      rds_multi_az      = true
      backup_retention  = 14
      instance_class    = "db.t3.small"
    }
    prod = {
      enable_prometheus = true
      rds_multi_az      = true
      backup_retention  = 30
      instance_class    = "db.t3.medium"
    }
  }

  # Current environment settings
  env_config = local.environment_config[var.environment]

  # Common naming convention
  name_prefix = "lakehouse-${random_id.bucket_suffix.hex}"

  # Common tags applied to all resources
  common_tags = {
    Project     = "self-healing-lakehouse"
    Environment = var.environment
    ManagedBy   = "terraform"
    Purpose     = "self-healing-lakehouse"
    CreatedBy   = "terraform-aws-modules"
  }

  # Resource-specific tag sets
  storage_tags = merge(local.common_tags, {
    Component = "data-storage"
    Pillar    = "code"
  })

  compute_tags = merge(local.common_tags, {
    Component = "data-processing"
    Pillar    = "code"
  })

  monitoring_tags = merge(local.common_tags, {
    Component = "observability"
    Pillar    = "observability"
  })

  security_tags = merge(local.common_tags, {
    Component = "automation"
    Pillar    = "guard"
  })
}