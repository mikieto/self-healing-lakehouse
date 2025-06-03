#!/usr/bin/env python3
"""
AWS Glue Data Quality Job - Enhanced with CloudWatch Metrics
Phase 3.2.1: Data Quality Trend Dashbord Support
"""

import sys
import boto3
import time
from datetime import datetime
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext

# AWS Official Glue Job Pattern
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)

# Standard AWS Glue argument parsing
args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'source-path', 
    'quarantine-path',
    'sns-topic-arn'
])

job.init(args['JOB_NAME'], args)

def send_cloudwatch_metric(metric_name, value, unit='Count', namespace='SelfHealingLakehouse'):
    """Send custom metric to CloudWatch"""
    try:
        cloudwatch = boto3.client('cloudwatch')
        cloudwatch.put_metric_data(
            Namespace=namespace,
            MetricData=[
                {
                    'MetricName': metric_name,
                    'Value': value,
                    'Unit': unit,
                    'Timestamp': datetime.utcnow(),
                    'Dimensions': [
                        {
                            'Name': 'JobName',
                            'Value': args['JOB_NAME']
                        },
                        {
                            'Name': 'Environment',
                            'Value': 'dev'  # Could be passed as parameter
                        }
                    ]
                }
            ]
        )
        print(f"📊 CloudWatch metric sent: {metric_name} = {value}")
    except Exception as e:
        print(f"⚠️ Failed to send CloudWatch metric: {e}")

def calculate_data_quality_score(df, row_count):
    """Calculate data quality score (0-100)"""
    if row_count == 0:
        return 0
    
    try:
        # Count various quality issues
        null_count = 0
        outlier_count = 0
        
        # Check for null values in critical columns
        if 'sensor_id' in df.columns:
            null_count += df.filter(df.sensor_id.isNull()).count()
        if 'temperature' in df.columns:
            null_count += df.filter(df.temperature.isNull()).count()
            # Check for temperature outliers (outside reasonable range)
            outlier_count += df.filter((df.temperature < -50) | (df.temperature > 100)).count()
        if 'humidity' in df.columns:
            null_count += df.filter(df.humidity.isNull()).count()
            # Check for humidity outliers (outside 0-100 range)
            outlier_count += df.filter((df.humidity < 0) | (df.humidity > 100)).count()
        
        # Calculate quality score
        total_issues = null_count + outlier_count
        quality_score = max(0, 100 - (total_issues * 100 / row_count))
        
        return quality_score, null_count, outlier_count
        
    except Exception as e:
        print(f"⚠️ Error calculating quality score: {e}")
        return 50, 0, 0  # Default fallback

def main():
    """Enhanced AWS Official Data Quality Pattern with CloudWatch Metrics"""
    print(f"🚀 Starting enhanced {args['JOB_NAME']}")
    start_time = time.time()
    
    # AWS Official: Read from S3 using Glue DynamicFrame
    try:
        datasource = glueContext.create_dynamic_frame.from_options(
            format_options={"multiline": False},
            connection_type="s3",
            format="csv",
            connection_options={
                "paths": [args['source-path']],
                "recurse": True
            }
        )
        
        # AWS Official: Basic data validation
        df = datasource.toDF()
        row_count = df.count()
        
        print(f"📊 Processing {row_count} records")
        
        # Send row count metric
        send_cloudwatch_metric('DataRowCount', row_count)
        
        # Calculate data quality score
        quality_score, null_count, outlier_count = calculate_data_quality_score(df, row_count)
        
        # Send quality metrics
        send_cloudwatch_metric('DataQualityScore', quality_score, 'Percent')
        send_cloudwatch_metric('NullValueCount', null_count)
        send_cloudwatch_metric('OutlierCount', outlier_count)
        
        # Processing time metric
        processing_time = time.time() - start_time
        send_cloudwatch_metric('ProcessingTimeSeconds', processing_time, 'Seconds')
        
        # AWS Official: Quality check pattern with enhanced logic
        if row_count == 0:
            status = "NO_DATA"
            message = "No data found in source"
            send_cloudwatch_metric('JobStatus', 0)  # 0 = failure
        elif quality_score < 70:
            status = "QUALITY_ISSUES"
            message = f"Data quality issues detected: Score {quality_score:.1f}% (nulls: {null_count}, outliers: {outlier_count})"
            send_cloudwatch_metric('JobStatus', 0)  # 0 = failure
            send_cloudwatch_metric('QualityViolationCount', 1)
        elif row_count < 10:
            status = "LOW_VOLUME"  
            message = f"Low data volume: {row_count} records, Quality: {quality_score:.1f}%"
            send_cloudwatch_metric('JobStatus', 1)  # 1 = success with warnings
        else:
            status = "SUCCESS"
            message = f"Data quality check passed: {row_count} records, Quality: {quality_score:.1f}%"
            send_cloudwatch_metric('JobStatus', 2)  # 2 = complete success
        
        # Send final summary metric
        send_cloudwatch_metric('JobCompletionCount', 1)
        
    except Exception as e:
        status = "ERROR"
        message = f"Data processing failed: {str(e)}"
        send_cloudwatch_metric('JobStatus', -1)  # -1 = error
        send_cloudwatch_metric('JobErrorCount', 1)
        print(f"❌ Processing error: {e}")
    
    # AWS Official: SNS notification pattern with enhanced message
    try:
        sns = boto3.client('sns')
        enhanced_message = f"""
📊 Data Quality Report
Status: {status}
Details: {message}
Processing Time: {processing_time:.2f} seconds

📈 Metrics sent to CloudWatch:
- Namespace: SelfHealingLakehouse
- JobName: {args['JOB_NAME']}
        """
        
        sns.publish(
            TopicArn=args['sns-topic-arn'],
            Subject=f"Data Quality Check - {status}",
            Message=enhanced_message
        )
    except Exception as e:
        print(f"⚠️ Failed to send SNS notification: {e}")
    
    print(f"✅ {message}")
    print(f"📊 CloudWatch metrics sent for dashboard visualization")

if __name__ == "__main__":
    main()
    job.commit()