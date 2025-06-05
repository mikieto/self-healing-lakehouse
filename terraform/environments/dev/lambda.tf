# terraform/environments/dev/lambda.tf
# Lambda function for Glue job triggering - NEW FILE

# Lambda function ZIP file
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "/tmp/lambda-function.zip"

  source {
    content  = <<EOF
import json
import boto3
import logging

# ログ設定
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    S3 EventBridge イベントを受信してGlueジョブを開始
    """
    try:
        # Glueクライアント初期化
        glue_client = boto3.client('glue')
        
        # イベント情報の抽出
        bucket_name = event['detail']['bucket']['name']
        object_key = event['detail']['object']['key']
        
        logger.info(f"New file detected: s3://{bucket_name}/{object_key}")
        
        # Glueジョブ開始
        job_name = aws_glue_job.data_quality.name
        
        response = glue_client.start_job_run(
            JobName=job_name,
            Arguments={
                '--triggered_by': 'eventbridge',
                '--source_file': f"s3://{bucket_name}/{object_key}",
                '--trigger_time': str(context.aws_request_id)
            }
        )
        
        job_run_id = response['JobRunId']
        logger.info(f"Glue job started successfully: {job_run_id}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Glue job {job_name} started successfully',
                'jobRunId': job_run_id,
                'sourceFile': f"s3://{bucket_name}/{object_key}"
            })
        }
        
    except Exception as e:
        logger.error(f"Error starting Glue job: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }
EOF
    filename = "lambda_function.py"
  }
}

# Lambda execution role
resource "aws_iam_role" "lambda_glue_trigger" {
  name = "lakehouse-lambda-glue-trigger-${random_id.bucket_suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Lambda basic execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_glue_trigger.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for Glue job execution
resource "aws_iam_role_policy" "lambda_glue_policy" {
  name = "glue-job-execution-${random_id.bucket_suffix.hex}"
  role = aws_iam_role.lambda_glue_trigger.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:GetJobRuns"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda function
resource "aws_lambda_function" "glue_trigger" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "lakehouse-glue-trigger-${random_id.bucket_suffix.hex}"
  role          = aws_iam_role.lambda_glue_trigger.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  description = "Trigger Glue data quality job from S3 events"

  tags = local.common_tags
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "eventbridge_invoke" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.glue_trigger.function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.self_healing_eventbridge.eventbridge_rule_arns["new_data_uploaded"]
}
