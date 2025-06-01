# ====================================================
# [OBSERVABILITY PILLAR] Real-time System Monitoring
# ====================================================
# Purpose: Comprehensive visibility into system health and performance
# Benefit: Immediate awareness of issues and system state changes
# Three Pillars Role: Early detection enables rapid response and recovery
# Learning Value: Shows proactive monitoring and alerting implementation

# terraform/environments/dev/observability.tf
# Direct AWS resource implementation for Observability

# Amazon Managed Service for Prometheus workspace
resource "aws_prometheus_workspace" "main" {
  alias = "lakehouse-prometheus-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name    = "lakehouse-prometheus"
    Purpose = "self-healing-lakehouse"
  }
}

# Amazon Managed Grafana workspace
resource "aws_grafana_workspace" "main" {
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["SAML"]  # Changed from AWS_SSO to SAML
  permission_type          = "SERVICE_MANAGED"
  role_arn                = aws_iam_role.grafana.arn
  
  name        = "lakehouse-grafana-${random_id.bucket_suffix.hex}"
  description = "Self-Healing Lakehouse Observability"
  
  data_sources = ["PROMETHEUS", "CLOUDWATCH"]
  
  tags = {
    Name    = "lakehouse-grafana"
    Purpose = "self-healing-lakehouse"
  }
}

# IAM Role for Grafana service
resource "aws_iam_role" "grafana" {
  name = "lakehouse-grafana-role-${random_id.bucket_suffix.hex}"
  
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
  
  tags = {
    Name    = "lakehouse-grafana-role"
    Purpose = "self-healing-lakehouse"
  }
}

# CloudWatch access policy for Grafana
resource "aws_iam_role_policy_attachment" "grafana_cloudwatch" {
  role       = aws_iam_role.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonGrafanaCloudWatchAccess"
}

# Prometheus query access for Grafana
resource "aws_iam_role_policy_attachment" "grafana_prometheus" {
  role       = aws_iam_role.grafana.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess"
}

# CloudWatch Dashboard for self-healing monitoring (no tags supported)
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
          title  = "Data Lake Objects Count"
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
          title  = "Self-Healing Events Triggered"
        }
      }
    ]
  })
}