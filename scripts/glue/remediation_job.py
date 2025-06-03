#!/usr/bin/env python3
"""
AWS Glue Remediation Job - Based on AWS Official Template  
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
    'quarantine-path',
    'sns-topic-arn'
])

job.init(args['JOB_NAME'], args)

def main():
    """AWS Official Remediation Pattern"""
    print(f"🔧 Starting {args['JOB_NAME']}")
    
    # AWS Official: List quarantined files
    s3 = boto3.client('s3')
    
    # Extract bucket and prefix from quarantine path
    bucket = args['quarantine-path'].replace('s3://', '').split('/')[0]
    prefix = '/'.join(args['quarantine-path'].replace('s3://', '').split('/')[1:])
    
    try:
        response = s3.list_objects_v2(Bucket=bucket, Prefix=prefix)
        file_count = len(response.get('Contents', []))
        
        if file_count == 0:
            status = "NO_QUARANTINE"
            message = "No quarantined files found"
        else:
            status = "QUARANTINE_DETECTED"
            message = f"Found {file_count} quarantined files requiring attention"
        
    except Exception as e:
        status = "ERROR"
        message = f"Remediation check failed: {str(e)}"
    
    # AWS Official: SNS notification pattern
    sns = boto3.client('sns')
    sns.publish(
        TopicArn=args['sns-topic-arn'],
        Subject=f"Remediation Check - {status}",
        Message=message
    )
    
    print(f"✅ {message}")

if __name__ == "__main__":
    main()
    job.commit()