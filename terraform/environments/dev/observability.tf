# ====================================================
# [OBSERVABILITY PILLAR] Real-time System Monitoring
# ====================================================
# Purpose: Comprehensive visibility into system health and performance
# Benefit: Immediate awareness of issues and system state changes
# Three Pillars Role: Early detection enables rapid response and recovery
# Learning Value: Shows production-ready monitoring patterns

# terraform/environments/dev/observability.tf

# Local variables for configuration
locals {
  observability_config = {
    name_prefix = "lakehouse-obs-${random_id.bucket_suffix.hex}"
    tags = {
      Name        = "lakehouse-observability"
      Purpose     = "self-healing-lakehouse"
      Environment = var.environment
    }
  }
}

# Only create Prometheus workspace in production
resource "aws_prometheus_workspace" "main" {
  count = var.environment == "prod" ? 1 : 0
  alias = local.observability_config.name_prefix

  logging_configuration {
    log_group_arn = "${aws_cloudwatch_log_group.prometheus[0].arn}:*"
  }

  tags = local.observability_config.tags
}

resource "aws_cloudwatch_log_group" "prometheus" {
  count             = var.environment == "prod" ? 1 : 0
  name              = "/aws/prometheus/${local.observability_config.name_prefix}"
  retention_in_days = 7

  tags = local.observability_config.tags
}

# ===== GRAFANA WORKSPACE =====
resource "aws_grafana_workspace" "main" {
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["SAML"]
  permission_type          = "SERVICE_MANAGED"
  role_arn                 = aws_iam_role.grafana.arn

  name        = local.observability_config.name_prefix
  description = "Self-Healing Lakehouse Observability Dashboard"

  # Essential data sources only
  data_sources = [
    "PROMETHEUS",
    "CLOUDWATCH"
  ]

  tags = local.observability_config.tags
}

# ===== IAM ROLES =====
resource "aws_iam_role" "grafana" {
  name = "${local.observability_config.name_prefix}-grafana-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "grafana.amazonaws.com"
        }
      }
    ]
  })

  tags = local.observability_config.tags
}

# Essential Grafana permissions
resource "aws_iam_role_policy_attachment" "grafana_cloudwatch" {
  role       = aws_iam_role.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonGrafanaCloudWatchAccess"
}

resource "aws_iam_role_policy_attachment" "grafana_prometheus" {
  role       = aws_iam_role.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess"
}

# ===== CLOUDWATCH DASHBOARDS =====
# Main Self-Healing Dashboard (keeps existing name)
resource "aws_cloudwatch_dashboard" "self_healing" {
  dashboard_name = "SelfHealingLakehouseDashboard"

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
          title  = "📊 Data Lake Objects Count"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Events", "MatchedEvents", "RuleName", "self-healing-rule"]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "⚡ Self-Healing Events Triggered"
        }
      }
    ]
  })
}

# Enhanced Dashboard for detailed monitoring
resource "aws_cloudwatch_dashboard" "self_healing_enhanced" {
  dashboard_name = "${local.observability_config.name_prefix}-detailed"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6

        properties = {
          metrics = [
            ["AWS/S3", "NumberOfObjects", "BucketName", module.lakehouse_storage.s3_bucket_id, "StorageType", "AllStorageTypes"],
            ["AWS/S3", "BucketSizeBytes", "BucketName", module.lakehouse_storage.s3_bucket_id, "StorageType", "StandardStorage"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "📊 Data Lake Metrics"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6

        properties = {
          metrics = [
            ["AWS/Glue", "glue.driver.aggregate.numCompletedStages", "JobName", aws_glue_job.data_quality.name],
            ["AWS/Glue", "glue.driver.aggregate.numFailedStages", "JobName", aws_glue_job.data_quality.name]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "🔧 Data Quality Jobs"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6

        properties = {
          metrics = [
            ["AWS/Events", "MatchedEvents", "RuleName", "new_data_uploaded"],
            ["AWS/Events", "SuccessfulInvocations", "RuleName", "new_data_uploaded"]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "⚡ EventBridge Activity"
        }
      }
    ]
  })
}

# ===== ESSENTIAL CLOUDWATCH ALARMS =====
# Data Quality Failure Alarm
resource "aws_cloudwatch_metric_alarm" "data_quality_failures" {
  alarm_name          = "${local.observability_config.name_prefix}-dq-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "glue.driver.aggregate.numFailedStages"
  namespace           = "AWS/Glue"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Data quality job failures detected"

  dimensions = {
    JobName = aws_glue_job.data_quality.name
  }

  alarm_actions = [module.healing_alerts_sns.topic_arn]
  ok_actions    = [module.healing_alerts_sns.topic_arn]

  tags = local.observability_config.tags
}

# S3 Data Lake Monitoring 
resource "aws_cloudwatch_metric_alarm" "s3_object_threshold" {
  alarm_name          = "${local.observability_config.name_prefix}-s3-data"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NumberOfObjects"
  namespace           = "AWS/S3"
  period              = "86400" # Daily check
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Data lake appears empty - potential issue"

  dimensions = {
    BucketName  = module.lakehouse_storage.s3_bucket_id
    StorageType = "AllStorageTypes"
  }

  alarm_actions = [module.healing_alerts_sns.topic_arn]

  tags = local.observability_config.tags
}

# ===== OUTPUTS =====
output "observability_enhanced" {
  description = "Balanced observability configuration"
  value = {
    grafana_workspace = {
      endpoint = aws_grafana_workspace.main.endpoint
      id       = aws_grafana_workspace.main.id
    }
    prometheus = {
      endpoint     = try(aws_prometheus_workspace.main[0].prometheus_endpoint, "not_enabled_in_dev")
      workspace_id = try(aws_prometheus_workspace.main[0].id, "not_enabled_in_dev")
    }
    dashboards = {
      main     = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=SelfHealingLakehouseDashboard"
      detailed = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.self_healing_enhanced.dashboard_name}"
    }
    alarms = {
      data_quality  = aws_cloudwatch_metric_alarm.data_quality_failures.arn
      s3_monitoring = aws_cloudwatch_metric_alarm.s3_object_threshold.arn
    }
  }
}