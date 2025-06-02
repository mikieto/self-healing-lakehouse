# =======================================================
# [S3 NATIVE LOCKING] Bootstrap Outputs
# =======================================================

output "github_actions_role_arn" {
  description = "GitHub Actions IAM Role ARN for CI/CD"
  value       = aws_iam_role.github_actions.arn
}

output "terraform_state_bucket" {
  description = "S3 bucket for Terraform state with native locking"
  value       = aws_s3_bucket.terraform_state.bucket
}

# TRUE S3 Native Locking backend configuration
output "s3_native_backend_config" {
  description = "S3 Native Locking backend configuration (copy to environments/*/backend.tf)"
  value = {
    bucket         = aws_s3_bucket.terraform_state.bucket
    key           = "environments/dev/terraform.tfstate"
    region        = data.aws_region.current.name
    encrypt       = true
    use_lockfile  = true  # ← This is the real S3 Native Locking
  }
}

# Ready-to-use backend.tf content for environments
output "backend_tf_content" {
  description = "Copy this content to terraform/environments/dev/backend.tf"
  value = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.terraform_state.bucket}"
        key            = "environments/dev/terraform.tfstate"
        region         = "${data.aws_region.current.name}"
        encrypt        = true
        use_lockfile   = true
      }
    }
  EOT
}

# GitHub Variables for CI/CD
output "github_variables" {
  description = "Set these in GitHub Repository Variables"
  value = {
    AWS_ROLE_ARN = aws_iam_role.github_actions.arn
    ALERT_EMAIL  = "mikieto@gmail.com"
  }
}

# Deployment summary
output "deployment_summary" {
  description = "S3 Native Locking deployment summary"
  value = {
    state_bucket   = aws_s3_bucket.terraform_state.bucket
    locking_method = "s3_native"
    dynamodb_table = "none_required"
    cost_savings   = "~$0.25/month (no DynamoDB)"
    terraform_version = ">= 1.6 required"
  }
}