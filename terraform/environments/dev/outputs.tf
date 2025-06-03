# ================================================
# [THREE PILLARS] Infrastructure Configuration
# ================================================
# Purpose: Support Technical Survival Strategy three pillars implementation
# Learning Value: Shows enterprise-level infrastructure configuration
# terraform/environments/dev/outputs.tf
# Output values for infrastructure components (DRY principle applied)

locals {
  # Common references to avoid repetition
  bucket_id  = module.lakehouse_storage.s3_bucket_id
  bucket_arn = module.lakehouse_storage.s3_bucket_arn
  # Fixed: Use references from Cloud Posse modules
  # grafana_endpoint    = try(module.grafana.workspace_endpoint, "not_available")
  grafana_endpoint    = "DISABLED_SSO_REQUIRED"
  prometheus_endpoint = try(module.prometheus.prometheus_endpoint, "not_enabled_in_dev")
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
    sns_topic        = module.healing_alerts_sns.topic_arn
  }
}

# === QUICK START GUIDE ===
output "quick_start" {
  description = "Quick start information"
  value       = "Self-Healing Lakehouse deployed. Check AWS console for resources."
}

# === CONSOLE ACCESS (30秒の奇跡用) ===
output "console_access" {
  description = "Quick access URLs for immediate value demonstration"
  value = {
    s3_data_lake         = "https://s3.console.aws.amazon.com/s3/buckets/${local.bucket_id}"
    grafana_workspace    = local.grafana_endpoint
    prometheus_metrics   = local.prometheus_endpoint
    cloudwatch_dashboard = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=SelfHealingLakehouseDashboard"
    glue_jobs            = "https://console.aws.amazon.com/glue/home?region=${var.aws_region}#etl:tab=jobs"
    eventbridge_rules    = "https://console.aws.amazon.com/events/home?region=${var.aws_region}#/rules"
  }
}

# === SYSTEM ARCHITECTURE (Three Pillars) ===
output "system_architecture" {
  description = "Technical architecture details"
  value = {
    code_pillar = {
      s3_bucket     = local.bucket_id
      glue_database = aws_glue_catalog_database.main.name
      crawler       = aws_glue_crawler.main.name
    }
    observability_pillar = {
      cloudwatch_dashboard = "SelfHealingLakehouseDashboard"
      grafana_workspace    = local.grafana_endpoint
      prometheus           = local.prometheus_endpoint
    }
    guard_pillar = {
      data_quality_job       = aws_glue_job.data_quality.name
      eventbridge_automation = module.self_healing_eventbridge.eventbridge_rule_arns["new_data_uploaded"]
      sns_alerts             = module.healing_alerts_sns.topic_arn
    }
  }
}

# === HELP GUIDE ===
output "help_guide" {
  description = "Common issues and solutions"
  value = {
    upload_data = {
      description = "Upload sample data to trigger self-healing"
      command     = "aws s3 cp sample.csv s3://${local.bucket_id}/raw/"
    }
    monitor_jobs = {
      description = "Monitor Glue job execution"
      url         = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups"
    }
    check_alerts = {
      description = "Verify SNS notifications"
      url         = "https://console.aws.amazon.com/sns/v3/home?region=${var.aws_region}#/topics"
    }
    grafana_access = {
      description = "Access monitoring dashboard"
      endpoint    = local.grafana_endpoint
    }
    cost_monitoring = {
      description = "Monitor AWS costs"
      url         = "https://console.aws.amazon.com/billing/home#/bills"
      cleanup     = "Run 'terraform destroy' when done"
    }
  }
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
      data_layer    = "S3 + Lake Formation + Glue Catalog"
      processing    = "Glue Crawler + Data Quality + Remediation Jobs"
      monitoring    = "Prometheus + Grafana + CloudWatch"
      automation    = "EventBridge + SNS + Bash Scripts"
      chaos_testing = "S3 corruption injection + monitoring"
    }
    resource_count = 25 # Approximate after cleanup
  }
}

# Version management outputs
output "version_management" {
  description = "Version management information"
  value = {
    git_commit = var.git_commit_hash
    deployment_timestamp = var.deployment_timestamp
    deployed_by = var.deployed_by
    version_metadata_location = "s3://${module.lakehouse_storage.s3_bucket_id}/scripts/.versions.json"
    version_history_logs = "/aws/terraform/script-deployment"
  }
}