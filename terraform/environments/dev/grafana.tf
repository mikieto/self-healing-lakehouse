# ====================================================
# [OBSERVABILITY PILLAR] AWS Managed Grafana
# ====================================================

# Local variables for Grafana configuration
locals {
  grafana_config = {
    name_prefix = "lakehouse-grafana-${random_id.bucket_suffix.hex}"
    tags = {
      Name        = "lakehouse-grafana"
      Purpose     = "self-healing-lakehouse"
      Environment = var.environment
      Component   = "observability"
      Pillar      = "observability"
    }
  }
}

# ===== GRAFANA WORKSPACE =====
resource "aws_grafana_workspace" "main" {
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["SAML"]
  permission_type          = "SERVICE_MANAGED"
  role_arn                 = aws_iam_role.grafana.arn

  name        = local.grafana_config.name_prefix
  description = "Self-Healing Lakehouse Observability Dashboard"

  data_sources = [
    "PROMETHEUS",
    "CLOUDWATCH"
  ]

  tags = local.grafana_config.tags
}

# ===== IAM ROLE FOR GRAFANA =====
resource "aws_iam_role" "grafana" {
  name = "${local.grafana_config.name_prefix}-role"

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

  tags = local.grafana_config.tags
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

# ===== OUTPUTS =====
output "grafana_info" {
  description = "Grafana workspace information"
  value = {
    endpoint    = aws_grafana_workspace.main.endpoint
    id          = aws_grafana_workspace.main.id
    role_arn    = aws_iam_role.grafana.arn
    console_url = "https://console.aws.amazon.com/grafana/home?region=${var.aws_region}#/workspaces"
  }
}