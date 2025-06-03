#!/bin/bash
# Simple chaos engineering script for Self-Healing Lakehouse

BUCKET="lakehouse-data-bec8c89a"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "🧪 Injecting corrupt data for chaos engineering test..."

# Create corrupt CSV data
cat << CSV > /tmp/corrupt_data_$TIMESTAMP.csv
sensor_id,temperature,humidity,timestamp,status
sensor_999,999,999,invalid_timestamp,CORRUPT
invalid_row_data
sensor_888,not_a_number,not_a_number,2024-01-01,ANOMALY
CSV

# Upload to S3
aws s3 cp /tmp/corrupt_data_$TIMESTAMP.csv s3://$BUCKET/raw/corrupt_data_$TIMESTAMP.csv

echo "✅ Corrupt data injected: s3://$BUCKET/raw/corrupt_data_$TIMESTAMP.csv"
echo "🔧 Monitor self-healing in AWS Console:"
echo "   - Glue Jobs for data quality checks"
echo "   - EventBridge for event triggers" 
echo "   - S3 quarantine folder for moved files"
echo "   - SNS for email notifications"

# Clean up
rm -f /tmp/corrupt_data_$TIMESTAMP.csv
