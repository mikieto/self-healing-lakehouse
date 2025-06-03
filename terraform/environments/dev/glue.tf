# ===============================================
# [CODE PILLAR] Data Processing Infrastructure
# ===============================================
# Purpose: Production-ready data processing with essential features
# Benefit: Maintainable, scalable, and reliable data pipelines
# Three Pillars Role: Robust foundation for automated data operations
# Learning Value: Shows enterprise data processing patterns

# terraform/environments/dev/glue.tf

# Local variables for configuration
locals {
  glue_config = {
    name_prefix   = "lakehouse-${random_id.bucket_suffix.hex}"
    script_bucket = module.lakehouse_storage.s3_bucket_id
    database_name = "lakehouse_catalog_${random_id.bucket_suffix.hex}"

    # Job configurations
    job_defaults = {
      glue_version        = "4.0"
      python_version      = "3"
      max_retries         = 2
      timeout             = 60 # minutes
      max_concurrent_runs = 2
      worker_type         = "G.1X"
      number_of_workers   = 2
    }

    tags = {
      Name        = "lakehouse-data-processing"
      Purpose     = "self-healing-lakehouse"
      Environment = var.environment
      Component   = "data-processing"
    }
  }
}

# ===== GLUE CATALOG =====
resource "aws_glue_catalog_database" "main" {
  name        = local.glue_config.database_name
  description = "Self-Healing Lakehouse Data Catalog"

  create_table_default_permission {
    permissions = ["SELECT"]

    principal {
      data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS"
    }
  }

  tags = local.glue_config.tags
}

# ===== ENHANCED GLUE CRAWLER =====
resource "aws_glue_crawler" "main" {
  name          = "${local.glue_config.name_prefix}-crawler"
  database_name = aws_glue_catalog_database.main.name
  role          = local.glue_iam_role.iam_role_arn

  # S3 targets
  s3_target {
    path = "s3://${local.glue_config.script_bucket}/raw/"
    exclusions = [
      "**/_temporary/**",
      "**/.spark-staging/**"
    ]
  }

  # Enhanced schema change policy
  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }

  # Configuration for better performance
  configuration = jsonencode({
    "Version" = 1.0
    "CrawlerOutput" = {
      "Partitions" = {
        "AddOrUpdateBehavior" = "InheritFromTable"
      }
    }
    "Grouping" = {
      "TableGroupingPolicy" = "CombineCompatibleSchemas"
    }
  })

  # Schedule: Run every 6 hours during business hours
  schedule = "cron(0 6,12,18 ? * MON-FRI *)"

  tags = local.glue_config.tags
}

# ===== DATA QUALITY JOB (maintaining original name) =====
resource "aws_glue_job" "data_quality" {
  name         = "${local.glue_config.name_prefix}-data-quality"
  role_arn     = local.glue_iam_role.iam_role_arn
  glue_version = local.glue_config.job_defaults.glue_version

  command {
    script_location = "s3://${local.glue_config.script_bucket}/scripts/data_quality_job.py"
    python_version  = local.glue_config.job_defaults.python_version
  }

  # Production-ready arguments
  default_arguments = {
    "--job-language"                     = "python"
    "--job-bookmark-option"              = "job-bookmark-enable"
    "--enable-metrics"                   = "true"
    "--enable-continuous-cloudwatch-log" = "true"

    # Essential arguments (maintain compatibility)
    "--TempDir"         = "s3://${local.glue_config.script_bucket}/temp/"
    "--source-path"     = "s3://${local.glue_config.script_bucket}/raw/"
    "--quarantine-path" = "s3://${local.glue_config.script_bucket}/quarantine/"
    "--database-name"   = aws_glue_catalog_database.main.name
    "--table-name"      = "sample_sensor_data"
    "--sns-topic-arn"   = module.healing_alerts_sns.topic_arn
  }

  # Production execution properties
  execution_property {
    max_concurrent_runs = local.glue_config.job_defaults.max_concurrent_runs
  }

  max_retries = local.glue_config.job_defaults.max_retries
  timeout     = local.glue_config.job_defaults.timeout

  # Worker configuration
  worker_type       = local.glue_config.job_defaults.worker_type
  number_of_workers = local.glue_config.job_defaults.number_of_workers

  tags = merge(local.glue_config.tags, {
    JobType = "data-quality"
  })
}

# ===== REMEDIATION JOB (maintaining original name) =====
resource "aws_glue_job" "remediation" {
  name         = "${local.glue_config.name_prefix}-remediation"
  role_arn     = local.glue_iam_role.iam_role_arn
  glue_version = local.glue_config.job_defaults.glue_version

  command {
    script_location = "s3://${local.glue_config.script_bucket}/scripts/remediation_job.py"
    python_version  = local.glue_config.job_defaults.python_version
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--job-bookmark-option"              = "job-bookmark-disable" # Always process all data
    "--enable-metrics"                   = "true"
    "--enable-continuous-cloudwatch-log" = "true"

    # Remediation-specific arguments (maintain compatibility)
    "--TempDir"         = "s3://${local.glue_config.script_bucket}/temp/"
    "--source-path"     = "s3://${local.glue_config.script_bucket}/raw/"
    "--quarantine-path" = "s3://${local.glue_config.script_bucket}/quarantine/"
    "--sns-topic-arn"   = module.healing_alerts_sns.topic_arn
    "--database-name"   = aws_glue_catalog_database.main.name
  }

  execution_property {
    max_concurrent_runs = 1 # Remediation should be serial
  }

  max_retries = local.glue_config.job_defaults.max_retries
  timeout     = local.glue_config.job_defaults.timeout

  worker_type       = local.glue_config.job_defaults.worker_type
  number_of_workers = local.glue_config.job_defaults.number_of_workers

  tags = merge(local.glue_config.tags, {
    JobType = "remediation"
  })
}

# ===== JOB TRIGGERS =====
# Data Quality Trigger (scheduled)
resource "aws_glue_trigger" "data_quality_scheduled" {
  name     = "${local.glue_config.name_prefix}-dq-scheduled"
  type     = "SCHEDULED"
  schedule = "cron(0 2,8,14,20 * * ? *)" # Every 6 hours

  actions {
    job_name = aws_glue_job.data_quality.name
  }

  tags = local.glue_config.tags
}

# Remediation Trigger (on-demand)
resource "aws_glue_trigger" "remediation_on_demand" {
  name = "${local.glue_config.name_prefix}-remediation-demand"
  type = "ON_DEMAND"

  actions {
    job_name = aws_glue_job.remediation.name
  }

  tags = local.glue_config.tags
}

# ===== OUTPUTS =====
output "data_processing_enhanced" {
  description = "Balanced data processing components"
  value = {
    database = {
      name = aws_glue_catalog_database.main.name
      arn  = aws_glue_catalog_database.main.arn
    }
    crawler = {
      name = aws_glue_crawler.main.name
      arn  = aws_glue_crawler.main.arn
    }
    jobs = {
      data_quality = {
        name = aws_glue_job.data_quality.name
        arn  = aws_glue_job.data_quality.arn
      }
      remediation = {
        name = aws_glue_job.remediation.name
        arn  = aws_glue_job.remediation.arn
      }
    }
    triggers = {
      scheduled_dq          = aws_glue_trigger.data_quality_scheduled.name
      on_demand_remediation = aws_glue_trigger.remediation_on_demand.name
    }
  }
}