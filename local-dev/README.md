# Local Development Environment

This directory is dedicated to local development and learning purposes only. It is NOT deployed to AWS production environment.

## 🎯 Purpose
- Learning and prototyping data transformation logic
- Local proof-of-concept for Self-Healing concepts
- Grafana dashboard development and testing

## 🚀 Usage

```bash
# Start local environment
make warm

# Access services
# Grafana: http://localhost:3000 (admin/admin)
# PostgreSQL: localhost:5432 (demo/demo123)

# Stop environment
make cleanup-local
```

## 📊 Local Data Flow

```
CSV Seeds → PostgreSQL → dbt transformations → Grafana visualization
```

## ⚠️ Important Notes
- Contents of this directory are NOT deployed to AWS
- Production data processing uses Glue ETL Jobs
- This environment is for learning and development only
