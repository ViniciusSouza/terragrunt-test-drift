# Terragrunt Test Configuration

This directory contains the Terragrunt configuration for testing the Epic 0.8 Terragrunt integration. It demonstrates the customer's actual usage pattern with monorepo structure and dependency management.

## 🏗️ Directory Structure

```
terragrunt/
├── terragrunt.hcl                    # Root configuration with common settings
├── azure/                            # Cloud provider level
│   └── dev/                          # Account/Environment level
│       └── eastus/                   # Region level
│           ├── resource-group/       # Resource type level
│           │   └── terragrunt.hcl    # Resource configuration
│           └── storage/              # Resource type level
│               └── terragrunt.hcl    # Resource configuration (depends on RG)
└── modules/                          # Shared Terraform modules
    ├── resource-group/               # Resource Group module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── storage-account/              # Storage Account module
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## 🎯 Customer Pattern Implementation

This configuration implements the customer's actual monorepo pattern:
- **Path Structure**: `{cloud-provider}/{account}/{region}/{resource-type}/{resource-name}`
- **Dependency Management**: Storage account depends on resource group
- **Tag Inheritance**: Common tags from root + resource-specific tags
- **Naming Conventions**: Consistent naming across environments

## 🚀 Quick Start

### Prerequisites
- Terragrunt installed (`choco install terragrunt` or download from releases)
- Azure CLI logged in (`az login`)
- Appropriate Azure permissions for creating resources

### Running Tests

```powershell
# Full end-to-end test
.\test-terragrunt-integration.ps1

# Setup only (don't run drift detection)
.\test-terragrunt-integration.ps1 -SetupOnly

# Cleanup only
.\test-terragrunt-integration.ps1 -CleanupOnly

# Test drift detection without applying resources
.\test-terragrunt-integration.ps1 -SkipApply
```

### Manual Testing

```bash
# Navigate to terragrunt directory
cd terragrunt

# Plan all resources
terragrunt run-all plan

# Apply all resources
terragrunt run-all apply

# Check dependencies
terragrunt graph-dependencies

# Destroy all resources
terragrunt run-all destroy
```

## 🔍 Drift Detection Testing

The configuration is designed to test these Epic 0.8 features:

### Core Terragrunt Integration
- [x] **Folder Discovery**: Automatically find `terragrunt.hcl` files
- [x] **Monorepo Support**: Handle complex directory structures
- [x] **Dependency Detection**: Identify resource dependencies
- [x] **Command Execution**: Run `terragrunt plan` with proper context

### Enhanced Filtering
- [x] **Severity Assessment**: Classify drift by environment and resource type
- [x] **Path-based Filtering**: Include/exclude based on directory patterns  
- [x] **Resource Type Classification**: Categorize resources (infrastructure, data, compute)

### Report Enhancement
- [x] **Terragrunt Metadata**: Include Terragrunt-specific information in reports
- [x] **Dependency Information**: Report on resource relationships
- [x] **Severity Levels**: Assign appropriate severity based on resource importance

## 🧪 Test Scenarios

### Scenario 1: Clean State (No Drift)
1. Apply Terragrunt configuration
2. Run drift detection immediately
3. Expected: No drift detected

### Scenario 2: Manual Drift Introduction
1. Apply Terragrunt configuration  
2. Manually modify resources in Azure portal
3. Run drift detection
4. Expected: Drift detected with proper classification

### Scenario 3: Dependency Testing
1. Apply only resource group
2. Run drift detection on storage (should handle missing dependency)
3. Apply storage account
4. Run drift detection again

### Scenario 4: Filtering and Severity
1. Test path-based filtering (dev vs prod paths)
2. Test resource type classification
3. Verify severity assignment based on patterns

## ⚙️ Configuration Files

### `.picpay-drift-config-terragrunt.yaml`
Enhanced configuration for Terragrunt integration:
- Terragrunt-specific settings
- Monorepo configuration
- Severity level definitions
- Enhanced issue templates

### Root `terragrunt.hcl`
- Common provider configuration
- Remote state setup (local backend for testing)
- Tag standardization
- Input variable inheritance

### Resource-specific `terragrunt.hcl` files
- Module source references
- Dependency declarations
- Resource-specific inputs
- Local variable definitions

## 🔧 Troubleshooting

### Common Issues

**Terragrunt not found**
```powershell
# Install via Chocolatey
choco install terragrunt

# Or download from GitHub releases
# https://github.com/gruntwork-io/terragrunt/releases
```

**Azure authentication errors**
```bash
# Login to Azure CLI
az login

# Verify active subscription
az account show

# Set specific subscription if needed
az account set --subscription "subscription-name"
```

**Storage account name conflicts**
- The configuration uses random suffixes to ensure unique names
- If conflicts occur, run `terragrunt destroy` and reapply

**Permission errors**
- Ensure your Azure account has Contributor role on the subscription
- Storage account creation requires specific permissions

### Debug Mode

```powershell
# Run with debug logging
$env:TG_LOG = "debug"
terragrunt plan

# Run drift detector with debug logging
$env:LOG_LEVEL = "debug"
..\src\bin\drift-detector.exe --config .picpay-drift-config-terragrunt.yaml
```

## 📊 Expected Outputs

### Successful Run
- Drift reports in `../drift-reports/` directory
- GitHub issues created (if configured)
- Console output showing detected resources and their status

### Report Structure
```json
{
  "timestamp": "2024-01-XX",
  "repositories_processed": 1,
  "resources_analyzed": 2,
  "drift_detected": true/false,
  "terragrunt_metadata": {
    "version": "x.x.x",
    "dependencies": [...],
    "module_sources": [...]
  },
  "resources": [...]
}
```

## 🎉 Success Criteria

Epic 0.8 Terragrunt Integration is successful when:

1. ✅ **Discovery**: All `terragrunt.hcl` files are found automatically
2. ✅ **Execution**: `terragrunt plan` runs without errors
3. ✅ **Dependencies**: Resource dependencies are properly handled
4. ✅ **Filtering**: Severity levels are assigned correctly  
5. ✅ **Reporting**: Enhanced reports include Terragrunt metadata
6. ✅ **Issues**: GitHub issues contain Terragrunt-specific information

---

*This test configuration supports the complete Epic 0.8 implementation and provides a foundation for future Terragrunt enhancements.*