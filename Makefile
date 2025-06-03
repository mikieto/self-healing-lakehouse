# Enterprise Self-Healing Data Lakehouse
# AWS Official Modules + Zero Custom Code
.PHONY: help check bootstrap plan apply fmt validate clean
.DEFAULT_GOAL := help

# Configuration
BOOTSTRAP_DIR := terraform/bootstrap
ENV_DIR := terraform/environments/dev

# Load .env file if it exists
ifneq (,$(wildcard .env))
    include .env
    export
endif

## What you can do and how to do it
help:
	@echo "🚀 Self-Healing Data Lakehouse"
	@echo "=============================="
	@echo ""
	@echo "💡 What you can build:"
	@echo "  📊 Enterprise data lakehouse with automatic healing"
	@echo "  🏗️ 70+ AWS resources using official modules only"
	@echo "  🛡️ Production-ready security and monitoring"
	@echo ""
	@echo "⚡ How to build it:"
	@echo "  make check        Check all prerequisites"
	@echo "  make bootstrap    Setup AWS backend (3 min)"
	@echo "  make plan         Review what will be created"
	@echo "  make apply        Build the lakehouse (10 min)"
	@echo "  make clean        Remove everything"
	@echo ""
	@echo "🔧 Development commands:"
	@echo "  make fmt          Format Terraform code"
	@echo "  make validate     Validate Terraform syntax"
	@echo ""
	@echo "📋 Prerequisites:"
	@echo "  1. Copy: cp .env.sample .env"
	@echo "  2. Edit: Add your AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY"
	@echo "  3. Check: make check"
	@echo ""
	@echo "🎯 Safe workflow:"
	@echo "  1. make check"
	@echo "  2. make bootstrap"
	@echo "  3. make plan      ← Review before applying"
	@echo "  4. make apply     ← Only after plan review"

## Check all prerequisites
check:
	@echo "🔍 Checking prerequisites..."
	@echo ""
	@echo "📋 Required tools:"
	@command -v terraform >/dev/null 2>&1 && echo "  ✅ Terraform installed" || { echo "  ❌ Terraform missing - Install from https://terraform.io"; exit 1; }
	@command -v aws >/dev/null 2>&1 && echo "  ✅ AWS CLI installed" || { echo "  ❌ AWS CLI missing - Install from https://aws.amazon.com/cli/"; exit 1; }
	@command -v jq >/dev/null 2>&1 && echo "  ✅ jq installed" || { echo "  ❌ jq missing - Install with: brew install jq (Mac) or apt install jq (Linux)"; exit 1; }
	@echo ""
	@echo "🔐 AWS credentials:"
	@if [ -n "$(AWS_ACCESS_KEY_ID)" ] && [ -n "$(AWS_SECRET_ACCESS_KEY)" ]; then \
		echo "  ✅ AWS credentials found in environment"; \
		aws sts get-caller-identity >/dev/null 2>&1 && echo "  ✅ AWS credentials valid" || echo "  ❌ AWS credentials invalid"; \
	else \
		echo "  ❌ AWS credentials missing"; \
		echo "     Please copy .env.sample to .env and add your credentials"; \
		exit 1; \
	fi
	@echo ""
	@echo "📁 Project structure:"
	@[ -d "$(BOOTSTRAP_DIR)" ] && echo "  ✅ Bootstrap directory exists" || { echo "  ❌ Missing $(BOOTSTRAP_DIR)"; exit 1; }
	@[ -d "$(ENV_DIR)" ] && echo "  ✅ Environment directory exists" || { echo "  ❌ Missing $(ENV_DIR)"; exit 1; }
	@echo ""
	@echo "✅ All prerequisites met! Ready to run 'make bootstrap'"

## Setup AWS backend infrastructure
bootstrap:
	@echo "🔧 Setting up AWS backend..."
	@make check
	@cd $(BOOTSTRAP_DIR) && terraform init && terraform apply -auto-approve
	@cd $(BOOTSTRAP_DIR) && \
		BUCKET=$$(terraform output -raw terraform_state_bucket) && \
		cd ../environments/dev && \
		echo "bucket = \"$$BUCKET\"" > backend.hcl && \
		echo "key = \"terraform.tfstate\"" >> backend.hcl && \
		echo "region = \"$(shell aws configure get region)\"" >> backend.hcl && \
		echo "encrypt = true" >> backend.hcl
	@echo "✅ Backend ready. Next: make plan"

## Format Terraform code
fmt:
	@echo "🎨 Formatting Terraform code..."
	@terraform fmt -recursive terraform/
	@echo "✅ Code formatted"

