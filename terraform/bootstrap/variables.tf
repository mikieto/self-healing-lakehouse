# =======================================================
# [S3 NATIVE LOCKING] Bootstrap Variables
# =======================================================

variable "aws_region" {
  description = "AWS region for S3 Native Locking infrastructure"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.aws_region))
    error_message = "AWS region must be a valid region identifier."
  }
}

variable "project_name" {
  description = "Project name for S3 bucket and resource naming"
  type        = string
  default     = "self-healing-lakehouse"

  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 30
    error_message = "Project name must be between 1 and 30 characters for S3 bucket naming."
  }
}

variable "github_repository" {
  description = "GitHub repository for OIDC authentication (format: owner/repo)"
  type        = string
  default     = "mikieto/self-healing-lakehouse"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$", var.github_repository))
    error_message = "GitHub repository must be in format 'owner/repository'."
  }
}