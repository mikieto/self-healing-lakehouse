# ================================================
# [OBSERVABILITY PILLAR] Alert Notification System
# ================================================
# Purpose: Real-time notification delivery for system events
# Benefit: Immediate communication of critical system changes
# Three Pillars Role: Enables rapid human response when needed
# Learning Value: Shows notification infrastructure as code

# terraform/environments/dev/sns.tf
# SNS Topics for notifications using Official Modules

# SNS Topic for self-healing alerts using terraform-aws-modules
module "healing_alerts_sns" {
  source  = "terraform-aws-modules/sns/aws"
  version = "~> 6.0"

  name = "self-healing-alerts-${random_id.bucket_suffix.hex}"

  # Optional: Email subscription for alerts
  subscriptions = {
    email = {
      protocol = "email"
      endpoint = var.alert_email
    }
  }

  tags = {
    Name    = "self-healing-alerts"
    Purpose = "self-healing-notifications"
  }
}