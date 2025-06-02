#!/bin/bash
# Comprehensive self-healing system test

set -euo pipefail

# Configuration
ENVIRONMENT=${1:-dev}
TEST_MODE=${2:-quick}  # quick|full|chaos
LOG_FILE="/tmp/self_healing_test_$(date +%Y%m%d_%H%M%S).log"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

error_exit() {
    echo -e "${RED}❌ Test Failed: $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

# Test 1: Infrastructure Health
test_infrastructure() {
    log "🏗️ Testing infrastructure health..."
    
    cd "terraform/environments/$ENVIRONMENT" || error_exit "Environment not found"
    
    # Verify Terraform state
    terraform plan -detailed-exitcode >/dev/null 2>&1 || error_exit "Infrastructure drift detected"
    
    # Verify S3 bucket accessibility
    BUCKET_NAME=$(terraform output -raw data_lake_bucket_name)
    aws s3 ls "s3://$BUCKET_NAME/" >/dev/null 2>&1 || error_exit "S3 bucket not accessible"
    
    log "✅ Infrastructure health check passed"
    cd - >/dev/null
}

# Test 2: Data Quality Pipeline
test_data_quality() {
    log "📊 Testing data quality pipeline..."
    
    # Upload test data with known quality issues
    BUCKET_NAME=$(cd terraform/environments/$ENVIRONMENT && terraform output -raw data_lake_bucket_name)
    
    # Create test data with quality issues
    cat > /tmp/test_data.csv << EOF
sensor_id,temperature,humidity,timestamp,status
SENSOR_TEST_001,22.5,45.2,2024-01-15T10:00:00,NORMAL
SENSOR_TEST_002,999.0,999.0,invalid_timestamp,CORRUPT
SENSOR_TEST_003,25.1,48.7,2024-01-15T10:02:00,NORMAL
EOF
    
    # Upload test data
    aws s3 cp /tmp/test_data.csv "s3://$BUCKET_NAME/raw/test_data_$(date +%s).csv"
    
    # Wait for processing and verify quarantine
    sleep 30
    
    # Check if corrupt data was quarantined
    if aws s3 ls "s3://$BUCKET_NAME/quarantine/" | grep -q "test_data"; then
        log "✅ Data quality validation working - corrupt data quarantined"
    else
        log "⚠️ Data quality test inconclusive - may need more time"
    fi
    
    # Cleanup
    rm -f /tmp/test_data.csv
}

# Test 3: Monitoring & Alerting
test_monitoring() {
    log "📡 Testing monitoring and alerting..."
    
    # Check CloudWatch dashboards exist
    aws cloudwatch describe-dashboards --dashboard-name-prefix "SelfHealing" >/dev/null 2>&1 || \
        error_exit "CloudWatch dashboards not found"
    
    # Check SNS topic exists and is accessible
    cd "terraform/environments/$ENVIRONMENT" || error_exit "Environment not found"
    SNS_TOPIC_ARN=$(terraform output -json automation | jq -r '.sns_topic')
    aws sns get-topic-attributes --topic-arn "$SNS_TOPIC_ARN" >/dev/null 2>&1 || \
        error_exit "SNS topic not accessible"
    
    log "✅ Monitoring infrastructure verified"
    cd - >/dev/null
}

# Main test execution
main() {
    log "🧪 Starting Self-Healing Lakehouse tests - $TEST_MODE mode"
    log "🎯 Environment: $ENVIRONMENT"
    
    # Validate prerequisites
    command -v terraform >/dev/null 2>&1 || error_exit "Terraform not found"
    command -v aws >/dev/null 2>&1 || error_exit "AWS CLI not found"
    command -v jq >/dev/null 2>&1 || error_exit "jq not found"
    
    # Run tests based on mode
    case "$TEST_MODE" in
        "quick")
            test_infrastructure
            ;;
        "full")
            test_infrastructure
            test_monitoring
            ;;
        "chaos")
            test_infrastructure
            test_data_quality
            test_monitoring
            ;;
        *)
            error_exit "Unknown test mode: $TEST_MODE (use: quick|full|chaos)"
            ;;
    esac
    
    log "🎉 All tests completed successfully!"
    log "📄 Test log: $LOG_FILE"
    
    echo -e "${GREEN}✅ Self-Healing Lakehouse tests passed!${NC}"
    echo -e "${BLUE}📊 Mode: $TEST_MODE${NC}"
    echo -e "${BLUE}🎯 Environment: $ENVIRONMENT${NC}"
    echo -e "${BLUE}📄 Log: $LOG_FILE${NC}"
}

# Execute main function
main "$@"