#!/usr/bin/env python3
"""
AWS Glue Data Quality Job - Based on AWS Official Template
Minimal customization following Zero Custom Code principle
"""

import sys
import boto3
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

def main():
    """AWS Official Data Quality Pattern"""
    print(f"🚀 Starting {args['JOB_NAME']}")
    
    # AWS Official: Read from S3 using Glue DynamicFrame
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
    
    # AWS Official: Quality check pattern
    if row_count == 0:
        status = "NO_DATA"
        message = "No data found in source"
    elif row_count < 10:
        status = "LOW_VOLUME"  
        message = f"Low data volume: {row_count} records"
    else:
        status = "SUCCESS"
        message = f"Data quality check passed: {row_count} records processed"
    
    # AWS Official: SNS notification pattern
    sns = boto3.client('sns')
    sns.publish(
        TopicArn=args['sns-topic-arn'],
        Subject=f"Data Quality Check - {status}",
        Message=message
    )
    
    print(f"✅ {message}")

if __name__ == "__main__":
    main()
    job.commit()