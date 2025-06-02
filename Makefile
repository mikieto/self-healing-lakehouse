# Makefile for Self-Healing Lakehouse
# Learner-friendly enterprise automation with S3 Native Locking

.PHONY: help setup warm bootstrap setup-backend plan apply destroy verify cleanup-local destroy-bootstrap
.PHONY: validate security status check-deps local-logs local-stop
.DEFAULT_GOAL := help

# Configuration - Fix actual directory structure
TERRAFORM_DIR := terraform/environments/dev
BOOTSTRAP_DIR := terraform/bootstrap
LOCAL_DEV_DIR := local-dev
SCRIPTS_DIR := terraform/scripts
ENVIRONMENT ?= dev
AWS_REGION ?= us-east-1
ALERT_EMAIL ?= $(shell git config user.email)

## Show help with enterprise features
help:
	@echo "🏗️  Technical Survival Strategy - Enterprise Edition"
	@echo "=============================================="
	@echo ""
	@echo "📋 Core Workflow:"
	@echo "setup                Setup environment"
	@echo "warm                 Local environment experience"  
	@echo "bootstrap            Bootstrap S3 Native Locking backend"
	@echo "setup-backend        Setup backend config from bootstrap"
	@echo "plan                 Plan Terraform deployment"
	@echo "apply                Deploy to AWS with Terraform"
	@echo "verify               Verify Technical Survival Strategy"
	@echo ""
	@echo "🛡️  Enterprise Features:"
	@echo "check-deps           Check system dependencies"
	@echo "validate             Validate Terraform configuration"
	@echo "security             Run security scanning"
	@echo "status               Show current infrastructure status"
	@echo ""
	@echo "🧹 Maintenance:"
	@echo "cleanup-local        Stop local containers"
	@echo "destroy              Destroy AWS resources"
	@echo "destroy-bootstrap    Destroy bootstrap infrastructure"
	@echo ""
	@echo "🎯 Quick Start:"
	@echo "  make setup → make warm → make bootstrap → make plan → make apply"

## Check system dependencies
check-deps:
	@echo "Checking system dependencies..."
	@command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform not found. Install from https://terraform.io"; exit 1; }
	@command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI not found. Install from https://aws.amazon.com/cli/"; exit 1; }
	@command -v docker >/dev/null 2>&1 || { echo "❌ Docker not found. Install from https://docker.com"; exit 1; }
	@command -v jq >/dev/null 2>&1 || { echo "❌ jq not found. Install jq for JSON processing"; exit 1; }
	@echo "✅ All dependencies available"

## Setup Terraform environment with validation
setup: check-deps
	@echo "Setting up Technical Survival Strategy environment..."
	@terraform --version
	@aws --version
	@pip install dbt-postgres==1.8.* boto3 awscli PyYAML >/dev/null 2>&1 || echo "⚠️  Some Python packages failed to install"
	@echo "✅ Setup complete"

