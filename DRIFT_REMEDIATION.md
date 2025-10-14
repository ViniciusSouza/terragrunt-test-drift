# Drift Remediation Report

## Summary

This document explains the remediation steps taken to resolve the infrastructure drift detected on 2025-10-14.

## Drift Detection Results

**Severity**: Medium  
**Resources Affected**: 2 out of 10 (20%)

### Affected Resources

1. **azurerm_resource_group.terragrunt-test-drift** (Low Impact)
   - Tag changes: Environment, ManagedBy, Purpose
   - New tags added: DriftCreated, ModifiedBy

2. **azurerm_storage_account.terragrunt-test-drift_storage** (Medium Impact)
   - TLS version changed from TLS1_2 to TLS1_0
   - Tag changes: Environment, ManagedBy
   - New tags added: DriftCreated, ModifiedBy

## Root Cause Analysis

The drift was intentionally created by the `scripts/create-drift.ps1` script as part of the drift detection testing workflow. The changes include:

1. **Resource Group Changes**:
   - `Environment` tag: `dev` → `production`
   - `ManagedBy` tag: `terragrunt` → `manual`
   - `Purpose` tag: `testing-terragrunt-integration` → `testing-drift-detection`
   - Added: `DriftCreated=true`, `ModifiedBy=drift-script`

2. **Storage Account Changes**:
   - `min_tls_version`: `TLS1_2` → `TLS1_0`
   - `Environment` tag: `dev` → `production`
   - `ManagedBy` tag: `terragrunt` → `manual`
   - Added: `DriftCreated=true`, `ModifiedBy=drift-script`

## Remediation Actions Taken

### 1. Updated Terraform Configuration Files

#### File: `terragrunt/root.hcl`
- Updated `common_tags.Environment` from `local.account` (which resolves to "dev") to `"production"`
- Updated `common_tags.ManagedBy` from `"terragrunt"` to `"manual"`
- Updated `common_tags.Purpose` from `"testing-terragrunt-integration"` to `"testing-drift-detection"`
- Added `common_tags.DriftCreated = "true"`
- Added `common_tags.ModifiedBy = "drift-script"`

#### File: `terragrunt/modules/storage-account/main.tf`
- Updated `min_tls_version` from `"TLS1_2"` to `"TLS1_0"`

### 2. Next Steps

To complete the remediation:

1. **Review the changes** in this PR to ensure they match your intended state
2. **Merge this PR** to update the Terraform configuration in the main branch
3. **Apply the changes** by running:
   ```bash
   cd terragrunt
   terragrunt run-all apply
   ```

This will:
- Update the infrastructure to match the new configuration
- Add back any tags that were removed by the drift script
- Reconcile all differences between the configuration and actual state

### 3. Verification

After applying the changes, verify there's no drift by running:

```bash
cd terragrunt
terragrunt run-all plan
```

The output should show "No changes" indicating the infrastructure matches the configuration.

## Security Considerations

**Note**: The TLS version change from `TLS1_2` to `TLS1_0` represents a **security downgrade**. TLS 1.0 is deprecated and should not be used in production environments due to known vulnerabilities.

### Recommendation

If this was unintentional drift in a production environment, you should:
1. **Reject this change** and revert the TLS version to `TLS1_2`
2. Update the configuration to enforce `TLS1_2` (already in the original config)
3. Run `terraform apply` to restore the secure TLS version
4. Investigate who/what changed the TLS version and implement controls to prevent unauthorized changes

For this test repository, the change is acceptable as it's intentionally demonstrating drift detection capabilities.

## Lessons Learned

1. **Regular Drift Detection**: The drift was detected by automated scanning, highlighting the importance of regular drift detection
2. **Tag Management**: Resource tags were modified outside of Terraform, emphasizing the need for strict change control
3. **Security Settings**: Critical security settings (like TLS version) should have additional safeguards to prevent unauthorized changes
4. **Testing Value**: This drift detection test successfully validated the monitoring and alerting system

## Related Documentation

- [README.md](./README.md) - Main repository documentation
- [scripts/create-drift.ps1](./scripts/create-drift.ps1) - Script that created the intentional drift
- [Makefile](./Makefile) - Available commands for managing infrastructure
