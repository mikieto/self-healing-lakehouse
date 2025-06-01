#!/bin/bash
# immediate_cleanup.sh - 即座に実行可能な改善

set -e

echo "🧹 Self-Healing Lakehouse - 即座クリーンアップ実行中..."

# 1. .gitignoreの改善
echo "📝 .gitignore を更新中..."
cat >> .gitignore << 'EOF'

# Terraform
**/.terraform/
**/.terraform.lock.hcl
*.tfstate
*.tfstate.*
*.tfplan
*.tfplan.*

# dbt
dbt/target/
dbt/dbt_packages/
dbt/logs/

# Build artifacts
*.zip
dist/
build/

# Environment files
.env
.env.local

# IDE
.vscode/
.idea/

# Python
__pycache__/
*.pyc
*.pyo
*.pyd
*.egg-info/

# Logs
*.log
logs/

EOF

# 2. dbt targetディレクトリのクリーンアップ
echo "🗑️  dbt build artifacts をクリーンアップ中..."
if [ -d "dbt/target" ]; then
    git rm -r --cached dbt/target/ 2>/dev/null || true
    rm -rf dbt/target/
    echo "✅ dbt/target/ をクリーンアップしました"
fi

# 3. Terraformキャッシュのクリーンアップ
echo "🗑️  Terraform cache をクリーンアップ中..."
if [ -d "terraform/bootstrap/.terraform" ]; then
    git rm -r --cached terraform/bootstrap/.terraform/ 2>/dev/null || true
    rm -rf terraform/bootstrap/.terraform/
    echo "✅ terraform/bootstrap/.terraform/ をクリーンアップしました"
fi

if [ -d "terraform/environments/dev/.terraform" ]; then
    git rm -r --cached terraform/environments/dev/.terraform/ 2>/dev/null || true
    rm -rf terraform/environments/dev/.terraform/
    echo "✅ terraform/environments/dev/.terraform/ をクリーンアップしました"
fi

# 4. ルートレベルのスクリプト整理
echo "📁 スクリプトファイルを整理中..."
mkdir -p scripts/chaos
if [ -f "inject_corrupt_data.sh" ]; then
    mv inject_corrupt_data.sh scripts/chaos/
    echo "✅ inject_corrupt_data.sh → scripts/chaos/ に移動"
fi

# 5. 開発環境用ディレクトリの整理
echo "📁 開発環境を整理中..."
mkdir -p local-dev
if [ -f "docker-compose.yml" ]; then
    mv docker-compose.yml local-dev/
    echo "✅ docker-compose.yml → local-dev/ に移動"
fi

if [ -d "dbt" ]; then
    mv dbt local-dev/
    echo "✅ dbt/ → local-dev/ に移動"
fi

# 6. 基本的なディレクトリ構造を作成
echo "📁 標準的なディレクトリ構造を作成中..."
mkdir -p {src,config,tests}
mkdir -p src/{scripts,utils}
mkdir -p config/{grafana,prometheus}
mkdir -p tests/{unit,integration}

# 7. README の基本構造を改善
echo "📄 README.md を更新中..."
cat > README.md << 'EOF'
# Self-Healing Lakehouse

An enterprise-grade self-healing data lakehouse implementation with AWS services.

## 🏗️ Architecture

- **Data Layer**: S3 + Lake Formation + Glue Catalog
- **Processing**: Glue ETL + Data Quality Jobs  
- **Observability**: Prometheus + Grafana + CloudWatch
- **Automation**: EventBridge + SNS + Self-Healing

## 🚀 Quick Start

```bash
# Setup development environment
make setup

# Deploy infrastructure  
make plan
make apply

# Test self-healing
make chaos-test
```

## 📁 Project Structure

```
├── terraform/           # Infrastructure as Code
├── src/                # Application source code
├── config/             # Configuration files
├── local-dev/          # Local development environment
├── tests/              # Test suites
└── docs/               # Documentation
```

## 🧪 Chaos Engineering

Test the self-healing capabilities:

```bash
# Run chaos script
./scripts/chaos/inject_corrupt_data.sh

# Monitor self-healing process
# - Check Grafana dashboard
# - Review SNS notifications
# - Verify S3 quarantine process
```

## 📖 Documentation

- [Architecture Overview](docs/architecture.md)
- [Deployment Guide](docs/deployment.md)
- [Chaos Engineering](docs/chaos-engineering.md)

EOF

echo ""
echo "✅ 即座クリーンアップ完了！"
echo ""
echo "📋 実行された改善:"
echo "  ✅ .gitignore の改善"
echo "  ✅ dbt/target/ クリーンアップ"
echo "  ✅ .terraform/ キャッシュクリーンアップ"
echo "  ✅ スクリプトファイル整理"
echo "  ✅ 開発環境整理"
echo "  ✅ 標準ディレクトリ構造作成"
echo "  ✅ README.md の改善"
echo ""
echo "🎯 次のステップ:"
echo "  1. git add . && git commit -m '🧹 Project cleanup and reorganization'"
echo "  2. terraform init (各環境で再初期化)"
echo "  3. make plan (動作確認)"
echo ""
echo "⚠️  注意: Terraform再初期化が必要です"