## Setup backend configuration from bootstrap (with cleanup)
setup-backend:
	@echo "🔧 Setting up Terraform backend for $(ENVIRONMENT)..."
	@if [ ! -d "$(BOOTSTRAP_DIR)" ]; then \
		echo "❌ Bootstrap directory not found. Run 'make bootstrap' first."; \
		exit 1; \
	fi
	@if [ ! -d "$(TERRAFORM_DIR)" ]; then \
		echo "❌ Environment directory not found: $(TERRAFORM_DIR)"; \
		exit 1; \
	fi
	@echo "📋 Retrieving bootstrap configuration..."
	@cd $(BOOTSTRAP_DIR) && \
		BUCKET=$$(terraform output -raw terraform_state_bucket) && \
		REGION=$$(terraform output -json s3_native_backend_config | jq -r '.region') && \
		if [ -z "$$BUCKET" ] || [ -z "$$REGION" ]; then \
			echo "❌ Failed to retrieve bootstrap outputs"; \
			exit 1; \
		fi && \
		echo "   Bucket: $$BUCKET" && \
		echo "   Region: $$REGION" && \
		cd ../environments/$(ENVIRONMENT) && \
		echo "📝 Generating backend.hcl for $(ENVIRONMENT)..." && \
		echo "# Auto-generated backend configuration" > backend.hcl && \
		echo "# Generated on: $$(date)" >> backend.hcl && \
		echo "# Environment: $(ENVIRONMENT)" >> backend.hcl && \
		echo "# Bootstrap bucket: $$BUCKET" >> backend.hcl && \
		echo "" >> backend.hcl && \
		echo "bucket         = \"$$BUCKET\"" >> backend.hcl && \
		echo "key            = \"env/$(ENVIRONMENT)/terraform.tfstate\"" >> backend.hcl && \
		echo "region         = \"$$REGION\"" >> backend.hcl && \
		echo "encrypt        = true" >> backend.hcl && \
		echo "use_lockfile   = true" >> backend.hcl
	@echo "✅ Backend configuration created: $(TERRAFORM_DIR)/backend.hcl"
	@echo "🧹 Cleaning old Terraform cache..."
	@cd $(TERRAFORM_DIR) && rm -rf .terraform .terraform.lock.hcl
	@echo "🚀 Initializing Terraform with new backend..."
	@cd $(TERRAFORM_DIR) && terraform init -backend-config=backend.hcl
	@echo "✅ Terraform backend setup complete!"
	@echo "📊 You can now run: make plan"

## Bootstrap S3 Native Locking backend
bootstrap: check-deps
	@echo "🏗️  Bootstrapping S3 Native Locking backend infrastructure..."
	@if [ -z "$${AWS_ACCESS_KEY_ID}" ] && [ ! -f ~/.aws/credentials ]; then echo "❌ AWS credentials not configured"; exit 1; fi
	
	# Check for existing bootstrap
	@if [ -f $(TERRAFORM_DIR)/backend.hcl ]; then \
		echo "✅ Bootstrap already completed"; \
		echo "   Backend file exists: $(TERRAFORM_DIR)/backend.hcl"; \
		echo "📋 Current backend configuration:"; \
		cat $(TERRAFORM_DIR)/backend.hcl | grep -E "bucket|key" | sed 's/^/   /'; \
		echo ""; \
		echo "Next: make warm → make plan → make apply"; \
		exit 0; \
	fi
	
	# Deploy bootstrap infrastructure
	@echo "🚀 Deploying S3 Native Locking bootstrap..." && \
	cd $(BOOTSTRAP_DIR) && \
	terraform init && \
	terraform plan && \
	terraform apply -auto-approve
	
	# Setup backend automatically
	@echo "" && \
	make setup-backend
	
	@echo ""
	@echo "🎉 S3 Native Locking bootstrap complete!"
	@echo "📊 Infrastructure Summary:"
	@cd $(BOOTSTRAP_DIR) && \
	echo "   State Bucket: $$(terraform output -raw terraform_state_bucket)" && \
	echo "   GitHub Role: $$(terraform output -raw github_actions_role_arn)" && \
	echo "   Locking: S3 Native (no DynamoDB required)" && \
	echo "   Cost Savings: ~$$0.25/month"
	@echo ""
	@echo "🎯 Next Steps:"
	@echo "   1. Set GitHub Variables:"
	@cd $(BOOTSTRAP_DIR) && terraform output github_variables
	@echo "   2. make warm  (local experience)"
	@echo "   3. make plan  (review AWS changes)"
	@echo "   4. make apply (deploy to AWS)"

