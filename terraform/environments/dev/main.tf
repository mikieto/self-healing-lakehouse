# ================================================
# [THREE PILLARS] Infrastructure Configuration
# ================================================
# Purpose: Support Technical Survival Strategy three pillars implementation
# Learning Value: Shows enterprise-level infrastructure configuration

# terraform/environments/dev/main.tf
terraform {
  required_version = ">= 1.7"

  # S3 backend configuration
  backend "s3" {
    # Configuration is provided via backend.hcl file
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Default tags for all resources
  default_tags {
    tags = {
      Project     = "self-healing-lakehouse"
      Environment = var.environment
      ManagedBy   = "terraform"
      Purpose     = "self-healing-lakehouse"
    }
  }
}

# Random suffix for unique resource naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Data sources for current AWS context
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}