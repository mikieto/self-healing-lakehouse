# ========================================================
# [THREE PILLARS FOUNDATION] S3 Native Locking Outputs
# ========================================================
# Purpose: Provide S3 Native Locking configuration for main environments
# Learning Value: Shows simplified state management without DynamoDB

# =======================================================
# [CODE PILLAR] S3 Native State Management Configuration
# =======================================================

output "terraform_state_bucket" {
  description = "[CODE PILLAR] S3 bucket name for Terraform state with native locking"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "terraform_state_bucket_arn" {
  description = "[CODE PILLAR] S3 bucket ARN for IAM policy configuration"
  value       = aws_s3_bucket.terraform_state.arn
}

output "terraform_backend_config" {
  description = "[CODE PILLAR] S3 Native Locking backend configuration"
  value = {
    bucket         = aws_s3_bucket.terraform_state.bucket
    key           = "env/dev/terraform.tfstate"
    region        = data.aws_region.current.name
    encrypt       = true
    use_lockfile  = true  # S3 Native Locking enabled
  }
}

# =======================================================
# [OBSERVABILITY PILLAR] Monitoring Configuration
# =======================================================

output "bootstrap_log_group" {
  description = "[OBSERVABILITY PILLAR] CloudWatch log group for bootstrap operations"
  value       = aws_cloudwatch_log_group.bootstrap_logs.name
}

output "bootstrap_log_group_arn" {
  description = "[OBSERVABILITY PILLAR] CloudWatch log group ARN"
  value       = aws_cloudwatch_log_group.bootstrap_logs.arn
}

# =======================================================
# [GUARD PILLAR] Security Configuration
# =======================================================

output "terraform_execution_role_arn" {
  description = "[GUARD PILLAR] IAM role ARN for secure Terraform execution"
  value       = aws_iam_role.terraform_execution.arn
}

output "terraform_execution_role_name" {
  description = "[GUARD PILLAR] IAM role name for reference"
  value       = aws_iam_role.terraform_execution.name
}

# =======================================================
# [LEARNING EXPERIENCE] S3 Native Locking Benefits
# =======================================================

output "next_steps" {
  description = "Next steps for S3 Native Locking setup"
  value = var.learning_mode ? "S3 Native Locking bootstrap complete! No DynamoDB needed." : "Bootstrap completed"
}

output "backend_config_hcl" {
  description = "Ready-to-use S3 Native Locking backend configuration"
  value = <<-EOT
    bucket         = "${aws_s3_bucket.terraform_state.bucket}"
    key            = "env/dev/terraform.tfstate"
    region         = "${data.aws_region.current.name}"
    encrypt        = true
    use_lockfile   = true
  EOT
}

output "aws_console_urls" {
  description = "Quick access URLs for AWS console"
  value = var.learning_mode ? {
    s3_state_bucket = "https://s3.console.aws.amazon.com/s3/buckets/${aws_s3_bucket.terraform_state.bucket}"
    cloudwatch_logs = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#logsV2:log-groups/log-group/${replace(aws_cloudwatch_log_group.bootstrap_logs.name, "/", "$252F")}"
    iam_role       = "https://console.aws.amazon.com/iam/home#/roles/${aws_iam_role.terraform_execution.name}"
  } : {}
}

# Bootstrap metadata
output "bootstrap_info" {
  description = "S3 Native Locking bootstrap deployment information"
  value = {
    deployment_id    = random_id.bootstrap_suffix.hex
    aws_account     = data.aws_caller_identity.current.account_id
    aws_region      = data.aws_region.current.name
    locking_method  = "s3_native"
    timestamp       = timestamp()
  }
}