## Validate Terraform configuration
validate:
	@echo "🔍 Validating Terraform configuration..."
	@[ -f $(ENV_DIR)/backend.hcl ] || { echo "❌ Run 'make bootstrap' first"; exit 1; }
	@cd $(ENV_DIR) && terraform init -backend-config=backend.hcl >/dev/null
	@cd $(ENV_DIR) && terraform validate
	@echo "✅ Configuration valid"

## Show what will be created (safe to run)
plan:
	@echo "📋 Planning lakehouse deployment..."
	@[ -f $(ENV_DIR)/backend.hcl ] || { echo "❌ Run 'make bootstrap' first"; exit 1; }
	@cd $(ENV_DIR) && terraform init -backend-config=backend.hcl
	@cd $(ENV_DIR) && terraform plan
	@echo ""
	@echo "💡 Review the plan above. If it looks good, run: make apply"

## Deploy the lakehouse to AWS (requires plan review)
apply:
	@echo "🚀 Deploying lakehouse..."
	@[ -f $(ENV_DIR)/backend.hcl ] || { echo "❌ Run 'make bootstrap' first"; exit 1; }
	@echo "⚠️  This will create real AWS resources and incur costs"
	@read -p "Did you review the plan? Continue? [y/N] " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		cd $(ENV_DIR) && terraform init -backend-config=backend.hcl; \
		cd $(ENV_DIR) && terraform apply; \
		echo "✅ Lakehouse deployed!"; \
		echo "🎯 Check AWS Console for your resources"; \
	else \
		echo "❌ Deployment cancelled. Run 'make plan' first"; \
	fi

## Remove all AWS resources
clean:
	@echo "🧹 Cleaning up AWS resources..."
	@echo "⚠️  This will destroy all infrastructure and data"
	@read -p "Are you sure? [y/N] " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		if [ -f $(ENV_DIR)/backend.hcl ]; then \
			cd $(ENV_DIR) && terraform destroy; \
		fi; \
		if [ -d $(BOOTSTRAP_DIR) ]; then \
			cd $(BOOTSTRAP_DIR) && terraform destroy; \
		fi; \
		rm -f $(ENV_DIR)/backend.hcl; \
		echo "✅ All resources destroyed"; \
	else \
		echo "❌ Cleanup cancelled"; \
	fi

# Version-aware deployment commands
apply-versioned:
	@echo "🔄 Deploying with Git version tracking..."
	@GIT_HASH=$$(git rev-parse HEAD) && \
	TIMESTAMP=$$(date -u +"%Y-%m-%dT%H:%M:%SZ") && \
	USER_INFO=$$(git config user.name || echo "unknown") && \
	cd terraform/environments/dev && \
	terraform apply \
		-var="git_commit_hash=$$GIT_HASH" \
		-var="deployment_timestamp=$$TIMESTAMP" \
		-var="deployed_by=$$USER_INFO"

# Check deployed versions
check-versions:
	@echo "📋 Checking deployed script versions..."
	@BUCKET=$$(cd terraform/environments/dev && terraform output -raw data_lake_bucket_name 2>/dev/null) && \
	if [ -n "$$BUCKET" ]; then \
		echo "🔍 Version metadata:"; \
		aws s3 cp s3://$$BUCKET/scripts/.versions.json - | jq '.'; \
	else \
		echo "❌ Bucket not found. Deploy infrastructure first."; \
	fi

# Show version history
version-history:
	@echo "📈 Deployment version history..."
	@aws logs describe-log-streams \
		--log-group-name "/aws/terraform/script-deployment" \
		--query 'logStreams[].logStreamName' \
		--output table

# Compare versions
compare-versions:
	@echo "🔍 Comparing current vs deployed versions..."
	@GIT_HASH=$$(git rev-parse HEAD) && \
	BUCKET=$$(cd terraform/environments/dev && terraform output -raw data_lake_bucket_name 2>/dev/null) && \
	if [ -n "$$BUCKET" ]; then \
		DEPLOYED_HASH=$$(aws s3 cp s3://$$BUCKET/scripts/.versions.json - | jq -r '.deployment_info.git_commit'); \
		echo "📊 Current Git commit: $$GIT_HASH"; \
		echo "📊 Deployed commit: $$DEPLOYED_HASH"; \
		if [ "$$GIT_HASH" = "$$DEPLOYED_HASH" ]; then \
			echo "✅ Versions match - no deployment needed"; \
		else \
			echo "⚠️  Version mismatch - consider running 'make apply-versioned'"; \
		fi; \
	else \
		echo "❌ Cannot compare - infrastructure not deployed"; \
	fi