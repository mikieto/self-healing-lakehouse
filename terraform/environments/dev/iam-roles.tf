# ================================================
# [THREE PILLARS] Infrastructure Configuration
# ================================================
# Purpose: Support Technical Survival Strategy three pillars implementation
# Learning Value: Shows enterprise-level infrastructure configuration

# terraform/environments/dev/iam-roles.tf
# IAM roles for services (cleaned up)

# IAM Role for Glue services
resource "aws_iam_role" "glue" {
  name = "lakehouse-glue-role-${random_id.bucket_suffix.hex}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name    = "lakehouse-glue-role"
    Purpose = "data-processing"
  }
}

# Attach AWS managed policy for Glue service
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Custom policy for S3 access
resource "aws_iam_policy" "glue_s3_access" {
  name        = "lakehouse-glue-s3-access-${random_id.bucket_suffix.hex}"
  description = "S3 access policy for Glue jobs"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.lakehouse_storage.s3_bucket_arn,
          "${module.lakehouse_storage.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Attach S3 access policy to Glue role
resource "aws_iam_role_policy_attachment" "glue_s3" {
  role       = aws_iam_role.glue.name
  policy_arn = aws_iam_policy.glue_s3_access.arn
}

# Module-like output for compatibility (simplified)
locals {
  glue_iam_role = {
    iam_role_arn = aws_iam_role.glue.arn
  }
}