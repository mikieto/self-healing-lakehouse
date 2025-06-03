# ====================================================
# [OBSERVABILITY PILLAR] CloudWatch Monitoring
# ====================================================
# Purpose: CloudWatch dashboards and alarms for monitoring
# Benefit: AWS native monitoring with custom dashboards
# Three Pillars Role: Real-time alerting and visualization
# Learning Value: Shows CloudWatch integration patterns

# terraform/environments/dev/cloudwatch.tf

# Local variables for CloudWatch configuration
locals {
  cloudwatch_config = {
    name_prefix = "lakehouse-cw-${random_id.bucket_suffix.hex}"
    tags = {
      Name        = "lakehouse-cloudwatch"
      Purpose     = "self-healing-lakehouse"
      Environment = var.environment
      Component   = "observability"
      Pillar      = "observability"
    }
  }
}

# ===== CLOUDWATCH DASHBOARDS =====
# Main Self-Healing Dashboard (keeps existing name for compatibility)
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
  dashboard_name = "${local.cloudwatch_config.name_prefix}-detailed"

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

# ===== CLOUDWATCH METRIC ALARMS =====
# Data Quality Failure Alarm
resource "aws_cloudwatch_metric_alarm" "data_quality_failures" {
  alarm_name          = "${local.cloudwatch_config.name_prefix}-dq-failures"
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

  tags = local.cloudwatch_config.tags
}

# S3 Data Lake Monitoring 
resource "aws_cloudwatch_metric_alarm" "s3_object_threshold" {
  alarm_name          = "${local.cloudwatch_config.name_prefix}-s3-data"
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

  tags = local.cloudwatch_config.tags
}

# ===== OUTPUTS =====
output "cloudwatch_info" {
  description = "CloudWatch monitoring information"
  value = {
    dashboards = {
      main     = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=SelfHealingLakehouseDashboard"
      detailed = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.self_healing_enhanced.dashboard_name}"
    }
    alarms = {
      data_quality  = aws_cloudwatch_metric_alarm.data_quality_failures.arn
      s3_monitoring = aws_cloudwatch_metric_alarm.s3_object_threshold.arn
    }
    console_url = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:"
  }
}