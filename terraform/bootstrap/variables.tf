# =========================================================
# [THREE PILLARS FOUNDATION] Bootstrap Configuration
# =========================================================
# Purpose: Centralized configuration for Technical Survival Strategy foundation
# Learning Value: Shows infrastructure configuration management best practices

variable "aws_region" {
  description = "AWS region for Three Pillars foundation infrastructure"
  type        = string
  default     = "us-east-1"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.aws_region))
    error_message = "AWS region must be a valid region identifier."
  }
}

variable "project_name" {
  description = "Project name for Technical Survival Strategy implementation"
  type        = string
  default     = "technical-survival-strategy"
  
  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 50
    error_message = "Project name must be between 1 and 50 characters."
  }
}

variable "environment" {
  description = "Environment name for bootstrap infrastructure"
  type        = string
  default     = "bootstrap"
  
  validation {
    condition     = contains(["bootstrap", "dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: bootstrap, dev, staging, prod."
  }
}

# Code Pillar configuration
variable "state_retention_days" {
  description = "[CODE PILLAR] Terraform state backup retention period"
  type        = number
  default     = 90
  
  validation {
    condition     = var.state_retention_days > 0 && var.state_retention_days <= 365
    error_message = "State retention must be between 1 and 365 days."
  }
}

# Observability Pillar configuration
variable "log_retention_days" {
  description = "[OBSERVABILITY PILLAR] CloudWatch log retention period"
  type        = number
  default     = 14
  
  validation {
    condition     = var.log_retention_days > 0 && var.log_retention_days <= 365
    error_message = "Log retention must be between 1 and 365 days."
  }
}

# Guard Pillar configuration
variable "enable_access_logging" {
  description = "[GUARD PILLAR] Enable S3 access logging for audit trail"
  type        = bool
  default     = true
}

variable "force_destroy_state_bucket" {
  description = "[GUARD PILLAR] Allow destruction of state bucket (use with caution)"
  type        = bool
  default     = false
}

# Learning environment specific
variable "learning_mode" {
  description = "Enable learning-friendly configurations and outputs"
  type        = bool
  default     = true
}
