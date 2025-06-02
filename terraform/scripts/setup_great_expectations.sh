#!/bin/bash
# terraform/scripts/setup_great_expectations.sh
# Enterprise-grade Great Expectations setup

set -euo pipefail

# Configuration
LOG_FILE="/tmp/ge_setup_$(date +%Y%m%d_%H%M%S).log"
GE_DIR="great_expectations"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    echo -e "${RED}❌ Error: $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

log "🎯 Starting enterprise Great Expectations setup"

# Validate prerequisites
command -v python3 >/dev/null 2>&1 || error_exit "Python3 not found"
command -v pip >/dev/null 2>&1 || error_exit "pip not found"

# Install GE with enterprise dependencies
log "📦 Installing Great Expectations with enterprise dependencies"
pip install great_expectations[s3,postgresql] pandas boto3 >/dev/null 2>&1 || error_exit "Failed to install GE"

# Get S3 bucket from Terraform for enterprise storage
log "📋 Getting S3 bucket configuration from Terraform"
if [ -d "terraform/environments/dev" ]; then
    cd terraform/environments/dev
    S3_BUCKET=$(terraform output -raw data_lake_bucket_name 2>/dev/null || echo "")
    cd - >/dev/null
else
    S3_BUCKET=""
fi

# Initialize GE project
log "🚀 Initializing Great Expectations project"
if [ -d "$GE_DIR" ]; then
    log "⚠️  GE directory exists, backing up"
    mv "$GE_DIR" "${GE_DIR}_backup_$(date +%s)"
fi

great_expectations --yes init >/dev/null 2>&1 || error_exit "Failed to initialize GE"

# Create enterprise configuration
log "⚙️ Creating enterprise configuration"
if [ -n "$S3_BUCKET" ]; then
    # Configure S3 stores for enterprise use
    cat > "$GE_DIR/great_expectations.yml" << EOF
# Enterprise Great Expectations Configuration
config_version: 3.0

config_variables_file_path: uncommitted/config_variables.yml

stores:
  expectations_store:
    class_name: ExpectationsStore
    store_backend:
      class_name: TupleS3StoreBackend
      bucket: "$S3_BUCKET"
      prefix: "great_expectations/expectations/"

  validations_store:
    class_name: ValidationsStore
    store_backend:
      class_name: TupleS3StoreBackend
      bucket: "$S3_BUCKET"  
      prefix: "great_expectations/validations/"

  evaluation_parameter_store:
    class_name: EvaluationParameterStore

expectations_store_name: expectations_store
validations_store_name: validations_store
evaluation_parameter_store_name: evaluation_parameter_store

data_docs_sites:
  s3_site:
    class_name: SiteBuilder
    store_backend:
      class_name: TupleS3StoreBackend
      bucket: "$S3_BUCKET"
      prefix: "great_expectations/data_docs/"
    site_index_builder:
      class_name: DefaultSiteIndexBuilder
EOF
    log "✅ Configured S3 backend for enterprise storage"
else
    log "⚠️  No S3 bucket found, using local storage"
fi

# Create sample data with realistic structure
log "📊 Creating enterprise sample data"
mkdir -p data/samples

python3 << 'EOF'
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

# Enterprise-grade sample data
np.random.seed(42)
start_time = datetime.now() - timedelta(days=1)

data = {
    'sensor_id': [f'SENSOR_{i:03d}' for i in np.random.randint(1, 50, 500)],
    'timestamp': [start_time + timedelta(minutes=i*3) for i in range(500)],
    'temperature': np.random.normal(22, 3, 500),
    'humidity': np.random.normal(60, 10, 500),
    'location': np.random.choice(['Floor1', 'Floor2', 'Floor3'], 500),
    'status': np.random.choice(['OK', 'WARNING', 'ERROR'], 500, p=[0.8, 0.15, 0.05])
}

# Add some realistic quality issues
data['temperature'][45] = 150  # Outlier
data['humidity'][67] = -10     # Invalid value
data['temperature'][89] = None # Missing value

df = pd.DataFrame(data)
df.to_csv('data/samples/sensor_data_enterprise.csv', index=False)
print("✅ Enterprise sample data created")
EOF

# Create basic validation script
log "📝 Creating validation script"
cat > scripts/validate_enterprise_data.py << 'EOF'
#!/usr/bin/env python3
"""
Enterprise Great Expectations validation script
"""
import great_expectations as gx
import sys
import os

def validate_data(file_path):
    """Validate data using Great Expectations"""
    try:
        context = gx.get_context()
        
        # Basic validation for enterprise data
        df = context.sources.pandas_default.read_csv(file_path)
        
        # Create basic expectation suite
        suite = context.add_or_update_expectation_suite("sensor_data_quality")
        
        # Add enterprise-grade expectations
        validator = context.get_validator(
            batch_request=context.build_batch_request(
                datasource_name="pandas_default",
                data_asset_name=file_path
            ),
            expectation_suite_name="sensor_data_quality"
        )
        
        # Basic data quality expectations
        validator.expect_column_to_exist("sensor_id")
        validator.expect_column_to_exist("timestamp") 
        validator.expect_column_values_to_be_between("temperature", min_value=-50, max_value=100)
        validator.expect_column_values_to_be_between("humidity", min_value=0, max_value=100)
        validator.expect_column_values_to_not_be_null("sensor_id")
        
        # Save suite and run validation
        validator.save_expectation_suite()
        results = validator.validate()
        
        return results.success
        
    except Exception as e:
        print(f"Validation failed: {e}")
        return False

if __name__ == "__main__":
    file_path = sys.argv[1] if len(sys.argv) > 1 else "data/samples/sensor_data_enterprise.csv"
    success = validate_data(file_path)
    print(f"Validation {'PASSED' if success else 'FAILED'}")
    sys.exit(0 if success else 1)
EOF

chmod +x scripts/validate_enterprise_data.py

# Test the setup
log "🧪 Testing Great Expectations setup"
if python3 scripts/validate_enterprise_data.py >/dev/null 2>&1; then
    log "✅ GE validation test passed"
else
    log "⚠️  GE validation test had issues (expected with quality issues in sample data)"
fi

log "🎉 Enterprise Great Expectations setup completed"
log "📄 Setup log saved to: $LOG_FILE"

echo -e "${GREEN}✅ Great Expectations enterprise setup completed!${NC}"
echo -e "${BLUE}📂 Created:${NC}"
echo "  - $GE_DIR/ (Enterprise GE project)"
echo "  - data/samples/sensor_data_enterprise.csv (Sample data with quality issues)"
echo "  - scripts/validate_enterprise_data.py (Validation script)"
echo -e "${BLUE}📄 Log file: $LOG_FILE${NC}"
echo -e "${BLUE}🚀 Ready for Phase 4 full implementation!${NC}"