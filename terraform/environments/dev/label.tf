# ====================================================
# [ENTERPRISE] Cloud Posse Label System
# ====================================================
# Purpose: Consistent naming and tagging across all resources
# Benefit: Enterprise-grade resource management and cost tracking
# Three Pillars Role: Foundation for all infrastructure components
# Learning Value: Shows enterprise naming conventions and automation

# terraform/environments/dev/label.tf

# ===== CLOUD POSSE LABEL MODULE =====
module "label" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"

  # Core naming components
  namespace   = "self-healing"
  environment = var.environment # "dev" 
  name        = "lakehouse"

  # Consistent delimiter
  delimiter = "-"

  # Enterprise tags
  tags = {
    Project      = "self-healing-lakehouse"
    Owner        = "data-engineering"
    BusinessUnit = "analytics"
    CostCenter   = "data-platform"
    Architecture = "three-pillars"
    IaC          = "terraform"
    Repository   = "self-healing-lakehouse"
  }
}

# ===== PILLAR-SPECIFIC LABELS =====

# CODE Pillar Label
module "code_label" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"

  attributes = ["code"]

  tags = {
    Pillar    = "code"
    Component = "infrastructure"
  }

  context = module.label.context
}

# OBSERVABILITY Pillar Label  
module "observability_label" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"

  attributes = ["observability"]

  tags = {
    Pillar    = "observability"
    Component = "monitoring"
  }

  context = module.label.context
}

# GUARD Pillar Label
module "guard_label" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"

  attributes = ["guard"]

  tags = {
    Pillar    = "guard"
    Component = "automation"
  }

  context = module.label.context
}

# ===== COMPONENT-SPECIFIC LABELS =====

# Storage Label (S3, RDS)
module "storage_label" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"

  attributes = ["storage"]

  tags = {
    Tier = "data"
  }

  context = module.code_label.context
}

# Processing Label (Glue)
module "processing_label" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"

  attributes = ["processing"]

  tags = {
    Tier = "compute"
  }

  context = module.code_label.context
}

# Monitoring Label (Grafana, Prometheus, CloudWatch) - AWS Limits Optimized
module "monitoring_label" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"

  attributes = ["grafana"]

  tags = {
    Tier = "observability"
  }

  # Direct connection to base label (skip observability layer)
  context = module.label.context
}

# ===== OUTPUTS =====
output "label_info" {
  description = "Cloud Posse label system information"
  value = {
    # Main label outputs
    id                   = module.label.id
    name                 = module.label.name
    namespace            = module.label.namespace
    environment          = module.label.environment
    tags                 = module.label.tags
    tags_as_list_of_maps = module.label.tags_as_list_of_maps

    # Pillar-specific IDs
    code_id          = module.code_label.id
    observability_id = module.observability_label.id
    guard_id         = module.guard_label.id

    # Component-specific IDs
    storage_id    = module.storage_label.id
    processing_id = module.processing_label.id
    monitoring_id = module.monitoring_label.id

    # Usage examples
    examples = {
      s3_bucket_name = module.storage_label.id
      glue_job_name  = module.processing_label.id
      grafana_name   = module.monitoring_label.id
    }
  }
}