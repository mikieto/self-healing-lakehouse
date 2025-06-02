# Enterprise Self-Healing Data Lakehouse

> **Deploy Enterprise-Grade Data Infrastructure in 15 Minutes**
> 
> AWS Native lakehouse with automatic healing capabilities using official modules only.

## 🏢 What You'll Build

Enterprise-ready Self-Healing Data Lakehouse featuring:

- **70+ AWS Resources** using terraform-aws-modules (zero custom code)
- **Three Pillars Architecture** (Code + Observability + Guard)
- **Production-Ready Security** with OIDC authentication and Lake Formation
- **Automatic Self-Healing** with Glue Data Quality and EventBridge

## 🚀 Quick Start: 15-Minute Enterprise Deployment

### ⚡ GitHub Codespaces (Recommended)

**Zero local setup - everything runs in your browser**

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/mikieto/self-healing-lakehouse)

```bash
# 1. Click the Codespaces button above
# 2. Wait 2 minutes for environment setup  
# 3. Configure AWS credentials (1 minute)
cp .env.sample .env
# Edit .env with your AWS credentials

# 4. Deploy enterprise lakehouse (12 minutes)
make check       # Verify prerequisites
make bootstrap   # Setup AWS backend (3 min)
make plan       # Review infrastructure (2 min)
make apply      # Deploy to AWS (7 min)
```

### 💻 Local Development (Alternative)

**For developers who prefer local setup**

```bash
# 1. Clone and setup (2 minutes)
git clone https://github.com/your-org/self-healing-lakehouse
cd self-healing-lakehouse
cp .env.sample .env
# Edit .env with your AWS credentials

# 2. Verify and deploy (13 minutes)
make check       # Verify prerequisites
make bootstrap   # Setup AWS backend
make plan       # Review infrastructure
make apply      # Deploy to AWS
```

### 📊 What Gets Created

```bash
# Enterprise Infrastructure (70+ resources)
✅ S3 Data Lake with versioning and encryption
✅ AWS Managed Grafana + Prometheus workspaces
✅ Glue Data Quality jobs with self-healing
✅ EventBridge automation + SNS notifications
✅ Enterprise VPC with 3-tier architecture
✅ RDS PostgreSQL with multi-AZ option
✅ OIDC authentication for GitHub Actions
```

## 🎯 Three Pillars Architecture

