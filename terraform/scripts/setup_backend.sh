#!/bin/bash
# terraform/scripts/setup_backend.sh
# Dynamic Terraform backend configuration generator

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_ROOT="$(dirname "$SCRIPT_DIR")"
BOOTSTRAP_DIR="$TERRAFORM_ROOT/bootstrap"
ENVIRONMENT="${1:-dev}"
ENV_DIR="$TERRAFORM_ROOT/environments/$ENVIRONMENT"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔧 Setting up Terraform backend for environment: $ENVIRONMENT${NC}"

# Check if bootstrap directory exists
if [ ! -d "$BOOTSTRAP_DIR" ]; then
    echo -e "${YELLOW}⚠️  Bootstrap directory not found. Run bootstrap first.${NC}"
    exit 1
fi

# Check if environment directory exists
if [ ! -d "$ENV_DIR" ]; then
    echo -e "${YELLOW}⚠️  Environment directory not found: $ENV_DIR${NC}"
    exit 1
fi

# Get bootstrap outputs
echo -e "${BLUE}📋 Retrieving bootstrap configuration...${NC}"
cd "$BOOTSTRAP_DIR"

# Extract backend configuration from bootstrap
BUCKET=$(terraform output -raw terraform_state_bucket)
REGION=$(terraform output -json bootstrap_info | jq -r '.aws_region')

if [ -z "$BUCKET" ] || [ -z "$REGION" ]; then
    echo -e "${YELLOW}⚠️  Failed to retrieve bootstrap outputs${NC}"
    exit 1
fi

# Generate backend.hcl
echo -e "${BLUE}📝 Generating backend.hcl for $ENVIRONMENT...${NC}"
cd "$ENV_DIR"

cat > backend.hcl << EOF
# Auto-generated backend configuration
# Generated on: $(date)
# Environment: $ENVIRONMENT
# Bootstrap bucket: $BUCKET

bucket         = "$BUCKET"
key            = "env/$ENVIRONMENT/terraform.tfstate"
region         = "$REGION"
encrypt        = true
use_lockfile   = true
EOF

echo -e "${GREEN}✅ Backend configuration created: $ENV_DIR/backend.hcl${NC}"

# Initialize Terraform
echo -e "${BLUE}🚀 Initializing Terraform...${NC}"
terraform init -backend-config=backend.hcl

echo -e "${GREEN}✅ Terraform backend setup complete!${NC}"
echo -e "${BLUE}📊 You can now run: terraform plan${NC}"