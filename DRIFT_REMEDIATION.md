# 🔧 Drift Remediation Guide

## 📋 Executive Summary

This document provides a comprehensive analysis and remediation plan for the infrastructure drift detected on 2025-10-14T09:37:41-04:00.

**Drift Status:**
- **Severity**: Medium
- **Total Resources Scanned**: 10
- **Resources with Drift**: 2 (20.00%)
- **Action Required**: Yes - Configuration update needed

---

## 🔍 Drift Analysis

### 1. Resource Group: `azurerm_resource_group.terragrunt-test-drift`

**Drift Type**: Configuration Modified  
**Impact Level**: Low  
**Root Cause**: Intentional modification via drift simulation script

#### Detected Changes:
- **Environment Tag**: Changed from `dev` → `production`
- **ManagedBy Tag**: Changed from `terragrunt` → `manual`
- **New Tags Added**:
  - `DriftCreated=true`
  - `ModifiedBy=drift-script`
  - `ModifiedAt=<timestamp>`

#### Risk Assessment:
- ✅ **No Security Impact**: Tag changes don't affect resource functionality
- ⚠️ **Operational Impact**: Mismatched tags can cause confusion in resource management
- ⚠️ **Compliance Impact**: Tags may be used for cost allocation and governance

---

### 2. Storage Account: `azurerm_storage_account.terragrunt-test-drift_storage`

**Drift Type**: Security Configuration Modified  
**Impact Level**: Medium  
**Root Cause**: Intentional modification via drift simulation script

#### Detected Changes:
- **TLS Version**: Changed from `TLS1_2` → `TLS1_0`
- **Tags Modified**: Environment, ManagedBy, and drift-tracking tags added
- **Extra Resource**: Additional blob container `drift-test-container` created

#### Risk Assessment:
- 🚨 **Security Impact**: TLS 1.0 is deprecated and insecure
  - Vulnerable to known attacks (BEAST, POODLE)
  - Does not meet modern compliance standards (PCI-DSS, HIPAA)
- ⚠️ **Operational Impact**: Untracked blob container not in IaC
- ⚠️ **Compliance Impact**: May violate security policies

---

## 🛠️ Remediation Plan

### Option 1: Revert to Terraform State (Recommended)

This option will restore resources to match your Terraform configuration, removing all drift.

#### Step 1: Review the Planned Changes
```bash
cd terragrunt
terragrunt run-all plan
```

#### Step 2: Apply Terraform Configuration
```bash
# This will:
# - Reset Resource Group tags to dev/terragrunt
# - Reset Storage Account TLS to TLS1_2
# - Remove drift-tracking tags
# - NOTE: Extra blob container will remain (Terraform doesn't know about it)
terragrunt run-all apply
```

#### Step 3: Remove Extra Blob Container
```bash
# Get storage account name
STORAGE_NAME=$(cd azure/dev/eastus/storage && terragrunt output -raw name)

# Delete extra container
az storage container delete \
  --name drift-test-container \
  --account-name $STORAGE_NAME \
  --auth-mode login
```

#### Step 4: Verify Drift is Resolved
```bash
terragrunt run-all plan
# Should show "No changes. Your infrastructure matches the configuration."
```

---

### Option 2: Update Terraform to Match Current State

If the changes were intentional and you want to keep them, update your Terraform configuration.

#### Step 1: Update Resource Group Tags

Edit `terragrunt/azure/dev/eastus/resource-group/terragrunt.hcl`:

```hcl
inputs = {
  name     = "rg-azure-dev-eastus-drift-test"
  location = "eastus"
  
  resource_tags = {
    Component     = "infrastructure"
    Service       = "shared"
    Environment   = "production"  # Changed from dev
    ManagedBy     = "manual"      # Changed from terragrunt
    DriftCreated  = "true"        # New tag
    ModifiedBy    = "drift-script" # New tag
  }
}
```

#### Step 2: Update Storage Account Configuration

⚠️ **WARNING**: Do NOT keep TLS 1.0 in production. This is a security risk.

If you must update the configuration (not recommended):

Edit `terragrunt/modules/storage-account/main.tf`:

```hcl
resource "azurerm_storage_account" "main" {
  # ... other settings ...
  
  min_tls_version = "TLS1_0"  # ⚠️ INSECURE - NOT RECOMMENDED
  
  tags = merge(var.tags, var.resource_tags)
}
```

**Better approach**: Keep TLS 1.2 and revert the Azure resource:

