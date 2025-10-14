# 🚀 Quick Drift Fix Guide

A fast reference for fixing common drift scenarios in this Terragrunt test environment.

## 🎯 Quick Fix Commands

### Option A: Revert All Drift (Recommended for Test Environment)

```bash
# Navigate to terragrunt directory
cd terragrunt

# Review what will change
terragrunt run-all plan

# Apply to revert drift
terragrunt run-all apply

# Clean up extra resources not in Terraform
STORAGE_NAME=$(cd azure/dev/eastus/storage && terragrunt output -raw name)
az storage container delete \
  --name drift-test-container \
  --account-name $STORAGE_NAME \
  --auth-mode login

# Verify no drift remains
terragrunt run-all plan
```

### Option B: Use Makefile (Even Faster)

```bash
# From repository root
make deploy

# Verify
make plan
```

---

## 🔍 Understanding the Detected Drift

### Resource Group Drift
- **What changed**: Tags (Environment, ManagedBy)
- **Fix**: Run `terragrunt apply` to revert tags
- **Impact**: Low - tags don't affect functionality

### Storage Account Drift
- **What changed**: 
  - TLS version downgraded from 1.2 to 1.0 ⚠️
  - Tags modified
  - Extra blob container created
- **Fix**: Run `terragrunt apply` + manual container cleanup
- **Impact**: Medium - TLS 1.0 is a security risk

---

## ⚡ One-Liner Fixes

### Fix Resource Group Tags Only
```bash
cd terragrunt/azure/dev/eastus/resource-group && terragrunt apply -auto-approve
```

### Fix Storage Account Only
```bash
cd terragrunt/azure/dev/eastus/storage && terragrunt apply -auto-approve
```

### Delete Extra Blob Container
```bash
az storage container delete \
  --name drift-test-container \
  --account-name $(cd terragrunt/azure/dev/eastus/storage && terragrunt output -raw name) \
  --auth-mode login
```

---

## 📊 Verification Commands

### Check Current State
```bash
# Resource Group
RG_NAME=$(cd terragrunt/azure/dev/eastus/resource-group && terragrunt output -raw name)
az group show --name $RG_NAME --query "{name:name,tags:tags}" -o json

# Storage Account
STORAGE_NAME=$(cd terragrunt/azure/dev/eastus/storage && terragrunt output -raw name)
RG_NAME=$(cd terragrunt/azure/dev/eastus/resource-group && terragrunt output -raw name)
az storage account show \
  --name $STORAGE_NAME \
  --resource-group $RG_NAME \
  --query "{name:name,tls:minimumTlsVersion,tags:tags}" -o json

# List containers
az storage container list \
  --account-name $STORAGE_NAME \
  --auth-mode login \
  --query "[].name" -o table
```

### Expected Values After Fix

**Resource Group Tags:**
```json
{
  "Environment": "dev",
  "ManagedBy": "terragrunt",
  "Project": "drift-detector-test",
  "Purpose": "testing-terragrunt-integration",
  "CloudProvider": "azure",
  "Region": "eastus",
  "ResourceType": "resource-group",
  "Component": "infrastructure",
  "Service": "shared"
}
```

**Storage Account:**
- `minimumTlsVersion`: `TLS1_2`
- Containers: Only `test-container` (if enabled)
- Tags: Should match Terraform configuration

---

## 🔄 Re-create Drift (For Testing)

If you want to test drift detection again:

```bash
# From repository root
make add-drift

# Then check for drift
make plan
```

---

## 🛑 When NOT to Auto-Fix

Don't automatically apply fixes if:
- ❌ You're in a **production environment**
- ❌ The changes might be **intentional**
- ❌ You haven't **reviewed the plan** output
- ❌ The drift involves **sensitive resources** (databases, secrets)

Always review the `terragrunt plan` output before applying changes!

---

## 📖 More Information

See [DRIFT_REMEDIATION.md](../DRIFT_REMEDIATION.md) for detailed analysis and remediation strategies.
