# ====================================================
# [OBSERVABILITY PILLAR] AWS Managed Grafana - terraform-aws-modules
# ====================================================
# Purpose: Enterprise Grafana workspace with official modules
# Benefit: Proven stability + Cloud Posse naming
# Three Pillars Role: Real-time dashboards and monitoring
# Learning Value: Shows hybrid approach (official modules + Cloud Posse naming)

# terraform/environments/dev/grafana.tf

# ===== TERRAFORM-AWS-MODULES GRAFANA =====
module "grafana" {
  source  = "terraform-aws-modules/managed-service-grafana/aws"
  version = "~> 2.0"

  # 🌩️ Cloud Posse naming integration
  name = module.monitoring_label.id

  # Grafana workspace configuration
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"

  # Essential data sources
  data_sources = [
    "CLOUDWATCH",
    "PROMETHEUS"
  ]

  # Notification destinations
  notification_destinations = ["SNS"]

  # 🌩️ Cloud Posse tags
  tags = module.monitoring_label.tags
}

# ===== OUTPUTS =====
output "grafana_info" {
  description = "Terraform AWS Modules Grafana workspace information"
  value = {
    # Core Grafana info
    endpoint = module.grafana.workspace_endpoint
    id       = module.grafana.workspace_id
    arn      = module.grafana.workspace_arn
    
    # IAM role
    role_arn = module.grafana.workspace_iam_role_arn
    
    # URLs
    console_url = "https://console.aws.amazon.com/grafana/home?region=${var.aws_region}#/workspaces"
    
    # 🌩️ Cloud Posse naming
    name = module.monitoring_label.id
    tags = module.monitoring_label.tags
    
    # 🎯 Hybrid approach benefits
    features = {
      module_provider  = "terraform-aws-modules"
      naming_provider  = "cloudposse"
      stability        = "high"
      custom_code      = "minimal"
    }
  }
}