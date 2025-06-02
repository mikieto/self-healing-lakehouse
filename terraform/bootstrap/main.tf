# =======================================================
# [THREE PILLARS FOUNDATION] S3 Native Locking Bootstrap
# =======================================================
# Purpose: S3 Native Locking foundation (NO DynamoDB required)
# Benefit: Cost-effective state management with Terraform 1.6+ native locking
# Learning Value: Modern Terraform state management without additional services

terraform {
  required_version = ">= 1.6"  # S3 Native Locking requires 1.6+
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
  
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "bootstrap"
      ManagedBy   = "terraform"
      LockingType = "s3-native"
    }
  }
}

# Unique suffix for resource naming
resource "random_id" "suffix" {
  byte_length = 4
}

# AWS account and region data
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =======================================================
# [CODE PILLAR] S3 State Bucket (Native Locking Ready)
# =======================================================

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-state-${random_id.suffix.hex}"

  tags = {
    Name        = "terraform-state-s3-native-locking"
    Purpose     = "S3 Native Locking state storage"
    LockingType = "s3-native"
  }
}

# Versioning enables state history and rollback
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption for security
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =======================================================
# [GUARD PILLAR] GitHub Actions OIDC (Minimal)
# =======================================================

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name        = "github-actions-oidc"
    Purpose     = "OIDC authentication for CI/CD"
    LockingType = "s3-native"
  }
}

resource "aws_iam_role" "github_actions" {
  name = "GitHubActionsRole-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "github-actions-role"
    Purpose     = "GitHub Actions Terraform permissions"
    LockingType = "s3-native"
  }
}

# Comprehensive permissions for lakehouse deployment
resource "aws_iam_role_policy" "github_actions_permissions" {
  name = "github-actions-s3-native-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # Core AWS services for lakehouse
          "ec2:*",
          "s3:*",
          "rds:*", 
          "glue:*",
          "events:*",
          "logs:*",
          "cloudwatch:*",
          "sns:*",
          "lambda:*",
          "kms:*",
          
          # IAM for service roles
          "iam:GetRole",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy", 
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:PassRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:List*",
          "iam:Get*",
          
          # Identity verification
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })
}

# =======================================================
# NOTE: S3 Native Locking eliminates DynamoDB entirely
# State locking handled by S3 with use_lockfile = true
# Terraform 1.6+ feature for simplified architecture
# =======================================================