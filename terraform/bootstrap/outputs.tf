# =======================================================
# [S3 NATIVE LOCKING] Bootstrap Outputs
# =======================================================

output "github_actions_role_arn" {
  description = "GitHub Actions IAM Role ARN for CI/CD"
  value       = module.iam_github_oidc_role.arn
}

output "terraform_state_bucket" {
  description = "S3 bucket for Terraform state with native locking"
  value       = module.s3_bucket.s3_bucket_id
}

# TRUE S3 Native Locking backend configuration
output "s3_native_backend_config" {
  description = "S3 Native Locking backend configuration"
  value = {
    bucket       = module.s3_bucket.s3_bucket_id
    key          = "environments/dev/terraform.tfstate"
    region       = data.aws_region.current.name
    encrypt      = true
    use_lockfile = true # ← S3 Native Locking
  }
}

# Ready-to-use backend.tf content
output "backend_tf_content" {
  description = "Copy this content to terraform/environments/dev/backend.tf"
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${module.s3_bucket.s3_bucket_id}"
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
    AWS_ROLE_ARN = module.iam_github_oidc_role.arn
    ALERT_EMAIL  = "mikieto@gmail.com"
  }
}

# Deployment summary
output "deployment_summary" {
  description = "S3 Native Locking deployment summary"
  value = {
    state_bucket      = module.s3_bucket.s3_bucket_id
    locking_method    = "s3_native"
    dynamodb_table    = "none_required"
    cost_savings      = "~$0.25/month (no DynamoDB)"
    terraform_version = ">= 1.6 required"
  }
}