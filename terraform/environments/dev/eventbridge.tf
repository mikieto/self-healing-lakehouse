# ===========================================
# [GUARD PILLAR] Event-Driven Protection
# ===========================================
# Purpose: Automatic response to system events and anomalies
# Benefit: Immediate reaction to problems without human intervention
# Three Pillars Role: Autonomous system protection and recovery
# Learning Value: Demonstrates event-driven automation patterns

# terraform/environments/dev/eventbridge.tf
# Minimal EventBridge configuration for self-healing

# EventBridge rule for S3 events
module "self_healing_eventbridge" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "~> 3.0"
  
  create_bus = false  # Use default event bus
  
  rules = {
    new_data_uploaded = {
      description = "Detect new data files for quality checking"
      
      event_pattern = jsonencode({
        source      = ["aws.s3"]
        detail-type = ["Object Created"]
        detail = {
          bucket = {
            name = [module.lakehouse_storage.s3_bucket_id]
          }
          object = {
            key = [{
              prefix = "raw/"
            }]
          }
        }
      })
      
      enabled = true
    }
  }
  
  targets = {
    new_data_uploaded = [
      {
        name = "NotifyNewData"
        arn  = module.healing_alerts_sns.topic_arn
        input_transformer = {
          input_paths = {
            bucket = "$.detail.bucket.name"
            key    = "$.detail.object.key"
          }
          input_template = jsonencode({
            alert_type = "new_data_detected"
            message    = "📁 New data uploaded: <key> - Starting quality checks..."
            bucket     = "<bucket>"
            object_key = "<key>"
          })
        }
      }
    ]
  }
  
  tags = {
    Name    = "lakehouse-self-healing"
    Purpose = "self-healing-notifications"
  }
}