### 📄 **CODE PILLAR** - Reproducible Infrastructure
- **Terraform IaC** with S3 Native Locking (no DynamoDB needed)
- **AWS Official Modules** only (terraform-aws-modules/*)
- **Zero Custom Code** for maximum maintainability

### 📊 **OBSERVABILITY PILLAR** - Real-time Visibility  
- **AWS Managed Grafana** with enterprise features
- **Prometheus Workspace** for metrics collection
- **CloudWatch Integration** with custom dashboards

### 🛡️ **GUARD PILLAR** - Automatic Protection
- **Glue Data Quality** with automatic validation rules
- **EventBridge Self-Healing** triggers remediation jobs
- **S3 Quarantine** for bad data isolation

## 📋 Prerequisites

### Option A: GitHub Codespaces (Recommended)
```bash
# Everything is pre-installed in Codespaces
✅ terraform >= 1.6
✅ aws-cli v2  
✅ jq
✅ make

# Just add your AWS credentials to .env
```

### Option B: Local Development
```bash
# Install these tools locally
terraform >= 1.6    # For S3 Native Locking
aws-cli v2          # For AWS authentication
jq                  # For JSON processing
make               # Usually pre-installed
```

### AWS Setup
```bash
# 1. Create AWS account with admin access
# 2. Get access keys from AWS Console
# 3. Configure credentials
cp .env.sample .env
# Add: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
```

### Verify Setup
```bash
make check    # Validates all prerequisites
```

## 🔧 Development Workflow

### Safe Enterprise Workflow
```bash
make check      # Verify prerequisites
make fmt        # Format Terraform code
make validate   # Validate syntax
make plan       # Review changes (ALWAYS do this)
make apply      # Deploy to AWS (after plan review)
```

### Available Commands
```bash
make help       # Show all available commands
make bootstrap  # Setup AWS backend infrastructure
make plan       # Show what will be created/changed
make apply      # Deploy lakehouse to AWS
make fmt        # Format Terraform code
make validate   # Validate Terraform configuration
make clean      # Destroy all AWS resources
```

## 🧪 Testing Self-Healing Capabilities

### Upload Test Data
```bash
# 1. Get bucket name
cd terraform/environments/dev
terraform output data_lake_bucket_name

# 2. Upload data to trigger automation
aws s3 cp your-data.csv s3://BUCKET-NAME/raw/

# 3. Watch self-healing in AWS Console:
#    Glue Jobs → EventBridge Rules → SNS Notifications
```

### Monitoring
- **Grafana**: Check workspace in AWS Console
- **CloudWatch**: View custom dashboards
- **EventBridge**: Monitor automation triggers
- **SNS**: Receive notification emails

## 💰 Cost Optimization

### Enterprise Cost Features
- **Serverless Architecture** - Pay only for what you use
- **S3 Native Locking** - Saves ~$0.25/month (no DynamoDB)
- **Auto-scaling** - Resources scale with demand
- **Lifecycle Policies** - Automatic data archiving

### Estimated Monthly Cost
- **Development**: $5-20/month
- **Production**: $50-200/month (depends on data volume)

## 🏗️ Architecture Benefits

### Enterprise-Grade
- **Production Security** with OIDC and Lake Formation
- **Multi-AZ Support** for high availability
- **Encryption** at rest and in transit
- **VPC Isolation** with proper security groups

### Developer-Friendly
- **AWS Official Modules** - tested by millions
- **Zero Custom Code** - no maintenance burden
- **Clear Documentation** - enterprise learning path
- **Safe Workflows** - plan before apply

### Scalable
- **Multi-Environment** ready (dev/staging/prod)
- **Modular Design** - easy to extend
- **Official Modules** - community maintained

## 📚 Learning Path

### Beginner (15 minutes) - GitHub Codespaces
1. Click Codespaces button above
2. Edit `.env` with AWS credentials
3. Run `make check` to verify setup
4. Run `make bootstrap → plan → apply`

### Intermediate (30 minutes)
1. Explore AWS Console resources
2. Upload test data and watch automation
3. Review Terraform code structure
4. Understand three pillars integration

### Advanced (60 minutes)
1. Customize for your organization
2. Add new environments (staging/prod)
3. Integrate with existing systems
4. Implement custom business logic

## 🔧 Troubleshooting

### Common Issues
```bash
# AWS credentials not configured
make check    # Will show specific error

# Terraform version too old
terraform version    # Must be >= 1.6

# Missing tools
make check    # Will list missing dependencies
```

### Getting Help
- Check `make help` for all commands
- Review AWS Console for resource status
- Validate Terraform: `make validate`
- Check credentials: `aws sts get-caller-identity`

## 🚀 Next Steps

### Extend Your Lakehouse
1. **Add Environments**: Copy `dev` to `staging` and `prod`
2. **Custom Data Sources**: Modify Glue jobs for your data
3. **Advanced Monitoring**: Add custom Grafana dashboards
4. **CI/CD Integration**: Use GitHub Actions with OIDC

### Enterprise Integration
1. **Connect to Existing VPC**: Modify network configuration
2. **Custom IAM Policies**: Implement least-privilege access
3. **Data Governance**: Enhance Lake Formation permissions
4. **Compliance**: Add audit trails and logging

---

## 🏆 Enterprise Value

**Built for Production from Day 1**
- ✅ AWS Official Modules (battle-tested)
- ✅ Zero Custom Code (maintenance-free)
- ✅ Enterprise Security (OIDC + Lake Formation)
- ✅ Self-Healing (automatic problem resolution)
- ✅ Cost Optimized (serverless + lifecycle policies)

**Ready for Your Organization**
Deploy enterprise-grade data infrastructure in 15 minutes, not months.