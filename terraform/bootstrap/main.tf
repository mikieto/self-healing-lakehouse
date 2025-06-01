# =======================================================
# [CODE PILLAR FOUNDATION] S3 Native Locking Bootstrap
# =======================================================
# Purpose: Establish S3 Native Locking foundation for Technical Survival Strategy
# Benefit: Simplified, cost-effective state management without DynamoDB
# Three Pillars Role: Enables Code Pillar with S3-only state management
# Learning Value: Shows modern Terraform state management patterns

terraform {
  required_version = ">= 1.7"
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
  
  # Local backend for bootstrap phase
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
  
  # Default tags for all bootstrap resources
  default_tags {
    tags = {
      Project     = "TechnicalSurvivalStrategy"
      Environment = "bootstrap"
      ManagedBy   = "terraform"
      Purpose     = "s3-native-locking-foundation"
      Pillar      = "Code"
    }
  }
}

# Random suffix for unique resource naming
resource "random_id" "bootstrap_suffix" {
  byte_length = 4
}

# Current AWS account and region information
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =======================================================
# [CODE PILLAR] S3 Native Locking State Backend
# =======================================================

# S3 bucket for Terraform state storage with native locking
resource "aws_s3_bucket" "terraform_state" {
  bucket = "tss-terraform-state-${random_id.bootstrap_suffix.hex}"
  
  tags = {
    Name      = "terraform-state-backend"
    Pillar    = "Code"
    Component = "S3NativeStateManagement"
    Purpose   = "S3 Native Locking foundation infrastructure"
  }
}

# Enable versioning for state file protection
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for security
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access for security
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =======================================================
# [OBSERVABILITY PILLAR] Bootstrap Monitoring
# =======================================================

# CloudWatch Log Group for bootstrap operations
resource "aws_cloudwatch_log_group" "bootstrap_logs" {
  name              = "/aws/tss/bootstrap-${random_id.bootstrap_suffix.hex}"
  retention_in_days = 14

  tags = {
    Name      = "bootstrap-operations-logs"
    Pillar    = "Observability"
    Component = "BootstrapLogging"
    Purpose   = "Track bootstrap process for troubleshooting"
  }
}

# =======================================================
# [GUARD PILLAR] IAM Role for Secure Terraform Operations
# =======================================================

# IAM role for Terraform operations with minimal required permissions
resource "aws_iam_role" "terraform_execution" {
  name = "tss-terraform-execution-${random_id.bootstrap_suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name      = "terraform-execution-role"
    Pillar    = "Guard"
    Component = "SecureExecution"
    Purpose   = "Controlled permissions for Terraform operations"
  }
}

# Policy for Terraform state management operations (S3 only)
resource "aws_iam_role_policy" "terraform_state_access" {
  name = "terraform-state-access"
  role = aws_iam_role.terraform_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
      }
    ]
  })
}

# =======================================================
# Note: S3 Native Locking eliminates the need for DynamoDB
# State locking is handled directly by S3 with use_lockfile = true
# This simplifies the architecture and reduces costs
# =======================================================