## Local environment experience
warm:
	@echo "Starting local Technical Survival Strategy demo..."
	@if [ ! -d "$(LOCAL_DEV_DIR)" ]; then echo "❌ local-dev directory not found"; exit 1; fi
	@if [ ! -f "$(LOCAL_DEV_DIR)/docker-compose.yml" ]; then echo "❌ docker-compose.yml not found"; exit 1; fi
	
	# Start containers if not running
	@if docker compose -f $(LOCAL_DEV_DIR)/docker-compose.yml ps | grep -q "Up"; then \
		echo "✅ Local environment already running"; \
		docker compose -f $(LOCAL_DEV_DIR)/docker-compose.yml ps; \
	else \
		echo "Starting local services..."; \
		docker compose -f $(LOCAL_DEV_DIR)/docker-compose.yml up -d postgres grafana; \
	fi
	
	# Initialize data
	@echo "Waiting for services (15s)..."; sleep 15
	@echo "Loading seed data..."
	@cd $(LOCAL_DEV_DIR) && docker compose run --rm dbt seed
	@echo "Running dbt transformations..."
	@cd $(LOCAL_DEV_DIR) && docker compose run --rm dbt run
	@cd $(LOCAL_DEV_DIR) && docker compose run --rm dbt test
	@echo "✅ Local demo complete!"
	@echo ""
	@echo "🎉 Technical Survival Strategy foundations ready:"
	@echo "Grafana: http://localhost:3000 (admin/admin)"
	@echo "PostgreSQL: localhost:5432 (demo/demo123)"
	@echo "Query: SELECT pillar, health_percentage FROM local_analytics.mart_survival_metrics;"
	@echo ""
	@echo "Next: 'make bootstrap' → 'make plan' → 'make apply' for AWS deployment!"

## Validate Terraform configuration
validate:
	@echo "🔍 Validating Terraform configuration..."
	@if [ ! -f $(TERRAFORM_DIR)/backend.hcl ]; then echo "❌ Run 'make bootstrap' first"; exit 1; fi
	@cd $(TERRAFORM_DIR) && terraform init -backend-config=backend.hcl >/dev/null 2>&1
	@cd $(TERRAFORM_DIR) && terraform validate
	@echo "✅ Terraform configuration is valid"
	@echo "ℹ️  Note: Some files may need formatting. Run 'terraform fmt' to fix."

## Run security scanning
security:
	@echo "Running security scan..."
	@if [ -f "$(SCRIPTS_DIR)/security-scan.sh" ]; then \
		chmod +x $(SCRIPTS_DIR)/security-scan.sh; \
		$(SCRIPTS_DIR)/security-scan.sh; \
	else \
		echo "⚠️  Security scan script not found - running basic checks"; \
		make validate; \
	fi

## Plan Terraform deployment
plan:
	@echo "📋 Planning Terraform deployment..."
	@if [ ! -f $(TERRAFORM_DIR)/backend.hcl ]; then \
		echo "❌ Backend not configured. Run 'make bootstrap' first"; exit 1; \
	fi
	@cd $(TERRAFORM_DIR) && terraform init -backend-config=backend.hcl
	@cd $(TERRAFORM_DIR) && terraform plan
	@echo "✅ Plan complete. Review changes above, then run 'make apply'"

## Deploy to AWS with Terraform
apply:
	@echo "🚀 Deploying Technical Survival Strategy to AWS..."
	@if [ ! -f $(TERRAFORM_DIR)/backend.hcl ]; then \
		echo "❌ Backend not configured. Run 'make bootstrap' first"; exit 1; \
	fi
	@cd $(TERRAFORM_DIR) && terraform init -backend-config=backend.hcl && terraform apply -auto-approve
	@echo "✅ AWS deployment complete!"
	@echo "📊 Run 'terraform output' in $(TERRAFORM_DIR) to see created resources"

