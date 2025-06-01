# ============================================
# [CODE PILLAR] Data Storage Infrastructure
# ============================================
# Purpose: Reproducible, declarative data lake storage
# Benefit: Consistent storage configuration across all deployments
# Three Pillars Role: Foundation for reliable, scalable data operations
# Learning Value: Shows Infrastructure as Code principles in action

# terraform/environments/dev/s3.tf
# S3 and Lake Formation configuration

# Data Lake S3 bucket using official AWS module
module "lakehouse_storage" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"
  
  bucket = "lakehouse-data-${random_id.bucket_suffix.hex}"
  
  versioning = {
    enabled = true
  }
  
  lifecycle_rule = [
    {
      id     = "data_lifecycle"
      status = "Enabled"
      
      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
    }
  ]
  
  # EventBridge notifications are handled by a separate resource
  # notification = {
  #   eventbridge = {
  #     enabled = true
  #   }
  # }
  
  tags = {
    "Purpose"    = "self-healing-lakehouse"
    "FIS-Target" = "true"
  }
}

# S3 bucket notification for EventBridge
resource "aws_s3_bucket_notification" "lakehouse_events" {
  bucket      = module.lakehouse_storage.s3_bucket_id
  eventbridge = true
}

# Lake Formation Data Lake Settings (simplified)
resource "aws_lakeformation_data_lake_settings" "lakehouse" {
  admins = [data.aws_caller_identity.current.arn]
  
  # Simplified configuration without default permissions
  trusted_resource_owners = [data.aws_caller_identity.current.account_id]
}

# Note: random_id and data sources are already defined in main.tf