# ================================================
# [THREE PILLARS] Infrastructure Configuration
# ================================================
# Purpose: Support Technical Survival Strategy three pillars implementation
# Learning Value: Shows enterprise-level infrastructure configuration

# terraform/environments/dev/variables.tf

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "alert_email" {
  description = "Email address for self-healing alerts"
  type        = string
  # Remove default - use TF_VAR_alert_email or terraform.tfvars
  sensitive = true

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_email))
    error_message = "Alert email must be a valid email address."
  }
}

# Removed unused variables:
# - project_name (not used consistently)