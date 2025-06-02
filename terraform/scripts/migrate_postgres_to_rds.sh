#!/bin/bash
# terraform/scripts/migrate_postgres_to_rds.sh
# Enterprise data migration from multiple sources to RDS

set -euo pipefail

# Configuration
ENV=${1:-dev}
MODE=${2:-demo}
LOG_FILE="/tmp/migration_$(date +%Y%m%d_%H%M%S).log"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

error_exit() {
    echo -e "${RED}❌ Error: $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

log "🗄️ Starting enterprise data migration to RDS - $MODE mode"

# Validate prerequisites
command -v aws >/dev/null 2>&1 || error_exit "AWS CLI not found"
command -v jq >/dev/null 2>&1 || error_exit "jq not found"
command -v psql >/dev/null 2>&1 || error_exit "psql not found"

# Get RDS connection info
log "📋 Retrieving RDS connection info"
cd "terraform/environments/$ENV" || error_exit "Environment directory not found"

if ! terraform output rds_connection_info >/dev/null 2>&1; then
    error_exit "RDS not deployed. Run 'terraform apply' first"
fi

RDS_INFO=$(terraform output -json rds_connection_info)
RDS_ENDPOINT=$(echo "$RDS_INFO" | jq -r '.endpoint')
SECRET_ARN=$(echo "$RDS_INFO" | jq -r '.secret_arn')

# Get RDS credentials
log "🔐 Retrieving RDS credentials"
RDS_PASSWORD=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_ARN" \
    --query SecretString \
    --output text | jq -r '.password') || error_exit "Failed to get RDS password"

# Test RDS connection
log "🔗 Testing RDS connection"
export PGPASSWORD="$RDS_PASSWORD"
if ! psql -h "$RDS_ENDPOINT" -U admin -d lakehouse -c "SELECT 1;" >/dev/null 2>&1; then
    error_exit "Cannot connect to RDS instance"
fi

cd - >/dev/null

# Create migration based on mode
case "$MODE" in
    "demo")
        log "🎯 Demo mode: Creating realistic sample data for demonstration"
        psql -h "$RDS_ENDPOINT" -U admin -d lakehouse << 'EOF'
-- Create enterprise schema
CREATE SCHEMA IF NOT EXISTS lakehouse;

-- Create tables with proper structure
CREATE TABLE IF NOT EXISTS lakehouse.sensor_data (
    id SERIAL PRIMARY KEY,
    sensor_id VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    temperature NUMERIC(5,2),
    humidity NUMERIC(5,2),
    location VARCHAR(100),
    status VARCHAR(20) DEFAULT 'OK',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS lakehouse.data_quality_log (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(100),
    check_name VARCHAR(100),
    status VARCHAR(20),
    message TEXT,
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert realistic demo data (simulating migration from legacy system)
INSERT INTO lakehouse.sensor_data (sensor_id, timestamp, temperature, humidity, location, status) VALUES
    ('SENSOR_001', NOW() - INTERVAL '2 hours', 22.5, 65.0, 'Floor1_Zone1', 'OK'),
    ('SENSOR_002', NOW() - INTERVAL '1 hour 30 minutes', 23.1, 67.2, 'Floor1_Zone2', 'OK'),
    ('SENSOR_003', NOW() - INTERVAL '1 hour', 21.8, 64.5, 'Floor2_Zone1', 'OK'),
    ('SENSOR_004', NOW() - INTERVAL '30 minutes', 24.2, 69.1, 'Floor2_Zone2', 'WARNING'),
    ('SENSOR_005', NOW(), 22.9, 66.3, 'Floor3_Zone1', 'OK');

-- Insert data quality log entry
INSERT INTO lakehouse.data_quality_log (table_name, check_name, status, message) VALUES
    ('sensor_data', 'initial_migration', 'SUCCESS', 'Demo data migration completed successfully');
EOF
        ;;
        
    "csv")
        log "📂 CSV mode: Migrating from CSV files"
        if [ ! -d "data/migration" ]; then
            error_exit "Migration CSV files not found in data/migration/"
        fi
        
        # Create schema first
        psql -h "$RDS_ENDPOINT" -U admin -d lakehouse -c "CREATE SCHEMA IF NOT EXISTS lakehouse;"
        
        # Migrate each CSV file
        for csv_file in data/migration/*.csv; do
            if [ -f "$csv_file" ]; then
                log "📥 Migrating $(basename "$csv_file")"
                # Use PostgreSQL COPY command for efficient CSV import
                table_name=$(basename "$csv_file" .csv)
                psql -h "$RDS_ENDPOINT" -U admin -d lakehouse -c "\COPY lakehouse.$table_name FROM '$csv_file' CSV HEADER;"
            fi
        done
        ;;
        
    "docker")
        log "🐳 Docker mode: Migrating from local Docker PostgreSQL"
        # Check if local-dev Docker is running
        if ! docker ps | grep -q postgres; then
            log "⚠️  Local PostgreSQL Docker not running, switching to demo mode"
            MODE="demo"
            exec "$0" "$ENV" "$MODE"
        fi
        
        # Export from Docker PostgreSQL
        log "📤 Exporting from Docker PostgreSQL"
        docker exec -i $(docker ps -q -f name=postgres) pg_dump -U lakehouse_user lakehouse_db > /tmp/local_export.sql
        
        # Import to RDS
        log "📥 Importing to RDS"
        psql -h "$RDS_ENDPOINT" -U admin -d lakehouse -f /tmp/local_export.sql
        rm -f /tmp/local_export.sql
        ;;
        
    *)
        error_exit "Unknown migration mode: $MODE. Use 'demo', 'csv', or 'docker'"
        ;;
esac

# Verify migration
log "✅ Verifying migration results"
TABLES=$(psql -h "$RDS_ENDPOINT" -U admin -d lakehouse -t -c "
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'lakehouse' AND table_type = 'BASE TABLE';" | tr -d ' ' | grep -v '^)

if [ -n "$TABLES" ]; then
    log "📊 Migration verification:"
    echo "$TABLES" | while read -r table; do
        if [ -n "$table" ]; then
            count=$(psql -h "$RDS_ENDPOINT" -U admin -d lakehouse -t -c "SELECT COUNT(*) FROM lakehouse.$table;" | tr -d ' ')
            log "  - Table '$table': $count rows"
        fi
    done
else
    error_exit "No tables found after migration"
fi

# Create indexes for performance (enterprise requirement)
log "🚀 Creating performance indexes"
psql -h "$RDS_ENDPOINT" -U admin -d lakehouse << 'EOF'
CREATE INDEX IF NOT EXISTS idx_sensor_data_timestamp ON lakehouse.sensor_data(timestamp);
CREATE INDEX IF NOT EXISTS idx_sensor_data_sensor_id ON lakehouse.sensor_data(sensor_id);
CREATE INDEX IF NOT EXISTS idx_sensor_data_location ON lakehouse.sensor_data(location);
EOF

# Cleanup
unset PGPASSWORD

log "🎉 Data migration completed successfully"
log "📄 Migration log: $LOG_FILE"

echo -e "${GREEN}✅ Enterprise data migration completed!${NC}"
echo -e "${BLUE}📊 Mode: $MODE${NC}"
echo -e "${BLUE}🗄️  Tables created with proper schema${NC}"
echo -e "${BLUE}📄 Log file: $LOG_FILE${NC}"
echo -e "${YELLOW}💡 To verify: psql -h $RDS_ENDPOINT -U admin -d lakehouse${NC}"