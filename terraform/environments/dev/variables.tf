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
  default     = "admin@example.com"
  sensitive   = true
}

# Removed unused variables:
# - project_name (not used consistently)