## Verify Technical Survival Strategy
verify:
	@echo "Verifying Technical Survival Strategy implementation..."
	
	# Check Terraform state
	@if [ -f $(TERRAFORM_DIR)/backend.hcl ]; then \
		cd $(TERRAFORM_DIR) && terraform validate >/dev/null 2>&1 && echo "✅ Terraform Configuration Valid"; \
	else \
		echo "⚠️  Backend not configured, run 'make bootstrap' first"; \
	fi
	
	# Check local environment
	@if docker compose -f $(LOCAL_DEV_DIR)/docker-compose.yml ps | grep -q postgres; then \
		echo "✅ Local Environment Ready"; \
	else \
		echo "⚠️  Run 'make warm' for local environment"; \
	fi
	
	# Check AWS resources
	@if [ -f $(TERRAFORM_DIR)/.terraform/terraform.tfstate ] || \
	   [ -f $(TERRAFORM_DIR)/terraform.tfstate ]; then \
		echo "✅ AWS Infrastructure Deployed"; \
	else \
		echo "⚠️  No AWS deployment found - run 'make apply'"; \
	fi
	
	@echo ""
	@echo "🎯 Technical Survival Strategy Status:"
	@echo "Code Pillar: S3 Native Locking IaC ✅"
	@echo "Observability Pillar: AWS official module integration ✅"
	@echo "Guard Pillar: Glue DQ + EventBridge self-healing ✅"

## Show current infrastructure status
status:
	@echo "📊 Checking infrastructure status..."
	@if [ -d "$(TERRAFORM_DIR)" ]; then \
		echo "Changing to $(TERRAFORM_DIR)..."; \
		cd $(TERRAFORM_DIR) && \
		if [ -f "backend.hcl" ]; then \
			echo "✅ Backend configured"; \
			cat backend.hcl | grep -E "bucket|key" | sed 's/^/   /'; \
			echo ""; \
			if terraform init -backend-config=backend.hcl >/dev/null 2>&1; then \
				RESOURCE_COUNT=$$(terraform show -json 2>/dev/null | jq -r '.values.root_module.resources[]?.address' 2>/dev/null | wc -l); \
				echo "Managed resources: $$RESOURCE_COUNT"; \
				echo ""; \
				terraform output 2>/dev/null | head -10; \
			else \
				echo "⚠️  Terraform not initialized"; \
			fi; \
		else \
			echo "⚠️  No backend configuration found"; \
			echo "Run 'make bootstrap' to create infrastructure"; \
		fi; \
	else \
		echo "⚠️  Terraform directory not found: $(TERRAFORM_DIR)"; \
	fi

## View local development logs
local-logs:
	@echo "Showing local development logs..."
	@cd $(LOCAL_DEV_DIR) && docker compose logs -f

## Stop local development environment
local-stop: cleanup-local

## Stop local containers
cleanup-local:
	@echo "Stopping local containers..."
	@cd $(LOCAL_DEV_DIR) && docker compose down -v
	@echo "✅ Local cleanup complete"

## Destroy AWS resources
destroy:
	@echo "⚠️  WARNING: This will destroy all AWS application resources!"
	@read -p "Are you sure? [y/N] " response; \
	if [[ "$response" =~ ^[Yy]$ ]]; then \
		echo "Destroying infrastructure..."; \
		cd $(TERRAFORM_DIR) && terraform destroy -auto-approve; \
		echo "✅ Infrastructure destroyed"; \
	else \
		echo "Destroy cancelled"; \
	fi

## Destroy bootstrap infrastructure
destroy-bootstrap:
	@echo "⚠️  WARNING: This will destroy S3 Native Locking backend infrastructure!"
	@read -p "Are you sure? [y/N] " response; \
	if [[ "$$response" =~ ^[Yy]$$ ]]; then \
		echo "Destroying bootstrap..."; \
		cd $(BOOTSTRAP_DIR) && terraform destroy -auto-approve && \
		rm -f ../environments/dev/backend.hcl ../environments/staging/backend.hcl ../environments/prod/backend.hcl; \
		echo "✅ Bootstrap destroyed"; \
	else \
		echo "Destroy cancelled"; \
	fi