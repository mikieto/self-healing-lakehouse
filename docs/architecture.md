# Self-Healing Lakehouse Architecture

## 🏗️ Overall Architecture

### Local Development Environment
```
┌─────────────────────────────────────────┐
│            Local Development            │
├─────────────────────────────────────────┤
│ Docker Compose                          │
│ ├── PostgreSQL (demo data)              │
│ ├── Grafana (dashboards)                │
│ └── dbt (data transformations)          │
└─────────────────────────────────────────┘
```

### AWS Production Environment  
```
┌─────────────────────────────────────────┐
│             Data Layer                  │
├─────────────────────────────────────────┤
│ ├── S3 (Data Lake)                      │
│ ├── Lake Formation (Governance)         │
│ └── Glue Catalog (Metadata)             │
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│           Processing Layer              │
├─────────────────────────────────────────┤
│ ├── Glue Crawler (Schema Discovery)     │
│ ├── Glue Jobs (Data Quality)            │
│ └── Glue Jobs (Remediation)             │
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│          Self-Healing Layer             │
├─────────────────────────────────────────┤
│ ├── EventBridge (Event Detection)       │
│ ├── SNS (Notifications)                 │
│ └── Lambda (Chaos Engineering)          │
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│         Observability Layer             │
├─────────────────────────────────────────┤
│ ├── Prometheus (Metrics)                │
│ ├── Grafana (Dashboards)                │
│ └── CloudWatch (AWS Metrics)            │
└─────────────────────────────────────────┘
```

## 🔄 Data Flow

### Local Development Flow
1. **Seed Data** → PostgreSQL
2. **dbt Transformations** → Analytics Tables  
3. **Grafana** → Visualizations

### AWS Production Flow
1. **Raw Data** → S3 Bucket
2. **Glue Crawler** → Schema Discovery
3. **Glue Data Quality** → Validation
4. **EventBridge** → Failure Detection
5. **Self-Healing** → Automatic Remediation
6. **Observability** → Monitoring & Alerts

## 🎯 Key Design Principles

- **Separation of Concerns**: Local vs AWS environments
- **Self-Healing**: Automatic failure detection & recovery
- **Observability**: Comprehensive monitoring & alerting
- **Infrastructure as Code**: Terraform for all AWS resources
