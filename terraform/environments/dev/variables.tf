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
  default     = "devops@example.com" # RFC 2606 reserved domain - safe for demos
  sensitive   = true

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_email))
    error_message = "The alert_email must be a valid email address format."
  }
}