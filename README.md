# Terragrunt Test Drift Repository

This repository contains a test environment for demonstrating Terragrunt drift detection capabilities. It creates Azure resources using Terragrunt and provides tools to simulate configuration drift.

## 📋 Prerequisites

Before using this repository, ensure you have the following tools installed:

- **Terragrunt** - Infrastructure as Code tool ([Installation Guide](https://terragrunt.gruntwork.io/docs/getting-started/install/))
- **Terraform** - Required by Terragrunt ([Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli))
- **Azure CLI** - For Azure authentication ([Installation Guide](https://docs.microsoft.com/cli/azure/install-azure-cli))
- **Make** - For using the provided Makefile (usually pre-installed on Linux/macOS, on Windows use [chocolatey](https://chocolatey.org/packages/make) or WSL)
- **PowerShell** - For running drift creation scripts (pre-installed on Windows)

### Authentication Setup

1. Login to Azure CLI:
   ```bash
   az login
   ```

2. Set your default subscription (if needed):
   ```bash
   az account set --subscription "your-subscription-name-or-id"
   ```

## 🚀 Quick Start

### Using the Makefile (Recommended)

1. **Check dependencies**:
   ```bash
   make check-deps
   ```

2. **Deploy infrastructure** (or use `make create-resources` for first-time setup with plan review):
   ```bash
   make deploy
   ```

3. **Create drift by modifying resources**:
   ```bash
   make add-drift
   ```

4. **Detect the drift**:
   ```bash
   make plan
   ```

5. **Clean up resources when done**:
   ```bash
   make clean-resources
   ```

### Manual Commands

If you prefer to run commands manually:

1. **Initialize and create resources**:
   ```bash
   cd terragrunt
   terragrunt run-all init
   terragrunt run-all apply
   ```

2. **Create drift**:
   ```bash
   powershell -ExecutionPolicy Bypass -File scripts/create-drift.ps1
   ```

3. **Check for drift**:
   ```bash
   cd terragrunt
   terragrunt run-all plan
   ```

## 📁 Repository Structure

```
├── terragrunt/                    # Terragrunt configurations
│   ├── azure/dev/eastus/         # Environment-specific configs
│   │   ├── resource-group/       # Resource group module
│   │   └── storage/              # Storage account module (depends on RG)
│   ├── modules/                  # Terraform modules
│   │   ├── resource-group/       # Resource group Terraform module
│   │   └── storage-account/      # Storage account Terraform module
│   └── *.tf                     # Backend and provider configurations
├── scripts/                      # Utility scripts
│   └── create-drift.ps1         # PowerShell script to create drift
├── drift-reports/               # Drift detection reports
├── Makefile                     # Build automation
└── README.md                    # This file
```

## 🔧 What the Drift Script Does

The `create-drift.ps1` script modifies Azure resources to simulate configuration drift:

1. **Resource Group Changes**:
   - Changes tags from `Environment=dev` to `Environment=production`
   - Changes `ManagedBy` from `terragrunt` to `manual`
   - Adds drift-specific tags

2. **Storage Account Changes**:
   - Changes minimum TLS version from `TLS1_2` to `TLS1_0`
   - Adds additional tags
   - Creates an extra blob container

These changes are intentionally safe and non-destructive, designed to be easily detected by Terragrunt's plan command.

## 🎯 Available Make Targets

| Target | Description |
|--------|-------------|
| `help` | Show available commands and usage |
| `check-deps` | Verify all required tools are installed |
| `deploy` | Deploy/update Terragrunt configuration (non-interactive) |
| `create-resources` | Initialize and apply Terragrunt configuration (with plan review) |
| `clean-resources` | Destroy all created Azure resources |
| `clean-all` | Complete cleanup (resources + cache + state files) |
| `add-drift` | Run the PowerShell script to create drift |
| `plan` | Run `terragrunt plan` to detect configuration drift |
| `status` | Show current status of managed resources |
| `validate` | Validate Terragrunt configuration syntax |
| `init` | Initialize Terragrunt modules without applying |
| `refresh` | Refresh Terragrunt state from Azure |

## 🔍 Understanding Drift Detection

After running `make add-drift` and then `make plan`, you should see output showing:

- **Resource Group**: Tag changes and additions
- **Storage Account**: TLS version change and new tags
- **New Resources**: Additional blob container not in configuration

Example expected drift output:
```
# azurerm_resource_group.this will be updated in-place
~ resource "azurerm_resource_group" "this" {
    ~ tags        = {
        ~ "Environment" = "dev" -> "production"
        ~ "ManagedBy"   = "terragrunt" -> "manual"
        + "DriftCreated" = "true"
        # ... more changes
    }
}
```

### 🔧 Fixing Detected Drift

When drift is detected, you have several options to remediate it:

1. **Automated Fix** (Recommended for test environment):
   ```bash
   ./scripts/fix-drift.sh
   ```

2. **Manual Fix** (Review changes first):
   ```bash
   cd terragrunt
   terragrunt run-all plan    # Review changes
   terragrunt run-all apply   # Apply to fix drift
   ```

3. **Quick Fix via Makefile**:
   ```bash
   make deploy
   ```

For detailed remediation guidance, see:
- 📖 [Complete Drift Remediation Guide](./DRIFT_REMEDIATION.md) - Comprehensive analysis and remediation strategies
- 🚀 [Quick Fix Reference](./docs/drift-quick-fix.md) - Fast commands for common scenarios

## 🛠️ Troubleshooting

### Common Issues

1. **"Terragrunt not found"**
   - Install Terragrunt: `choco install terragrunt` (Windows) or follow [official guide](https://terragrunt.gruntwork.io/docs/getting-started/install/)

2. **"Not logged in to Azure"**
   - Run: `az login`

3. **"Permission denied" errors**
   - Ensure your Azure account has Contributor role on the subscription
   - For blob operations, the script automatically assigns Storage Blob Data Contributor role

4. **PowerShell execution policy errors**
   - The Makefile uses `-ExecutionPolicy Bypass` to handle this automatically
   - Or manually run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

### Resource Naming

Resources are created with random suffixes to avoid naming conflicts:
- Resource Group: `rg-terragrunt-test-{random}`
- Storage Account: `sttgtest{random}` (shortened for storage naming requirements)

## 🧹 Cleanup

Always clean up Azure resources when you're done testing:

```bash
make clean-resources
```

This will destroy all resources created by Terragrunt, including any modifications made by the drift script.

## 📝 Notes

- The drift script is designed to be **safe** and **reversible**
- All changes can be corrected by running `terragrunt run-all apply`
- Resource costs are minimal (Resource Group is free, Storage Account has minimal costs)
- The script includes verbose output to help understand what's happening at each step

## 🤝 Contributing

When modifying the drift script:
1. Ensure all changes are safe and reversible
2. Test on a separate Azure subscription first
3. Update documentation if adding new drift scenarios
4. Maintain backward compatibility with existing Terragrunt configurations