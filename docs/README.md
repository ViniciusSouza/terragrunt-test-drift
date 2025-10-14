# 📚 Drift Detection and Remediation - Documentation Index

This directory contains all documentation related to infrastructure drift detection and remediation for the Terragrunt Test Drift repository.

## 📋 Available Documentation

### 1. 🚨 [Issue Response Template](./ISSUE_RESPONSE.md)
**Purpose**: Quick response template for drift detection issues  
**Use when**: You need to respond to a drift detection alert  
**Contains**:
- Executive summary of detected drift
- Security assessment
- Quick remediation commands
- Validation steps

### 2. 🔧 [Drift Remediation Guide](../DRIFT_REMEDIATION.md)
**Purpose**: Comprehensive analysis and remediation strategies  
**Use when**: You need detailed understanding of drift and all remediation options  
**Contains**:
- Detailed drift analysis for each resource
- Risk assessment (security, operational, compliance)
- Multiple remediation options (revert vs. update)
- Root cause analysis
- Prevention measures for production

### 3. 🚀 [Quick Fix Reference](./drift-quick-fix.md)
**Purpose**: Fast commands for immediate action  
**Use when**: You need to fix drift quickly without reading lengthy docs  
**Contains**:
- One-liner fix commands
- Verification commands
- Expected values after fix
- Quick troubleshooting

## 🛠️ Available Tools

### 1. Automated Fix Script
**Location**: `../scripts/fix-drift.sh`  
**Usage**: `./scripts/fix-drift.sh` or `make fix-drift`  
**Description**: Automated script that:
- Detects current drift
- Prompts for confirmation
- Applies Terraform configuration
- Removes extra resources
- Verifies remediation

### 2. Makefile Targets
**Location**: `../Makefile`  
**Available Commands**:
```bash
make add-drift    # Create drift for testing
make plan         # Detect drift
make fix-drift    # Fix drift automatically
make deploy       # Redeploy infrastructure
```

## 📖 Documentation by Use Case

### I just received a drift detection alert
→ Start with: [ISSUE_RESPONSE.md](./ISSUE_RESPONSE.md)

### I need to understand the drift in detail
→ Read: [DRIFT_REMEDIATION.md](../DRIFT_REMEDIATION.md)

### I need to fix drift immediately
→ Use: [drift-quick-fix.md](./drift-quick-fix.md) or run `make fix-drift`

### I want to prevent drift in production
→ See: [DRIFT_REMEDIATION.md - Prevention Measures](../DRIFT_REMEDIATION.md#prevention-measures)

### I want to test drift detection
→ Follow: [README.md - Understanding Drift Detection](../README.md#-understanding-drift-detection)

## 🔄 Typical Workflow

### Testing Drift Detection (Development)
1. Deploy infrastructure: `make deploy`
2. Create drift: `make add-drift`
3. Detect drift: `make plan`
4. Fix drift: `make fix-drift`
5. Verify: `make plan`

### Responding to Production Drift
1. Read alert and review [ISSUE_RESPONSE.md](./ISSUE_RESPONSE.md)
2. Analyze drift using [DRIFT_REMEDIATION.md](../DRIFT_REMEDIATION.md)
3. Choose remediation approach (revert vs. update)
4. Execute remediation carefully
5. Verify and document

## 🎯 Quick Reference

### File Locations
```
terragrunt-test-drift/
├── DRIFT_REMEDIATION.md          # Main remediation guide
├── docs/
│   ├── README.md                 # This file
│   ├── ISSUE_RESPONSE.md         # Issue response template
│   └── drift-quick-fix.md        # Quick fix commands
├── scripts/
│   ├── create-drift.ps1          # Create drift for testing
│   └── fix-drift.sh              # Automated remediation
└── README.md                      # Repository documentation
```

### Command Quick Reference
```bash
# Drift Detection
make plan                          # Detect drift
terragrunt run-all plan           # Manual drift detection

# Drift Remediation
make fix-drift                     # Automated fix
make deploy                        # Redeploy infrastructure
./scripts/fix-drift.sh            # Run fix script directly

# Drift Creation (Testing)
make add-drift                     # Create test drift
powershell scripts/create-drift.ps1  # Manual drift creation

# Verification
make plan                          # Should show "No changes"
```

## 🔐 Security Considerations

**Critical**: Always review drift before remediation, especially for:
- Security configurations (TLS, encryption, access policies)
- Network configurations (firewalls, routing)
- Data storage resources (databases, storage accounts)
- IAM/RBAC changes

**Best Practices**:
1. Never auto-remediate production without review
2. Always have a rollback plan
3. Document all remediation actions
4. Test remediation in non-production first

## 📞 Support

For questions or issues:
1. Check the relevant documentation above
2. Review the [main README](../README.md)
3. Check the [Terragrunt documentation](https://terragrunt.gruntwork.io/)
4. Review [Azure best practices](https://learn.microsoft.com/azure/)

---

**Last Updated**: 2025-10-14  
**Repository**: [ViniciusSouza/terragrunt-test-drift](https://github.com/ViniciusSouza/terragrunt-test-drift)
