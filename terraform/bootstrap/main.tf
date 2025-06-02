# =======================================================
# [S3 NATIVE LOCKING] Bootstrap with AWS Official Modules
# =======================================================

terraform {
  required_version = ">= 1.6"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Current AWS region data source
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Random suffix for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

# =======================================================
# S3 Bucket using AWS Official Module
# =======================================================

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = "${var.project_name}-terraform-state-${random_id.suffix.hex}"
  
  # S3 Native Locking Configuration
  versioning = {
    enabled = true
  }
  
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  
  tags = {
    Name = "Terraform State Bucket"
    Project = var.project_name
    LockingMethod = "s3_native"
  }
}

# =======================================================
# IAM Module for GitHub Actions
# =======================================================

module "iam_github_oidc_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "~> 5.0"

  name = "GitHubActionsRole-${random_id.suffix.hex}"
  
  subjects = ["repo:${var.github_repository}:*"]
  
  policies = {
    LakehouseFullAccess = aws_iam_policy.github_actions_permissions.arn
  }

  tags = {
    Name = "GitHub Actions Role"
    Project = var.project_name
  }
}

# Custom policy for lakehouse permissions
resource "aws_iam_policy" "github_actions_permissions" {
  name = "github-actions-lakehouse-policy-${random_id.suffix.hex}"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # Core AWS services for lakehouse
          "ec2:*", "s3:*", "rds:*", "glue:*", "events:*",
          "logs:*", "cloudwatch:*", "sns:*", "lambda:*", "kms:*",
          
          # IAM permissions
          "iam:GetRole", "iam:CreateRole", "iam:DeleteRole",
          "iam:AttachRolePolicy", "iam:DetachRolePolicy", 
          "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:PassRole",
          "iam:TagRole", "iam:UntagRole", "iam:List*", "iam:Get*",
          "iam:CreatePolicy", "iam:DeletePolicy",
          "iam:CreateInstanceProfile", "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile",
          
          # Additional services
          "secretsmanager:*", "aps:*", "grafana:*", "lakeformation:*",
          "application-autoscaling:*", "elasticloadbalancing:*", 
          "autoscaling:*", "ssm:*", "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "GitHub Actions Lakehouse Policy"
    Project = var.project_name
  }
}

# =======================================================
# OIDC Provider for GitHub Actions (Missing Definition)
# =======================================================

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = {
    Name = "GitHub Actions OIDC Provider"
    Project = var.project_name
  }
}

# =======================================================
# Lake Formation Data Lake Settings
# =======================================================

resource "aws_lakeformation_data_lake_settings" "main" {
  admins = [
    data.aws_caller_identity.current.arn,  # Current user (mikieto)
    module.iam_github_oidc_role.arn        # GitHub Actions Role
  ]

  create_database_default_permissions {
    permissions = []
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }

  create_table_default_permissions {
    permissions = []
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }

  trusted_resource_owners = [
    data.aws_caller_identity.current.account_id
  ]
  
}