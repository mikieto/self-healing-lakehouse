# ================================================
# [CODE PILLAR] Athena Analytics Foundation  
# ================================================
# Purpose: Query analytics foundation for medallion 3-layer architecture
# Template: AWS Official Resources (zero custom code)

# Athena Workgroup for lakehouse analytics
resource "aws_athena_workgroup" "lakehouse_analytics" {
  name = "lakehouse-analytics-${random_id.bucket_suffix.hex}"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.lakehouse_storage.s3_bucket_id}/athena-results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }

    bytes_scanned_cutoff_per_query = 1073741824 # 1GB limit
  }

  force_destroy = true

  tags = {
    Name        = "lakehouse-athena"
    Purpose     = "medallion-analytics"
    Environment = var.environment
    Pillar      = "code"
  }
}

# Named queries for medallion layers
resource "aws_athena_named_query" "bronze_layer_sample" {
  name        = "bronze_layer_sample"
  workgroup   = aws_athena_workgroup.lakehouse_analytics.name
  database    = aws_glue_catalog_database.main.name
  description = "Bronze layer sample data query"

  query = <<-SQL
SELECT 
  sensor_id,
  temperature,
  humidity,
  timestamp,
  status,
  COUNT(*) as record_count
FROM "${aws_glue_catalog_database.main.name}"."raw_sensor_data"
WHERE timestamp >= current_date - interval '7' day
GROUP BY sensor_id, temperature, humidity, timestamp, status
ORDER BY timestamp DESC
LIMIT 100;
SQL
}

resource "aws_athena_named_query" "silver_layer_quality" {
  name        = "silver_layer_quality"
  workgroup   = aws_athena_workgroup.lakehouse_analytics.name
  database    = aws_glue_catalog_database.main.name
  description = "Silver layer data quality check"

  query = <<-SQL
SELECT 
  'Data Quality Report' as report_type,
  COUNT(*) as total_records,
  SUM(CASE WHEN temperature IS NULL THEN 1 ELSE 0 END) as null_temperature,
  SUM(CASE WHEN humidity IS NULL THEN 1 ELSE 0 END) as null_humidity,
  SUM(CASE WHEN temperature < -50 OR temperature > 100 THEN 1 ELSE 0 END) as temp_outliers,
  SUM(CASE WHEN humidity < 0 OR humidity > 100 THEN 1 ELSE 0 END) as humidity_outliers,
  ROUND(
    100.0 * (
      COUNT(*) - 
      SUM(CASE WHEN temperature IS NULL THEN 1 ELSE 0 END) -
      SUM(CASE WHEN humidity IS NULL THEN 1 ELSE 0 END) -
      SUM(CASE WHEN temperature < -50 OR temperature > 100 THEN 1 ELSE 0 END) -
      SUM(CASE WHEN humidity < 0 OR humidity > 100 THEN 1 ELSE 0 END)
    ) / COUNT(*), 2
  ) as quality_score_percentage
FROM "${aws_glue_catalog_database.main.name}"."raw_sensor_data"
WHERE timestamp >= current_date - interval '1' day;
SQL
}

resource "aws_athena_named_query" "gold_layer_aggregates" {
  name        = "gold_layer_aggregates"
  workgroup   = aws_athena_workgroup.lakehouse_analytics.name
  database    = aws_glue_catalog_database.main.name
  description = "Gold layer aggregate data analysis"

  query = <<-SQL
SELECT 
  DATE(timestamp) as analysis_date,
  sensor_id,
  AVG(temperature) as avg_temperature,
  AVG(humidity) as avg_humidity,
  MIN(temperature) as min_temperature,
  MAX(temperature) as max_temperature,
  COUNT(*) as readings_count,
  SUM(CASE WHEN status = 'OK' THEN 1 ELSE 0 END) as ok_readings,
  ROUND(100.0 * SUM(CASE WHEN status = 'OK' THEN 1 ELSE 0 END) / COUNT(*), 2) as success_rate
FROM "${aws_glue_catalog_database.main.name}"."raw_sensor_data"
WHERE timestamp >= current_date - interval '7' day
  AND temperature IS NOT NULL 
  AND humidity IS NOT NULL
GROUP BY DATE(timestamp), sensor_id
ORDER BY analysis_date DESC, sensor_id;
SQL
}

# Output for verification
output "athena_info" {
  description = "Athena analytics infrastructure information"
  value = {
    workgroup_name = aws_athena_workgroup.lakehouse_analytics.name
    workgroup_arn  = aws_athena_workgroup.lakehouse_analytics.arn
    console_url    = "https://console.aws.amazon.com/athena/home?region=${var.aws_region}"
    named_queries = [
      aws_athena_named_query.bronze_layer_sample.name,
      aws_athena_named_query.silver_layer_quality.name,
      aws_athena_named_query.gold_layer_aggregates.name
    ]
  }
}