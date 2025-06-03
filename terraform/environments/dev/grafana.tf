# ====================================================
# [OBSERVABILITY PILLAR] AWS Managed Grafana - terraform-aws-modules
# ====================================================
# Purpose: Enterprise Grafana workspace with official modules
# Note: COMPLETELY DISABLED - SSO setup required
# Three Pillars Role: Real-time dashboards and monitoring
# Learning Value: Shows conditional resource creation

# terraform/environments/dev/grafana.tf

# ===== GRAFANA MODULE - COMPLETELY DISABLED =====
# AWS Managed Grafana requires AWS SSO setup
# Uncomment entire block when SSO is configured

# module "grafana" {
#   source  = "terraform-aws-modules/managed-service-grafana/aws"
#   version = "~> 2.0"
# 
#   # 🌩️ Cloud Posse naming integration
#   name = module.monitoring_label.id
# 
#   # Grafana workspace configuration
#   account_access_type      = "CURRENT_ACCOUNT"
#   authentication_providers = ["AWS_SSO"]
#   permission_type          = "SERVICE_MANAGED"
# 
#   # Essential data sources
#   data_sources = [
#     "CLOUDWATCH",
#     "PROMETHEUS"
#   ]
# 
#   # Notification destinations
#   notification_destinations = ["SNS"]
# 
#   # 🌩️ Cloud Posse tags
#   tags = module.monitoring_label.tags
# }

# ===== DEVELOPMENT ALTERNATIVE - CLOUDWATCH DASHBOARDS =====
# For development, use CloudWatch dashboards instead of Grafana

resource "aws_cloudwatch_dashboard" "dev_monitoring" {
  dashboard_name = "SelfHealingLakehouse-Dev-Dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/S3", "NumberOfObjects", "BucketName", module.lakehouse_storage.s3_bucket_id, "StorageType", "AllStorageTypes"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "📊 Data Lake Objects Count (Dev)"
        }
      },
      {
        type   = "text"
        x      = 0
        y      = 6
        width  = 24
        height = 3
        properties = {
          markdown = "## 🚀 Self-Healing Lakehouse Development Monitoring\n\n**Note**: Grafana requires AWS SSO setup. Using CloudWatch dashboards for development.\n\n**To enable Grafana**: Set up AWS SSO and uncomment module in grafana.tf"
        }
      }
    ]
  })
}

# ===== OUTPUTS - DISABLED GRAFANA =====
output "grafana_info" {
  description = "Grafana workspace information (DISABLED - SSO required)"
  value = {
    # All Grafana endpoints disabled
    endpoint = "DISABLED_SSO_REQUIRED"
    id       = "DISABLED_SSO_REQUIRED"
    arn      = "DISABLED_SSO_REQUIRED"
    role_arn = "DISABLED_SSO_REQUIRED"

    # Development alternative
    dev_dashboard = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=SelfHealingLakehouse-Dev-Dashboard"

    # URLs
    console_url = "https://console.aws.amazon.com/grafana/home?region=${var.aws_region}#/workspaces"

    # Status
    status = "COMPLETELY_DISABLED_SSO_REQUIRED"

    # Instructions
    enable_instructions = "1. Setup AWS SSO, 2. Uncomment module in grafana.tf, 3. terraform apply"

    # 🎯 Current approach
    features = {
      grafana_enabled  = false
      alternative      = "cloudwatch_dashboards"
      sso_requirement  = "aws_sso_setup_needed"
      current_solution = "cloudwatch_dashboard_created"
    }
  }
}