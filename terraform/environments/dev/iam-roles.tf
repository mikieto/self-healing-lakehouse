# ================================================
# [THREE PILLARS] Cloud Posse IAM Integration
# ================================================
# Purpose: Enterprise-grade IAM using Cloud Posse standards
# Benefits: Security best practices, consistent tagging, reduced maintenance
# Learning Value: Professional IAM module patterns and enterprise compliance

# terraform/environments/dev/iam-roles.tf
# Cloud Posse IAM roles for lakehouse services

# =======================================================
# Glue Service IAM Role using Cloud Posse Module
# =======================================================

module "glue_iam_role" {
  source  = "cloudposse/iam-role/aws"
  version = "~> 0.16"

  # Cloud Posse naming convention
  namespace = "lakehouse"
  stage     = var.environment
  name      = "glue"

  # Standard Cloud Posse attributes
  attributes = ["data", "processing"]
  delimiter  = "-"

  # Required argument
  role_description = "IAM role for AWS Glue data processing jobs in lakehouse"

  # IAM role configuration
  principals = {
    Service = ["glue.amazonaws.com"]
  }

  # AWS managed policies
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  ]

  # Custom policy documents
  policy_documents = [
    data.aws_iam_policy_document.glue_s3_access.json,
    data.aws_iam_policy_document.glue_sns_access.json
  ]

  # Use explicit tags instead of local.common_tags
  tags = {
    Project     = "self-healing-lakehouse"
    Environment = var.environment
    ManagedBy   = "terraform"
    Purpose     = "data-processing"
    Component   = "iam"
  }
}

# =======================================================
# IAM Policy Documents using Terraform Data Sources
# =======================================================

# S3 access policy for Glue jobs
data "aws_iam_policy_document" "glue_s3_access" {
  statement {
    sid    = "S3DataLakeAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning"
    ]

    resources = [
      module.lakehouse_storage.s3_bucket_arn,
      "${module.lakehouse_storage.s3_bucket_arn}/*"
    ]
  }

  statement {
    sid    = "S3TempAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${module.lakehouse_storage.s3_bucket_arn}/temp/*",
      "${module.lakehouse_storage.s3_bucket_arn}/scripts/*"
    ]
  }
}

# SNS access policy for notifications
data "aws_iam_policy_document" "glue_sns_access" {
  statement {
    sid    = "SNSNotificationAccess"
    effect = "Allow"

    actions = [
      "sns:Publish"
    ]

    resources = [
      module.healing_alerts_sns.topic_arn
    ]
  }
}

# =======================================================
# Additional IAM Roles for Future Services
# =======================================================

# EventBridge execution role - Simplified version
module "eventbridge_iam_role" {
  source  = "cloudposse/iam-role/aws"
  version = "~> 0.16"

  namespace = "lakehouse"
  stage     = var.environment
  name      = "eventbridge"

  attributes = ["automation"]

  # Required argument
  role_description = "IAM role for EventBridge automation in self-healing lakehouse"

  principals = {
    Service = ["events.amazonaws.com"]
  }

  policy_documents = [
    data.aws_iam_policy_document.eventbridge_access.json
  ]

  tags = {
    Project     = "self-healing-lakehouse"
    Environment = var.environment
    ManagedBy   = "terraform"
    Purpose     = "automation"
    Component   = "iam"
  }
}

# EventBridge policy document
data "aws_iam_policy_document" "eventbridge_access" {
  statement {
    sid    = "GlueJobExecution"
    effect = "Allow"

    actions = [
      "glue:StartJobRun",
      "glue:GetJobRun",
      "glue:GetJobRuns"
    ]

    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:job/*"
    ]
  }

  statement {
    sid    = "SNSPublish"
    effect = "Allow"

    actions = [
      "sns:Publish"
    ]

    resources = [
      module.healing_alerts_sns.topic_arn
    ]
  }
}

# =======================================================
# Outputs for Backward Compatibility
# =======================================================

# Maintain existing interface for other modules
locals {
  glue_iam_role = {
    iam_role_arn  = module.glue_iam_role.arn
    iam_role_name = module.glue_iam_role.name
    iam_role_id   = module.glue_iam_role.id
  }

  eventbridge_iam_role = {
    iam_role_arn  = module.eventbridge_iam_role.arn
    iam_role_name = module.eventbridge_iam_role.name
    iam_role_id   = module.eventbridge_iam_role.id
  }
}

# Export additional role information
output "iam_roles_info" {
  description = "Cloud Posse IAM roles information"
  value = {
    glue_role = {
      arn  = module.glue_iam_role.arn
      name = module.glue_iam_role.name
      id   = module.glue_iam_role.id
    }
    eventbridge_role = {
      arn  = module.eventbridge_iam_role.arn
      name = module.eventbridge_iam_role.name
      id   = module.eventbridge_iam_role.id
    }
    cloud_posse_features = {
      naming_convention = "namespace-stage-name-attributes"
      tagging_strategy  = "cloud_posse_standard"
      security_features = "least_privilege_embedded"
      maintenance       = "community_maintained"
    }
  }
}