# eventbridge.tf - Conflict Resolution Version
# EventBridge configuration with unique naming to avoid conflicts

# EventBridge rule for S3 events
module "self_healing_eventbridge" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "~> 3.0"

  create_bus = false # Use default event bus

  # Unique IAM role name to avoid conflicts
  create_role = true
  role_name   = "eventbridge-role-${random_id.bucket_suffix.hex}" # Unique naming

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
    Name    = "lakehouse-self-healing-${random_id.bucket_suffix.hex}"
    Purpose = "self-healing-notifications"
  }
}