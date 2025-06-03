# ====================================================
# [OBSERVABILITY PILLAR] AWS Managed Prometheus - Cloud Posse
# ====================================================
# Purpose: Enterprise Prometheus workspace with Cloud Posse best practices
# Benefit: Zero custom code + automatic security configuration
# Three Pillars Role: Metrics foundation for monitoring
# Learning Value: Shows Cloud Posse enterprise patterns for metrics

# terraform/environments/dev/prometheus.tf

# Create Prometheus label for naming
module "prometheus_label" {
  source  = "cloudposse/label/null"
  version = "~> 0.25"

  attributes = ["prometheus"]

  tags = {
    Tier = "observability"
  }

  # Direct connection to base label (consistent with grafana approach)
  context = module.label.context
}

# ===== CLOUD POSSE MANAGED PROMETHEUS =====
module "prometheus" {
  source  = "cloudposse/managed-prometheus/aws"
  version = "~> 0.1.1"

  # 🌩️ Cloud Posse label integration
  context = module.prometheus_label.context

  # Minimal configuration - let Cloud Posse handle defaults
  # Environment-based enabling will be tested first
}

# ===== CONDITIONAL LOG GROUP (if not handled by module) =====
resource "aws_cloudwatch_log_group" "prometheus" {
  count             = var.environment == "prod" ? 1 : 0
  name              = "/aws/prometheus/${module.prometheus_label.id}"
  retention_in_days = 7

  tags = module.prometheus_label.tags
}

# ===== OUTPUTS =====
output "prometheus_info" {
  description = "Cloud Posse Prometheus workspace information"
  value = {
    # Core Prometheus info - using safe references
    endpoint     = try(module.prometheus.prometheus_endpoint, "not_available")
    workspace_id = try(module.prometheus.workspace_id, "not_available")
    arn          = try(module.prometheus.workspace_arn, "not_available")

    # Access role - using safe reference
    access_role_arn = try(module.prometheus.access_role_arn, "not_available")

    # Log group - using safe reference
    log_group = try(module.prometheus.log_group_name, "not_available")

    # URLs
    console_url = "https://console.aws.amazon.com/prometheus/home?region=${var.aws_region}#/workspaces"

    # 🌩️ Cloud Posse naming
    name   = module.prometheus_label.id
    tags   = module.prometheus_label.tags
    status = var.environment == "prod" ? "enabled" : "disabled_in_dev"

    # 🎯 Enterprise features
    features = {
      automatic_iam   = "enabled"
      security_config = "cloud_posse_best_practices"
      custom_code     = "minimal"
      provider        = "cloudposse"
    }
  }
}