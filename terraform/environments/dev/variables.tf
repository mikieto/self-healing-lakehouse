# ================================================
# Learning-Friendly Configuration Variables
# ================================================
# terraform/environments/dev/variables.tf

# ================================================
# Core Project Configuration
# ================================================
variable "project_name" {
  description = "Name of your lakehouse project (used for resource naming)"
  type        = string
  default     = "learning-lakehouse"

  validation {
    condition     = length(var.project_name) <= 20 && can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must be lowercase, alphanumeric with hyphens, max 20 characters."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.aws_region))
    error_message = "AWS region must be a valid region identifier."
  }
}

# ================================================
# AWS Services Toggles - Learn Each Service Individually!
# ================================================
variable "aws_services" {
  description = "Individual AWS services for hands-on learning - toggle each to see what it does!"
  type = object({
    enable_eventbridge   = bool  # Event-driven automation (file upload triggers)
    enable_sns          = bool  # Simple Notification Service (email alerts)
    enable_cloudwatch   = bool  # Monitoring dashboards and metrics
    enable_grafana      = bool  # Advanced visualization and dashboards
    enable_rds          = bool  # Relational Database Service
    enable_chaos_testing = bool # Advanced: Resilience testing (FIS + Lambda)
  })
  default = {
    enable_eventbridge   = true   # 🔄 Try toggling this - see how automation breaks!
    enable_sns          = true   # 📧 Disable to stop email notifications
    enable_cloudwatch   = true   # 📊 Core AWS monitoring - always useful
    enable_grafana      = false  # 📈 Advanced dashboards - costs extra (~$20/month)
    enable_rds          = false  # 🗄️  Database - costs extra (~$15/month)
    enable_chaos_testing = false # 🧪 Advanced resilience testing (multiple services)
  }

  validation {
    condition = alltrue([
      var.aws_services.enable_eventbridge != null,
      var.aws_services.enable_sns != null,
      var.aws_services.enable_cloudwatch != null,
      var.aws_services.enable_grafana != null,
      var.aws_services.enable_rds != null,
      var.aws_services.enable_chaos_testing != null
    ])
    error_message = "All AWS service flags must be boolean values."
  }
}

# ================================================
# Learning Preset Configuration
# ================================================
variable "learning_preset" {
  description = "Pre-configured setups for different learning scenarios"
  type        = string
  default     = "basic"

  validation {
    condition = contains([
      "basic",           # Minimal setup - core features only
      "intermediate",    # Add observability and monitoring
      "advanced",        # Full self-healing features
      "enterprise",      # Production-ready configuration
      "cost-optimized"   # Absolute minimum cost setup
    ], var.learning_preset)
    error_message = "Learning preset must be: basic, intermediate, advanced, enterprise, or cost-optimized."
  }
}

# ================================================
# Data Lake Configuration
# ================================================
variable "data_lake_config" {
  description = "Data lake storage configuration options"
  type = object({
    enable_versioning = bool
    enable_lifecycle  = bool
    enable_encryption = bool
    storage_classes   = list(string)
  })
  default = {
    enable_versioning = true
    enable_lifecycle  = true
    enable_encryption = true
    storage_classes   = ["STANDARD", "STANDARD_IA", "GLACIER"]
  }

  validation {
    condition = length(var.data_lake_config.storage_classes) > 0
    error_message = "At least one storage class must be specified."
  }
}

