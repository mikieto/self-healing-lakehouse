# ===============================================
# [CODE PILLAR] Data Processing Infrastructure
# ===============================================
# Purpose: Reproducible data transformation and catalog management
# Benefit: Consistent data processing logic across environments
# Three Pillars Role: Automated, reliable data pipeline foundation
# Learning Value: Demonstrates declarative data processing setup

# terraform/environments/dev/glue.tf
# AWS Glue configuration for data processing

# Glue Catalog Database
resource "aws_glue_catalog_database" "main" {
  name        = "lakehouse_catalog"
  description = "Self-Healing Lakehouse Data Catalog"
}

# Glue Crawler for data discovery
resource "aws_glue_crawler" "main" {
  database_name = aws_glue_catalog_database.main.name
  name          = "lakehouse-crawler-${random_id.bucket_suffix.hex}"
  role          = local.glue_iam_role.iam_role_arn
  
  s3_target {
    path = "s3://${module.lakehouse_storage.s3_bucket_id}/raw/"
  }
  
  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "DEPRECATE_IN_DATABASE"
  }
  
  tags = {
    Name    = "lakehouse-crawler"
    Purpose = "data-discovery"
  }
}


# Glue Data Quality Job
resource "aws_glue_job" "data_quality" {
  name     = "lakehouse-data-quality-${random_id.bucket_suffix.hex}"
  role_arn = local.glue_iam_role.iam_role_arn
  
  command {
    script_location = "s3://${module.lakehouse_storage.s3_bucket_id}/scripts/data_quality_job.py"
    python_version  = "3"
  }
  
  default_arguments = {
    "--TempDir"                           = "s3://${module.lakehouse_storage.s3_bucket_id}/temp/"
    "--enable-metrics"                    = ""
    "--enable-continuous-cloudwatch-log" = ""
    "--job-language"                      = "python"
    "--source-path"                       = "s3://${module.lakehouse_storage.s3_bucket_id}/raw/"
    "--quarantine-path"                   = "s3://${module.lakehouse_storage.s3_bucket_id}/quarantine/"
    "--database-name"                     = aws_glue_catalog_database.main.name
    "--table-name"                        = "sample_sensor_data"
  }
  
  max_retries = 1
  timeout     = 10
  
  tags = {
    Name    = "lakehouse-data-quality"
    Purpose = "self-healing-data-quality"
  }
}

# Glue Self-Healing Remediation Job
resource "aws_glue_job" "remediation" {
  name     = "lakehouse-remediation-${random_id.bucket_suffix.hex}"
  role_arn = local.glue_iam_role.iam_role_arn
  
  command {
    script_location = "s3://${module.lakehouse_storage.s3_bucket_id}/scripts/remediation_job.py"
    python_version  = "3"
  }
  
  default_arguments = {
    "--TempDir"          = "s3://${module.lakehouse_storage.s3_bucket_id}/temp/"
    "--source-path"      = "s3://${module.lakehouse_storage.s3_bucket_id}/raw/"
    "--quarantine-path"  = "s3://${module.lakehouse_storage.s3_bucket_id}/quarantine/"
    "--sns-topic-arn"    = module.healing_alerts_sns.topic_arn
  }
  
  tags = {
    Name    = "lakehouse-remediation"
    Purpose = "self-healing-remediation"
  }
}

# Remove Data Quality Ruleset for now (requires table to exist first)
# This can be added later after crawler discovers the table
# resource "aws_glue_data_quality_ruleset" "main" {
#   name    = "lakehouse-data-quality-rules-${random_id.bucket_suffix.hex}"
#   ruleset = "Rules = [ColumnCount > 0, IsComplete \"sensor_id\", ColumnValues \"temperature\" between 0 and 100, ColumnValues \"humidity\" between 0 and 100]"
#   
#   target_table {
#     database_name = aws_glue_catalog_database.main.name
#     table_name    = "sample_sensor_data"
#   }
#   
#   depends_on = [aws_glue_crawler.main]
#   
#   tags = {
#     Name    = "lakehouse-dq-rules"
#     Purpose = "data-quality-monitoring"
#   }
# }