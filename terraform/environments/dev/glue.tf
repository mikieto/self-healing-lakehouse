# terraform/environments/dev/glue.tf - Use new database name

locals {
  glue_config = {
    name_prefix   = "lakehouse-${random_id.bucket_suffix.hex}"
    script_bucket = module.lakehouse_storage.s3_bucket_id
    # Use timestamp to ensure unique name
    database_name = "lakehouse_db_${random_id.bucket_suffix.hex}_${formatdate("YYYYMMDD", timestamp())}"

    job_defaults = {
      glue_version        = "4.0"
      python_version      = "3"
      max_retries         = 2
      timeout             = 60
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

# =======================================================
# Lake Formation Settings - Complete IAM Delegation
# =======================================================

resource "aws_lakeformation_data_lake_settings" "main" {
  # Completely delegate to IAM
  create_database_default_permissions {
    permissions = ["ALL"]
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }

  create_table_default_permissions {
    permissions = ["ALL"]
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }

  # Remove any admin restrictions
  admins = []

}

# =======================================================
# Glue Catalog Database
# =======================================================

resource "aws_glue_catalog_database" "main" {
  name        = local.glue_config.database_name
  description = "Self-Healing Lakehouse Data Catalog - Clean Installation"

  create_table_default_permission {
    permissions = ["SELECT"]

    principal {
      data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS"
    }
  }

  tags = local.glue_config.tags

  # Ensure Lake Formation is set up first
  depends_on = [aws_lakeformation_data_lake_settings.main]
}

# =======================================================
# Glue Crawler
# =======================================================

resource "aws_glue_crawler" "main" {
  name          = "${local.glue_config.name_prefix}-crawler"
  database_name = aws_glue_catalog_database.main.name
  role          = local.glue_iam_role.iam_role_arn

  s3_target {
    path = "s3://${local.glue_config.script_bucket}/raw/"
    exclusions = [
      "**/_temporary/**",
      "**/.spark-staging/**"
    ]
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }

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

  schedule = "cron(0 6,12,18 ? * MON-FRI *)"
  tags     = local.glue_config.tags
}

# =======================================================
# Glue Jobs
# =======================================================

resource "aws_glue_job" "data_quality" {
  name         = "${local.glue_config.name_prefix}-data-quality"
  role_arn     = local.glue_iam_role.iam_role_arn
  glue_version = local.glue_config.job_defaults.glue_version

  command {
    script_location = "s3://${local.glue_config.script_bucket}/scripts/data_quality_job.py"
    python_version  = local.glue_config.job_defaults.python_version
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--job-bookmark-option"              = "job-bookmark-enable"
    "--enable-metrics"                   = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--TempDir"                          = "s3://${local.glue_config.script_bucket}/temp/"
    "--source-path"                      = "s3://${local.glue_config.script_bucket}/raw/"
    "--quarantine-path"                  = "s3://${local.glue_config.script_bucket}/quarantine/"
    "--database-name"                    = aws_glue_catalog_database.main.name
    "--table-name"                       = "sample_sensor_data"
    "--sns-topic-arn"                    = module.healing_alerts_sns.topic_arn
  }

  execution_property {
    max_concurrent_runs = local.glue_config.job_defaults.max_concurrent_runs
  }

  max_retries       = local.glue_config.job_defaults.max_retries
  timeout           = local.glue_config.job_defaults.timeout
  worker_type       = local.glue_config.job_defaults.worker_type
  number_of_workers = local.glue_config.job_defaults.number_of_workers

  tags = merge(local.glue_config.tags, {
    JobType = "data-quality"
  })
}

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
    "--job-bookmark-option"              = "job-bookmark-disable"
    "--enable-metrics"                   = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--TempDir"                          = "s3://${local.glue_config.script_bucket}/temp/"
    "--source-path"                      = "s3://${local.glue_config.script_bucket}/raw/"
    "--quarantine-path"                  = "s3://${local.glue_config.script_bucket}/quarantine/"
    "--sns-topic-arn"                    = module.healing_alerts_sns.topic_arn
    "--database-name"                    = aws_glue_catalog_database.main.name
  }

  execution_property {
    max_concurrent_runs = 1
  }

  max_retries       = local.glue_config.job_defaults.max_retries
  timeout           = local.glue_config.job_defaults.timeout
  worker_type       = local.glue_config.job_defaults.worker_type
  number_of_workers = local.glue_config.job_defaults.number_of_workers

  tags = merge(local.glue_config.tags, {
    JobType = "remediation"
  })
}

# =======================================================
# Job Triggers
# =======================================================

resource "aws_glue_trigger" "data_quality_scheduled" {
  name     = "${local.glue_config.name_prefix}-dq-scheduled"
  type     = "SCHEDULED"
  schedule = "cron(0 2,8,14,20 * * ? *)"

  actions {
    job_name = aws_glue_job.data_quality.name
  }

  tags = local.glue_config.tags
}

resource "aws_glue_trigger" "remediation_on_demand" {
  name = "${local.glue_config.name_prefix}-remediation-demand"
  type = "ON_DEMAND"

  actions {
    job_name = aws_glue_job.remediation.name
  }

  tags = local.glue_config.tags
}