# ================================================
# Network Configuration
# ================================================
variable "networking_config" {
  description = "VPC and networking configuration"
  type = object({
    vpc_cidr           = string
    enable_nat_gateway = bool
    enable_flow_logs   = bool
    availability_zones = number
  })
  default = {
    vpc_cidr           = "10.0.0.0/16"
    enable_nat_gateway = false  # Set to false for cost optimization
    enable_flow_logs   = true   # Enable for monitoring
    availability_zones = 2      # Multi-AZ for reliability
  }

  validation {
    condition     = can(cidrhost(var.networking_config.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }

  validation {
    condition     = var.networking_config.availability_zones >= 1 && var.networking_config.availability_zones <= 3
    error_message = "Availability zones must be between 1 and 3."
  }
}

# ================================================
# Data Processing Configuration
# ================================================
variable "processing_config" {
  description = "Glue data processing job configuration"
  type = object({
    enable_crawler      = bool
    enable_data_quality = bool
    enable_remediation  = bool
    glue_version       = string
    worker_type        = string
    number_of_workers  = number
    schedule_crawler   = string
    schedule_quality   = string
  })
  default = {
    enable_crawler      = true
    enable_data_quality = true
    enable_remediation  = true
    glue_version       = "4.0"
    worker_type        = "G.1X"    # Options: G.1X (cost-effective), G.2X (faster), Standard
    number_of_workers  = 2         # Adjust based on data volume
    schedule_crawler   = "cron(0 6,12,18 ? * MON-FRI *)"  # 3x daily on weekdays
    schedule_quality   = "cron(0 2,8,14,20 * * ? *)"      # 4x daily
  }

  validation {
    condition = contains(["G.1X", "G.2X", "Standard"], var.processing_config.worker_type)
    error_message = "Worker type must be G.1X, G.2X, or Standard."
  }

  validation {
    condition     = var.processing_config.number_of_workers >= 2 && var.processing_config.number_of_workers <= 50
    error_message = "Number of workers must be between 2 and 50."
  }
}

# ================================================
# Self-Healing Configuration
# ================================================
variable "self_healing_config" {
  description = "Self-healing automation and alerting configuration"
  type = object({
    notification_email      = string
    enable_auto_remediation = bool
    alert_thresholds = object({
      data_quality_failures = number
      storage_threshold_gb   = number
      error_rate_percent     = number
    })
  })
  default = {
    notification_email      = "your-email@example.com"  # CHANGE THIS!
    enable_auto_remediation = true
    alert_thresholds = {
      data_quality_failures = 3
      storage_threshold_gb   = 100
      error_rate_percent     = 5
    }
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.self_healing_config.notification_email))
    error_message = "Notification email must be a valid email address."
  }

  validation {
    condition = (
      var.self_healing_config.alert_thresholds.data_quality_failures > 0 &&
      var.self_healing_config.alert_thresholds.storage_threshold_gb > 0 &&
      var.self_healing_config.alert_thresholds.error_rate_percent > 0
    )
    error_message = "All alert thresholds must be positive numbers."
  }
}

# ================================================
# Observability Configuration
# ================================================
variable "observability_config" {
  description = "Monitoring, logging, and observability configuration"
  type = object({
    enable_prometheus         = bool
    enable_grafana           = bool
    enable_enhanced_monitoring = bool
    dashboard_types          = list(string)
    retention_days           = number
  })
  default = {
    enable_prometheus         = false  # Enable only in production
    enable_grafana           = true
    enable_enhanced_monitoring = true
    dashboard_types          = ["main", "detailed", "cost"]
    retention_days           = 7
  }

  validation {
    condition = alltrue([
      for dashboard in var.observability_config.dashboard_types :
      contains(["main", "detailed", "cost", "security"], dashboard)
    ])
    error_message = "Dashboard types must be from: main, detailed, cost, security."
  }

  validation {
    condition     = var.observability_config.retention_days >= 1 && var.observability_config.retention_days <= 365
    error_message = "Retention days must be between 1 and 365."
  }
}

# ================================================
# RDS Database Configuration (Optional)
# ================================================
variable "rds_config" {
  description = "RDS PostgreSQL database configuration (optional, requires enable_rds = true)"
  type = object({
    instance_class    = string
    allocated_storage = number
    engine_version    = string
    multi_az         = bool
    backup_retention = number
  })
  default = {
    instance_class    = "db.t3.micro"
    allocated_storage = 20
    engine_version    = "15.7"
    multi_az         = false  # Single AZ for cost savings in dev
    backup_retention = 7
  }

  validation {
    condition = contains([
      "db.t3.micro", "db.t3.small", "db.t3.medium", "db.t3.large",
      "db.r5.large", "db.r5.xlarge"
    ], var.rds_config.instance_class)
    error_message = "Instance class must be a valid RDS instance type."
  }

  validation {
    condition     = var.rds_config.allocated_storage >= 20 && var.rds_config.allocated_storage <= 1000
    error_message = "Allocated storage must be between 20 and 1000 GB."
  }

  validation {
    condition     = var.rds_config.backup_retention >= 0 && var.rds_config.backup_retention <= 35
    error_message = "Backup retention must be between 0 and 35 days."
  }
}

# ================================================
# Alert Email (for backward compatibility)
# ================================================
variable "alert_email" {
  description = "Email address for alerts (backward compatibility - use self_healing_config.notification_email instead)"
  type        = string
  default     = "your-email@example.com"
  sensitive   = true

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_email))
    error_message = "The alert_email must be a valid email address format."
  }
}