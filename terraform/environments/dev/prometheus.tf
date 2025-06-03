# ====================================================
# [OBSERVABILITY PILLAR] AWS Managed Prometheus
# ====================================================
# Purpose: Managed Prometheus workspace for metrics collection
# Benefit: Scalable metrics storage and querying
# Three Pillars Role: Metrics foundation for monitoring
# Learning Value: Shows enterprise metrics architecture

# terraform/environments/dev/prometheus.tf

# Local variables for Prometheus configuration
locals {
  prometheus_config = {
    name_prefix = "lakehouse-prometheus-${random_id.bucket_suffix.hex}"
    tags = {
      Name        = "lakehouse-prometheus"
      Purpose     = "self-healing-lakehouse"
      Environment = var.environment
      Component   = "observability"
      Pillar      = "observability"
    }
  }
}

# ===== PROMETHEUS WORKSPACE =====
# Only create Prometheus workspace in production
resource "aws_prometheus_workspace" "main" {
  count = var.environment == "prod" ? 1 : 0
  alias = local.prometheus_config.name_prefix

  logging_configuration {
    log_group_arn = "${aws_cloudwatch_log_group.prometheus[0].arn}:*"
  }

  tags = local.prometheus_config.tags
}

# ===== CLOUDWATCH LOG GROUP =====
resource "aws_cloudwatch_log_group" "prometheus" {
  count             = var.environment == "prod" ? 1 : 0
  name              = "/aws/prometheus/${local.prometheus_config.name_prefix}"
  retention_in_days = 7

  tags = local.prometheus_config.tags
}

# ===== OUTPUTS =====
output "prometheus_info" {
  description = "Prometheus workspace information"
  value = {
    endpoint     = try(aws_prometheus_workspace.main[0].prometheus_endpoint, "not_enabled_in_dev")
    workspace_id = try(aws_prometheus_workspace.main[0].id, "not_enabled_in_dev")
    log_group    = try(aws_cloudwatch_log_group.prometheus[0].name, "not_enabled_in_dev")
    console_url  = "https://console.aws.amazon.com/prometheus/home?region=${var.aws_region}#/workspaces"
    status       = var.environment == "prod" ? "enabled" : "disabled_in_dev"
  }
}