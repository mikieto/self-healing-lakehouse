.PHONY: help setup warm bootstrap plan apply destroy verify cleanup-local destroy-bootstrap

help:
	@echo "Technical Survival Strategy - Terraform Commands"
	@echo "=============================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Setup Terraform environment
	@echo "Setting up Terraform environment..."
	terraform --version
	aws --version
	pip install dbt-postgres==1.8.* boto3 awscli PyYAML >/dev/null
	@echo "Setup complete"

bootstrap: ## Bootstrap Terraform backend (S3 + DynamoDB)
	@echo "Bootstrapping Terraform backend infrastructure..."
	@if [ ! -f .env ]; then echo "ERROR: .env file not found. Copy .env.sample to .env"; exit 1; fi
	@if [ -z "$${AWS_ACCESS_KEY_ID}" ] && [ ! -f ~/.aws/credentials ]; then echo "ERROR: AWS credentials not configured"; exit 1; fi
	@export $$(cat .env | grep -v '^#' | xargs) && \
	if [ -f terraform/environments/dev/backend.hcl ] && aws s3api head-bucket --bucket terraform-state-$$PROJECT_NAME 2>/dev/null; then \
		echo "Bootstrap already completed."; \
		echo "Next: make warm → make plan → make apply"; \
		exit 0; \
	fi
	@export $$(cat .env | grep -v '^#' | xargs) && \
	echo "Deploying bootstrap infrastructure..." && \
	cd terraform/bootstrap && \
	terraform init && \
	terraform plan -var="aws_region=$$AWS_REGION" -var="project_name=$$PROJECT_NAME" -var="environment=$$ENVIRONMENT" -out=bootstrap.tfplan && \
	terraform apply bootstrap.tfplan && \
	terraform output -raw backend_config_hcl > ../environments/dev/backend.hcl
	@echo "Bootstrap complete!"

warm: ## Local environment experience
	@echo "Starting local Technical Survival Strategy demo..."
	@if [ ! -d "local-dev" ]; then echo "ERROR: local-dev directory not found"; exit 1; fi
	@if [ ! -f "local-dev/docker-compose.yml" ]; then echo "ERROR: docker-compose.yml not found"; exit 1; fi
	@if docker compose -f local-dev/docker-compose.yml ps | grep -q "Up"; then \
		echo "Local environment already running"; \
		docker compose -f local-dev/docker-compose.yml ps; \
	else \
		echo "Starting local services..."; \
		docker compose -f local-dev/docker-compose.yml up -d postgres grafana; \
	fi
	@echo "Waiting for services (15s)..."; sleep 15
	@echo "Loading seed data..."
	@cd local-dev && docker compose run --rm dbt seed
	@echo "Running dbt transformations..."
	@cd local-dev && docker compose run --rm dbt run
	@cd local-dev && docker compose run --rm dbt test
	@echo "Local demo complete!"
	@echo ""
	@echo "Technical Survival Strategy foundations ready:"
	@echo "Grafana: http://localhost:3000 (admin/admin)"
	@echo "PostgreSQL: localhost:5432 (demo/demo123)"
	@echo "Query: SELECT pillar, health_percentage FROM local_analytics.mart_survival_metrics;"
	@echo ""
	@echo "Next: 'make bootstrap' → 'make plan' → 'make apply' for AWS deployment!"

plan: ## Plan Terraform deployment
	@echo "Planning Terraform deployment..."
	@if [ ! -f .env ]; then echo "ERROR: .env file not found"; exit 1; fi
	@if [ ! -f terraform/environments/dev/backend.hcl ]; then echo "ERROR: Run 'make bootstrap' first"; exit 1; fi
	@cd terraform/environments/dev && terraform init -backend-config=backend.hcl
	@cd terraform/environments/dev && terraform plan
	@echo "Plan complete. Review changes above, then run 'make apply'"

apply: ## Deploy to AWS with Terraform
	@echo "Deploying Technical Survival Strategy to AWS..."
	@cd terraform/environments/dev && terraform init -backend-config=backend.hcl && terraform apply -auto-approve
	@echo "AWS deployment complete!"

verify: ## Verify Technical Survival Strategy
	@echo "Verifying Technical Survival Strategy implementation..."
	@if [ -f terraform/environments/dev/backend.hcl ]; then \
		cd terraform/environments/dev && terraform validate && echo "Terraform Valid"; \
	else \
		echo "Backend not configured, run 'make bootstrap' first"; \
	fi
	@if docker compose -f local-dev/docker-compose.yml ps | grep -q postgres; then \
		echo "Local Environment Ready"; \
	else \
		echo "Run 'make warm' for local environment"; \
	fi
	@echo ""
	@echo "Technical Survival Strategy Status:"
	@echo "Code Pillar: Terraform unified IaC"
	@echo "Observability Pillar: AWS official module integration"
	@echo "Guard Pillar: Glue DQ + EventBridge self-healing"

cleanup-local: ## Stop local containers
	@echo "Stopping local containers..."
	@cd local-dev && docker compose down -v
	@echo "Local cleanup complete"

destroy: ## Destroy AWS resources
	@echo "WARNING: This will destroy all AWS application resources!"
	@read -p "Are you sure? [y/N] " response; \
	if [[ "$$response" =~ ^[Yy]$$ ]]; then \
		cd terraform/environments/dev && terraform destroy -auto-approve; \
	else echo "Destroy cancelled"; fi

destroy-bootstrap: ## Destroy bootstrap infrastructure
	@echo "WARNING: This will destroy Terraform backend infrastructure!"
	@read -p "Are you sure? [y/N] " response; \
	if [[ "$$response" =~ ^[Yy]$$ ]]; then \
		cd terraform/bootstrap && terraform destroy -auto-approve && \
		rm -f ../environments/dev/backend.hcl; \
	else echo "Destroy cancelled"; fi