```bash
STORAGE_NAME=$(cd terragrunt/azure/dev/eastus/storage && terragrunt output -raw name)
RG_NAME=$(cd terragrunt/azure/dev/eastus/resource-group && terragrunt output -raw name)

az storage account update \
  --name $STORAGE_NAME \
  --resource-group $RG_NAME \
  --min-tls-version TLS1_2
```

#### Step 3: Add Blob Container to Terraform (Optional)

If you want to keep the extra container, add it to your configuration:

Edit `terragrunt/modules/storage-account/main.tf`:

```hcl
# Add after the existing container resource
resource "azurerm_storage_container" "drift_test" {
  name                  = "drift-test-container"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}
```

---

## 🔐 Security Recommendations

### Immediate Actions (Critical)
1. ✅ **Revert TLS 1.0 to TLS 1.2** - This is a critical security vulnerability
2. ✅ **Verify no sensitive data in drift-test-container**
3. ✅ **Review access logs for unauthorized access**

### Short-term Actions
1. 📋 **Implement drift detection automation** - Set up scheduled drift checks
2. 🔒 **Enable Azure Policy** - Prevent TLS version downgrades
3. 📝 **Document change management process** - Require all changes through Terraform

### Long-term Actions
1. 🛡️ **Implement resource locks** - Prevent manual changes in production
2. 📊 **Set up monitoring** - Alert on configuration changes
3. 🔄 **CI/CD integration** - Automated drift detection in pipeline

---

## 📝 Root Cause Analysis

### How Did This Drift Occur?

Based on the analysis of the repository, this drift was **intentionally created** for testing purposes using the `scripts/create-drift.ps1` script. The script:

1. Modified Resource Group tags to simulate tag drift
2. Changed Storage Account TLS version to demonstrate security drift
3. Created an extra blob container to show resource drift

### Prevention Measures

For production environments, implement these controls:

1. **Resource Locks**: Apply `CanNotDelete` or `ReadOnly` locks
   ```bash
   az lock create --name PreventDrift \
     --lock-type CanNotDelete \
     --resource-group $RG_NAME
   ```

2. **Azure Policy**: Enforce minimum TLS version
   ```json
   {
     "mode": "All",
     "policyRule": {
       "if": {
         "allOf": [
           {
             "field": "type",
             "equals": "Microsoft.Storage/storageAccounts"
           },
           {
             "field": "Microsoft.Storage/storageAccounts/minimumTlsVersion",
             "notEquals": "TLS1_2"
           }
         ]
       },
       "then": {
         "effect": "deny"
       }
     }
   }
   ```

3. **RBAC**: Restrict who can modify resources
4. **Automated Drift Detection**: Use tools like Terraform Cloud, Azure DevOps, or GitHub Actions

---

## ✅ Validation Steps

After remediation, verify the fix:

### 1. Check Terraform Plan
```bash
cd terragrunt
terragrunt run-all plan
# Expected: No changes needed
```

### 2. Verify Resource Configuration
```bash
# Check Resource Group
RG_NAME=$(cd azure/dev/eastus/resource-group && terragrunt output -raw name)
az group show --name $RG_NAME --query tags

# Check Storage Account
STORAGE_NAME=$(cd azure/dev/eastus/storage && terragrunt output -raw name)
az storage account show \
  --name $STORAGE_NAME \
  --resource-group $RG_NAME \
  --query "{tls:minimumTlsVersion,tags:tags}"
```

### 3. List Storage Containers
```bash
az storage container list \
  --account-name $STORAGE_NAME \
  --auth-mode login \
  --query "[].name"
# Should match containers defined in Terraform
```

---

## 📞 Support and Documentation

- 📚 [Terragrunt Documentation](https://terragrunt.gruntwork.io/)
- 🔧 [Azure Storage Security Best Practices](https://learn.microsoft.com/azure/storage/common/storage-security-guide)
- 🛡️ [Azure Policy Samples](https://github.com/Azure/azure-policy)
- 📖 [Repository README](./README.md)

---

## 🎯 Quick Commands Reference

### For Test Environment (This Repository)
```bash
# Apply Terraform to fix drift
make deploy

# Or manually:
cd terragrunt
terragrunt run-all apply

# Verify fix
terragrunt run-all plan
```

### For Production Environment
```bash
# 1. Review changes carefully
terragrunt run-all plan -out=tfplan

# 2. Review the plan file
terragrunt show tfplan

# 3. Apply only if changes are expected
terragrunt run-all apply tfplan

# 4. Verify
terragrunt run-all plan
```

---

**Document Version**: 1.0  
**Last Updated**: 2025-10-14  
**Next Review**: After drift remediation
