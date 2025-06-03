# ================================================
# Bootstrap-Integrated Learner-Friendly Outputs
# ================================================
# terraform/environments/dev/outputs.tf

# ================================================
# Success Celebration
# ================================================
output "🎉_deployment_success" {
  description = "Congratulations! Your self-healing lakehouse is ready"
  value       = "✅ Self-Healing Lakehouse deployed successfully in ${var.aws_region} using S3 Native Locking!"
}

output "🏗️_bootstrap_integration" {
  description = "Bootstrap foundation information"
  value = {
    backend_type     = "S3 Native Locking (Terraform >= 1.6)"
    state_management = "Centralized S3 backend from bootstrap"
    cost_savings     = "~$0.25/month saved (no DynamoDB table needed)"
    github_actions   = "OIDC authentication configured via bootstrap"
  }
}

output "📊_your_lakehouse_details" {
  description = "Essential information about your deployed lakehouse"
  value = {
    project_name    = var.project_name
    environment     = var.environment
    region         = var.aws_region
    learning_preset = var.learning_preset
    data_bucket    = module.data_lake.s3_bucket_id
    bucket_region  = module.data_lake.s3_bucket_region
  }
}

# ================================================
# Quick Access Links
# ================================================
output "🔗_quick_links" {
  description = "Important AWS Console links to explore your lakehouse"
  value = {
    aws_console = "https://${var.aws_region}.console.aws.amazon.com/console/home?region=${var.aws_region}"
    s3_console  = "https://s3.console.aws.amazon.com/s3/buckets/${module.data_lake.s3_bucket_id}?region=${var.aws_region}"
    glue_console = var.processing_config.enable_crawler ? 
      "https://${var.aws_region}.console.aws.amazon.com/glue/home?region=${var.aws_region}#catalog:tab=crawlers" : 
      "Glue crawler not enabled"
    cloudwatch_console = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:"
    grafana_endpoint = var.features.enable_observability ? 
      try(module.grafana[0].workspace_endpoint, "Grafana workspace not ready yet") : 
      "Observability not enabled"
  }
}

# ================================================
# Learning Experiments
# ================================================
output "🧪_try_these_experiments" {
  description = "Hands-on experiments to learn how self-healing works"
  value = {
    upload_test_data = "aws s3 cp your-file.csv s3://${module.data_lake.s3_bucket_id}/raw/"
    view_s3_events = var.features.enable_self_healing ? 
      "Check EventBridge rules in AWS Console to see automation triggers" : 
      "Enable self_healing feature to see event automation"
    monitor_processing = var.processing_config.enable_crawler ? 
      "Watch Glue crawler discover your data schema automatically" : 
      "Enable crawler to see automatic schema discovery"
    check_notifications = var.features.enable_self_healing ? 
      "Check your email (${var.self_healing_config.notification_email}) for alerts" : 
      "Enable self_healing to receive email notifications"
  }
}

# ================================================
# Feature Status
# ================================================
output "⚙️_enabled_features" {
  description = "Current feature configuration status"
  value = {
    self_healing_enabled   = var.features.enable_self_healing ? "✅ Active" : "❌ Disabled"
    observability_enabled  = var.features.enable_observability ? "✅ Active" : "❌ Disabled"
    database_enabled      = var.features.enable_rds ? "✅ Active" : "❌ Disabled"
    chaos_testing_enabled = var.features.enable_chaos_testing ? "✅ Active" : "❌ Disabled"
    data_crawler_enabled  = var.processing_config.enable_crawler ? "✅ Active" : "❌ Disabled"
    data_quality_enabled  = var.processing_config.enable_data_quality ? "✅ Active" : "❌ Disabled"
  }
}

# ================================================
# Cost Information
# ================================================
output "💰_estimated_monthly_cost" {
  description = "Approximate monthly AWS costs for your current configuration"
  value = {
    base_infrastructure = "$5-10 (S3, Glue, CloudWatch basics)"
    observability_cost = var.features.enable_observability ? "$15-25 (Grafana workspace)" : "$0 (disabled)"
    database_cost = var.features.enable_rds ? "$15-30 (RDS PostgreSQL ${var.rds_config.instance_class})" : "$0 (disabled)"
    data_processing = var.processing_config.enable_data_quality ? "$5-15 (depends on data volume)" : "$0 (disabled)"
    total_estimate = var.features.enable_observability && var.features.enable_rds ? 
      "$40-80/month (all features enabled)" : 
      var.features.enable_observability ? "$25-50/month (with monitoring)" :
      "$10-25/month (basic setup)"
    cost_optimization_tip = "💡 Disable unused features in terraform.tfvars to reduce costs"
  }
}

