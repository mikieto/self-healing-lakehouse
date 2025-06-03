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
  role          = local.glue_iam_role.iam_role_name

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

# =======================================================
# AWS OFFICIAL: Glue Scripts Auto-deployment 
# =======================================================
# Add this to your existing terraform/environments/dev/glue.tf

# AWS Official: S3 Object upload pattern
resource "aws_s3_object" "data_quality_script" {
  bucket = module.lakehouse_storage.s3_bucket_id
  key    = "scripts/data_quality_job.py"
  source = "${path.root}/../../../scripts/glue/data_quality_job.py"
  etag   = filemd5("${path.root}/../../../scripts/glue/data_quality_job.py")

  tags = local.glue_config.tags
}

resource "aws_s3_object" "remediation_script" {
  bucket = module.lakehouse_storage.s3_bucket_id
  key    = "scripts/remediation_job.py"
  source = "${path.root}/../../../scripts/glue/remediation_job.py"
  etag   = filemd5("${path.root}/../../../scripts/glue/remediation_job.py")

  tags = local.glue_config.tags
}

# AWS Official: Sample data upload

# =======================================================
# UPDATE EXISTING GLUE JOBS: Change script_location only
# =======================================================

# In your existing aws_glue_job.data_quality, update:
# script_location = "s3://${local.glue_config.script_bucket}/scripts/data_quality_job.py"

# In your existing aws_glue_job.remediation, update:  
# script_location = "s3://${local.glue_config.script_bucket}/scripts/remediation_job.py"

# =======================================================
# AWS OFFICIAL: SNS permissions for Glue
# =======================================================

resource "aws_iam_role_policy" "glue_sns_minimal" {
  name = "glue-sns-${random_id.bucket_suffix.hex}"
  role = local.glue_iam_role.iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = module.healing_alerts_sns.topic_arn
      }
    ]
  })
}

# =======================================================
# AWS-based Sample Data (No Local Files Required)
# =======================================================
resource "aws_s3_object" "sample_data_clean" {
  bucket  = module.lakehouse_storage.s3_bucket_id
  key     = "raw/sample_data_clean.csv"
  content = <<-CSV
sensor_id,temperature,humidity,timestamp,status
SENSOR_001,22.5,45.2,2024-06-03T10:00:00Z,OK
SENSOR_002,23.1,47.8,2024-06-03T10:01:00Z,OK
SENSOR_003,21.8,44.5,2024-06-03T10:02:00Z,OK
SENSOR_004,24.2,49.1,2024-06-03T10:03:00Z,OK
SENSOR_005,22.9,46.3,2024-06-03T10:04:00Z,OK
CSV

  content_type = "text/csv"

  tags = merge(local.glue_config.tags, {
    Purpose = "sample-data"
    Type    = "clean-sensor-data"
  })
}

resource "aws_s3_object" "sample_data_corrupt" {
  bucket  = module.lakehouse_storage.s3_bucket_id
  key     = "raw/sample_data_corrupt.csv"
  content = <<-CSV
sensor_id,temperature,humidity,timestamp,status
SENSOR_999,999.0,999.0,invalid_timestamp,CORRUPT
invalid_row_data
SENSOR_888,not_a_number,not_a_number,2024-01-01,ANOMALY
SENSOR_777,,,-999,ERROR
CSV

  content_type = "text/csv"

  tags = merge(local.glue_config.tags, {
    Purpose = "sample-data"
    Type    = "corrupt-test-data"
  })
}

# =======================================================
# Git-based Version Management
# =======================================================

# Script version metadata
resource "aws_s3_object" "script_versions" {
  bucket  = module.lakehouse_storage.s3_bucket_id
  key     = "scripts/.versions.json"
  content = jsonencode({
    deployment_info = {
      timestamp = var.deployment_timestamp != "" ? var.deployment_timestamp : timestamp()
      git_commit = var.git_commit_hash
      deployed_by = var.deployed_by
      terraform_version = "1.7+"
    }
    scripts = {
      data_quality_job = {
        file_path = "scripts/glue/data_quality_job.py"
        s3_key = "scripts/data_quality_job.py"
        version_hash = filemd5("${path.root}/../../../scripts/glue/data_quality_job.py")
        git_commit = var.git_commit_hash
        deployed_at = var.deployment_timestamp != "" ? var.deployment_timestamp : timestamp()
      }
      remediation_job = {
        file_path = "scripts/glue/remediation_job.py"
        s3_key = "scripts/remediation_job.py" 
        version_hash = filemd5("${path.root}/../../../scripts/glue/remediation_job.py")
        git_commit = var.git_commit_hash
        deployed_at = var.deployment_timestamp != "" ? var.deployment_timestamp : timestamp()
      }
    }
    environment = {
      name = var.environment
      aws_region = data.aws_region.current.name
      bucket = module.lakehouse_storage.s3_bucket_id
    }
  })
  
  content_type = "application/json"
  
  tags = merge(local.glue_config.tags, {
    Purpose = "version-management"
    Type = "deployment-metadata"
  })
}

# CloudWatch Log Group for deployment tracking
resource "aws_cloudwatch_log_group" "script_deployment" {
  name              = "/aws/terraform/script-deployment"
  retention_in_days = 30
  
  tags = merge(local.glue_config.tags, {
    Purpose = "deployment-tracking"
  })
}

# CloudWatch Log Stream for version history
resource "aws_cloudwatch_log_stream" "version_history" {
  name           = "version-history"
  log_group_name = aws_cloudwatch_log_group.script_deployment.name
}