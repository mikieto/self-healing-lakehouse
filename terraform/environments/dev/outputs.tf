# ================================================
# [THREE PILLARS] Infrastructure Configuration
# ================================================
# Purpose: Support Technical Survival Strategy three pillars implementation
# Learning Value: Shows enterprise-level infrastructure configuration
# terraform/environments/dev/outputs.tf
# Output values for infrastructure components (DRY principle applied)
locals {
  # Common references to avoid repetition
  bucket_id = module.lakehouse_storage.s3_bucket_id
  bucket_arn = module.lakehouse_storage.s3_bucket_arn
  grafana_endpoint = aws_grafana_workspace.main.endpoint
  prometheus_endpoint = aws_prometheus_workspace.main.prometheus_endpoint
}
# === CORE INFRASTRUCTURE ===
output "data_lake_bucket_name" {
  description = "Name of the data lake S3 bucket"
  value       = local.bucket_id
}
output "data_lake_bucket_arn" {
  description = "ARN of the data lake S3 bucket"
  value       = local.bucket_arn
}
# === OBSERVABILITY ===
output "observability_endpoints" {
  description = "Monitoring and observability endpoints"
  value = {
    grafana    = local.grafana_endpoint
    prometheus = local.prometheus_endpoint
    dashboard  = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=SelfHealingLakehouseDashboard"
  }
}
# === DATA PROCESSING ===
output "data_processing" {
  description = "Data processing components"
  value = {
    database = aws_glue_catalog_database.main.name
    crawler  = aws_glue_crawler.main.name
    jobs = {
      data_quality = aws_glue_job.data_quality.name
      remediation  = aws_glue_job.remediation.name
    }
  }
}
# === AUTOMATION ===
output "automation" {
  description = "Self-healing automation components"
  value = {
    eventbridge_rule = module.self_healing_eventbridge.eventbridge_rule_arns["new_data_uploaded"]
    sns_topic       = module.healing_alerts_sns.topic_arn
  }
}
# === QUICK START GUIDE ===
output "quick_start" {
  description = "Quick start information"
  value = "Self-Healing Lakehouse deployed. Check AWS console for resources."
}
# === TECHNICAL DETAILS ===
output "architecture_info" {
  description = "Architecture and modules used"
  value = {
    official_modules = {
      s3_bucket   = "terraform-aws-modules/s3-bucket/aws ~> 4.0"
      sns         = "terraform-aws-modules/sns/aws ~> 6.0"
      eventbridge = "terraform-aws-modules/eventbridge/aws ~> 3.0"
    }
    architecture = {
      data_layer      = "S3 + Lake Formation + Glue Catalog"
      processing      = "Glue Crawler + Data Quality + Remediation Jobs"
      monitoring      = "Prometheus + Grafana + CloudWatch"
      automation      = "EventBridge + SNS + Bash Scripts"
      chaos_testing   = "S3 corruption injection + monitoring"
    }
    resource_count = 25  # Approximate after cleanup
  }
}