# ================================================
# Next Steps Guide
# ================================================
output "🎯_learning_roadmap" {
  description = "Suggested next steps for your learning journey"
  value = {
    step_1_data_upload = "Upload sample CSV files to s3://${module.data_lake.s3_bucket_id}/raw/ and watch automation"
    step_2_feature_toggle = "Try changing feature flags in terraform.tfvars and run 'terraform apply'"
    step_3_monitoring = var.features.enable_observability ? 
      "Explore Grafana dashboards and CloudWatch metrics" : 
      "Enable observability features to see monitoring in action"
    step_4_scaling = "Try different worker_type and number_of_workers in processing_config"
    step_5_advanced = "Enable chaos_testing feature for advanced resilience experiments"
    step_6_enterprise = "Change learning_preset to 'enterprise' for production-ready configuration"
    step_7_bootstrap = "Review terraform/bootstrap/ to understand S3 Native Locking foundation"
  }
}

# ================================================
# Troubleshooting Resources
# ================================================
output "🔧_troubleshooting" {
  description = "Helpful commands and resources for troubleshooting"
  value = {
    check_resources = "terraform state list | grep -E '(bucket|glue|grafana)'"
    validate_config = "terraform validate && terraform plan"
    view_logs = "Check CloudWatch Logs for Glue job execution details"
    get_help = "Review README.md for detailed documentation and examples"
    cost_check = "Use AWS Cost Explorer to monitor actual spending"
    clean_up = "Run 'make clean' when finished learning to avoid ongoing costs"
  }
}

# ================================================
# Resource Inventory
# ================================================
output "📋_resource_summary" {
  description = "Summary of created AWS resources"
  value = {
    foundation = {
      backend_type = "S3 Native Locking"
      state_bucket = "Managed by terraform/bootstrap"
      oidc_integration = "GitHub Actions ready"
      cost_optimization = "No DynamoDB table required"
    }
    networking = {
      vpc_id = module.vpc.vpc_id
      public_subnets = length(module.vpc.public_subnets)
      private_subnets = length(module.vpc.private_subnets)
      database_subnets = var.features.enable_rds ? length(module.vpc.database_subnets) : 0
    }
    storage = {
      data_lake_bucket = module.data_lake.s3_bucket_id
      versioning_enabled = var.data_lake_config.enable_versioning
      encryption_enabled = var.data_lake_config.enable_encryption
      lifecycle_enabled = var.data_lake_config.enable_lifecycle
    }
    processing = {
      glue_database = var.processing_config.enable_crawler ? aws_glue_catalog_database.main[0].name : "not created"
      glue_crawler = var.processing_config.enable_crawler ? aws_glue_crawler.main[0].name : "not created"
      data_quality_job = var.processing_config.enable_data_quality ? aws_glue_job.data_quality[0].name : "not created"
      worker_configuration = "${var.processing_config.worker_type} x ${var.processing_config.number_of_workers}"
    }
    automation = {
      eventbridge_rules = var.features.enable_self_healing ? length(module.automation[0].eventbridge_rule_arns) : 0
      sns_topic = var.features.enable_self_healing ? module.notifications[0].topic_arn : "not created"
      notification_email = var.features.enable_self_healing ? var.self_healing_config.notification_email : "not configured"
    }
    observability = {
      grafana_workspace = var.features.enable_observability ? "created" : "not created"
      cloudwatch_dashboard = var.features.enable_observability ? aws_cloudwatch_dashboard.self_healing[0].dashboard_name : "not created"
      enhanced_monitoring = var.observability_config.enable_enhanced_monitoring
    }
    database = {
      rds_instance = var.features.enable_rds ? module.database[0].db_instance_identifier : "not created"
      instance_class = var.features.enable_rds ? var.rds_config.instance_class : "n/a"
      multi_az = var.features.enable_rds ? var.rds_config.multi_az : false
    }
  }
}