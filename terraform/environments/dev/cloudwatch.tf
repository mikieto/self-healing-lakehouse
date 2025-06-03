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

# Data Quality Trends Dashboard
resource "aws_cloudwatch_dashboard" "data_quality_trends" {
  dashboard_name = "SelfHealingLakehouse-DataQuality-Trends"

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
            ["SelfHealingLakehouse", "DataQualityScore", "JobName", aws_glue_job.data_quality.name, "Environment", "dev"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "📊 Data Quality Score Trend"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
          annotations = {
            horizontal = [
              {
                label = "Quality Threshold"
                value = 70
              }
            ]
          }
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
            ["SelfHealingLakehouse", "DataRowCount", "JobName", aws_glue_job.data_quality.name, "Environment", "dev"],
            [".", "NullValueCount", ".", ".", ".", "."],
            [".", "OutlierCount", ".", ".", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "📈 Data Volume & Quality Issues"
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
            ["SelfHealingLakehouse", "ProcessingTimeSeconds", "JobName", aws_glue_job.data_quality.name, "Environment", "dev"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "⏱️ Processing Performance"
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
            ["SelfHealingLakehouse", "JobStatus", "JobName", aws_glue_job.data_quality.name, "Environment", "dev"],
            [".", "QualityViolationCount", ".", ".", ".", "."],
            [".", "JobErrorCount", ".", ".", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "🚨 Job Status & Violations"
          annotations = {
            horizontal = [
              {
                label = "Success"
                value = 2
              },
              {
                label = "Warning"
                value = 1
              },
              {
                label = "Failure"
                value = 0
              }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/S3", "NumberOfObjects", "BucketName", module.lakehouse_storage.s3_bucket_id, "StorageType", "AllStorageTypes"],
            ["AWS/Events", "MatchedEvents", "RuleName", "new_data_uploaded"]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "🗄️ Data Lake Activity"
        }
      },
      {
        type   = "text"
        x      = 0
        y      = 12
        width  = 24
        height = 2

        properties = {
          markdown = "## 🎯 Data Quality Monitoring Dashboard\n\n**Phase 3.2.1 Implementation**: Real-time data quality trends with custom CloudWatch metrics. Quality score tracks data health over time, with automatic alerting when scores drop below 70%."
        }
      }
    ]
  })

}

# Enhanced metric alarms for data quality trends
resource "aws_cloudwatch_metric_alarm" "data_quality_score_low" {
  alarm_name          = "${local.cloudwatch_config.name_prefix}-quality-score-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DataQualityScore"
  namespace           = "SelfHealingLakehouse"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "Data quality score dropped below acceptable threshold"

  dimensions = {
    JobName     = aws_glue_job.data_quality.name
    Environment = "dev"
  }

  alarm_actions = [module.healing_alerts_sns.topic_arn]
  ok_actions    = [module.healing_alerts_sns.topic_arn]

  tags = local.cloudwatch_config.tags
}

resource "aws_cloudwatch_metric_alarm" "high_processing_time" {
  alarm_name          = "${local.cloudwatch_config.name_prefix}-slow-processing"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ProcessingTimeSeconds"
  namespace           = "SelfHealingLakehouse"
  period              = "300"
  statistic           = "Average"
  threshold           = "300" # 5 minutes
  alarm_description   = "Data processing taking longer than expected"

  dimensions = {
    JobName     = aws_glue_job.data_quality.name
    Environment = "dev"
  }

  alarm_actions = [module.healing_alerts_sns.topic_arn]

  tags = local.cloudwatch_config.tags
}