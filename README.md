# Technical Survival Strategy - Self-Healing Lakehouse

> **Experience the Future of Data Infrastructure in 30 Minutes**
> 
> From zero to complete Data Lakehouse with automated healing capabilities.

## 🎯 What You'll Experience

Transform from an empty environment to a production-ready Data Lakehouse featuring:

- **Real-time Data Pipeline** with automatic quality validation
- **Self-Healing Monitoring** with Grafana dashboards  
- **Enterprise-Ready Architecture** deployable to AWS in 45 minutes

## 🚀 Quick Start: The 30-Second Miracle

### ⚡ Instant Start with GitHub Codespaces (Recommended)

**No setup required - runs in your browser**

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/mikieto/self-healing-lakehouse)

```bash
# 1. Click the Codespaces button above
# 2. Wait 2 minutes for environment setup
# 3. Run one command:
make warm

# 4. Experience the complete Data Lakehouse in 30 minutes:
#    ✅ PostgreSQL data foundation
#    ✅ dbt transformations  
#    ✅ Grafana real-time dashboards
#    ✅ Automated quality validation

# 5. Explore the results:
#    📊 Grafana: http://localhost:3000 (admin/admin)
#    🗄️ PostgreSQL: localhost:5432 (demo/demo123)
```

### 🏢 Deploy to Your AWS Account (Optional)

*Scale to enterprise production when ready*

```bash
# 1. Configure AWS credentials in Codespaces
cp .env.sample .env
# Edit .env with your AWS settings

# 2. Deploy to your AWS account
make bootstrap  # Setup AWS backend
make plan      # Review infrastructure 
make apply     # Deploy to production
```

### 💻 Local Development (Advanced)

*For developers who want to modify the code*

```bash
git clone https://github.com/your-org/self-healing-lakehouse.git
cd self-healing-lakehouse
make warm
```

## 🏗️ Three Pillars Architecture

| Pillar | Local Environment | AWS Production |
|--------|------------------|----------------|
| **Code** | PostgreSQL + dbt | RDS + Glue |
| **Observability** | Grafana + Prometheus | CloudWatch + QuickSight |
| **Guard** | dbt tests + validations | EventBridge + Auto-healing |

## 🎓 Learning Path

1. **Experience** (30 min): Run `make warm` and explore the results
2. **Understand** (15 min): Examine the [Architecture Guide](docs/ARCHITECTURE.md)
3. **Deploy** (45 min): Follow [AWS Deployment Guide](docs/AWS_DEPLOYMENT.md)
4. **Customize** (∞): Adapt for your enterprise needs

## 📊 What Makes This Special

- **Zero to Lakehouse**: Complete data infrastructure in 30 minutes
- **Self-Healing**: Automatic detection and recovery from failures
- **Enterprise-Ready**: Production-grade security and scalability
- **Cost-Effective**: Pay only for what you use, scale automatically

## 🎯 Expected Results

After `make warm` completes:

```
✅ Local demo complete!

🎯 Technical Survival Strategy foundations ready:
📈 Grafana: http://localhost:3000 (admin/admin)
🗄️ PostgreSQL: localhost:5432 (demo/demo123)
💡 Query: SELECT pillar, health_percentage FROM local_analytics.mart_survival_metrics;

🚀 Next: 'make bootstrap' → 'make plan' → 'make apply' for AWS deployment!
```

## 📚 Documentation

- [Quick Start Guide](docs/QUICKSTART.md) - Detailed walkthrough
- [Architecture Overview](docs/ARCHITECTURE.md) - Technical deep-dive
- [AWS Deployment](docs/AWS_DEPLOYMENT.md) - Production setup
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues

## 🎊 The Big Picture

This repository demonstrates how modern data infrastructure can be:
- **Built in minutes**, not months
- **Self-managing**, not maintenance-heavy
- **Cloud-native**, not vendor-locked
- **AI-ready**, not legacy-bound

Experience the future of data engineering. Start with `make warm`.