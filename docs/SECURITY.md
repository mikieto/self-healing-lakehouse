# 🔒 Security Guidelines - Self-Healing Lakehouse

## ⚠️ **CRITICAL: Never Commit These Files**

### **🚨 HIGH RISK - AWS Credentials**
```bash
.env                    # Contains AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
.env.local             # Local environment overrides
.aws/credentials       # AWS CLI credentials file
```

### **🚨 HIGH RISK - Terraform State**
```bash
*.tfstate              # Contains all infrastructure details and secrets
*.tfstate.backup       # Backup state files
.terraform/            # Working directory with cached credentials
```

## ✅ **Safe Files to Commit**
```bash
.env.sample            # Template file (no real credentials)
.gitignore             # Security configuration
*.tf                   # Terraform configuration files (no secrets)
docker-compose.yml     # Infrastructure as code
Makefile              # Build automation
```

## 🛡️ **Security Best Practices**

### **1. Check Before Committing**
```bash
# Always check what you're committing
git status
git diff --cached

# Verify .env is NOT in the staging area
git ls-files | grep -E "\.env$|\.tfstate$"
```

### **2. Emergency: If You Accidentally Committed Secrets**
```bash
# 1. Immediately rotate AWS credentials in AWS Console
# 2. Remove from Git history (if public repo)
git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch .env' --prune-empty --tag-name-filter cat -- --all

# 3. Force push (DANGEROUS - use with caution)
git push --force-with-lease --all
```

### **3. Verify .gitignore is Working**
```bash
# Create test .env file
echo "TEST_SECRET=test123" > .env

# Check it's ignored
git status
# Should NOT show .env as untracked file

# Clean up test
rm .env
```

## 🔍 **Security Verification Checklist**

Before any `git push`:

- [ ] `.env` file is NOT tracked by Git
- [ ] `*.tfstate` files are NOT tracked by Git
- [ ] AWS credentials are NOT in any committed files
- [ ] `.gitignore` includes all sensitive file patterns
- [ ] `git status` shows no sensitive files

## 📚 **Educational Note**

This project demonstrates **Infrastructure as Code** security:

- **Public**: Configuration files (`.tf`, `docker-compose.yml`)
- **Private**: Credentials and state (`.env`, `*.tfstate`)
- **Template**: Examples without secrets (`.env.sample`)

## 🆘 **If Something Goes Wrong**

1. **Stop immediately** - don't push anything
2. **Rotate credentials** in AWS Console
3. **Clean Git history** if needed
4. **Ask for help** - security mistakes happen, quick response matters

Remember: **Security is everyone's responsibility!** 🛡️