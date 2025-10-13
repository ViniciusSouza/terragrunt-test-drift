# Script to create drift by modifying Azure resources
# This script modifies resources created by Terragrunt to create detectable drift

$ErrorActionPreference = "Stop"

Write-Host "Creating drift in Azure resources..." -ForegroundColor Cyan
Write-Host ""

# Navigate to terragrunt directory
$originalLocation = Get-Location
$terragruntDir = Join-Path $PSScriptRoot "..\terragrunt"

if (-not (Test-Path $terragruntDir)) {
    Write-Host "ERROR: Terragrunt directory not found at $terragruntDir" -ForegroundColor Red
    exit 1
}

Push-Location $terragruntDir

try {
    # Check if Terragrunt directory structure exists
    if (-not (Test-Path "azure/dev/eastus/resource-group") -or -not (Test-Path "azure/dev/eastus/storage")) {
        Write-Host "ERROR: Expected Terragrunt directory structure not found" -ForegroundColor Red
        Write-Host "   Expected: azure/dev/eastus/resource-group and azure/dev/eastus/storage" -ForegroundColor Yellow
        exit 1
    }

    # Check if Terragrunt modules have been initialized (look for .terragrunt-cache or state files)
    $hasState = $false
    if ((Test-Path "azure/dev/eastus/resource-group/.terragrunt-cache") -or 
        (Test-Path "azure/dev/eastus/resource-group/terraform.tfstate") -or
        (Test-Path "azure/dev/eastus/storage/.terragrunt-cache") -or
        (Test-Path "azure/dev/eastus/storage/terraform.tfstate")) {
        $hasState = $true
    }
    
    if (-not $hasState) {
        Write-Host "❌ Error: No Terragrunt state found" -ForegroundColor Red
        Write-Host "   Please run 'terragrunt run-all apply' first to create resources" -ForegroundColor Yellow
        exit 1
    }

    # Extract resource names from Terragrunt output
    Write-Host "Reading Terragrunt state..." -ForegroundColor Yellow
    
    # Get resource group name from the resource group module
    Push-Location "azure/dev/eastus/resource-group"
    $rgName = terragrunt output -raw name 2>$null
    Pop-Location
    
    # Get storage account name from the storage module
    Push-Location "azure/dev/eastus/storage"
    $storageName = terragrunt output -raw name 2>$null
    Pop-Location

    if ([string]::IsNullOrEmpty($rgName) -or [string]::IsNullOrEmpty($storageName)) {
        Write-Host "❌ Error: Could not read resource names from Terragrunt output" -ForegroundColor Red
        Write-Host "   Make sure resources are created with 'terragrunt run-all apply'" -ForegroundColor Yellow
        exit 1
    }

    Write-Host "   Resource Group: $rgName" -ForegroundColor White
    Write-Host "   Storage Account: $storageName" -ForegroundColor White
    Write-Host ""

    # Check if Terragrunt is installed
    try {
        $null = Get-Command terragrunt -ErrorAction Stop
        $terragruntVersion = terragrunt --version
        Write-Host "   Terragrunt: $terragruntVersion" -ForegroundColor Gray
    } catch {
        Write-Host "❌ Error: Terragrunt not found" -ForegroundColor Red
        Write-Host "   Please install Terragrunt: https://terragrunt.gruntwork.io/docs/getting-started/install/" -ForegroundColor Yellow
        exit 1
    }

    # Get current user's object ID
    $userObjectId = az ad signed-in-user show --query id -o tsv
    
    # Assign Storage Blob Data Contributor role if needed for container creation
    Write-Host "Ensuring RBAC permissions for blob operations..." -ForegroundColor Yellow
    az role assignment create `
        --role "Storage Blob Data Contributor" `
        --assignee $userObjectId `
        --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$storageName" `
        --output none 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   [OK] RBAC role assigned" -ForegroundColor Green
    } else {
        Write-Host "   [INFO] Role already assigned or no permissions to assign (will proceed anyway)" -ForegroundColor Gray
    }
    Write-Host ""

    # Check if Azure CLI is installed
    try {
        $null = Get-Command az -ErrorAction Stop
    } catch {
        Write-Host "ERROR: Azure CLI not found" -ForegroundColor Red
        Write-Host "   Please install Azure CLI: https://docs.microsoft.com/cli/azure/install-azure-cli" -ForegroundColor Yellow
        exit 1
    }

    # Check if logged in to Azure
    try {
        $null = az account show 2>$null
    } catch {
        Write-Host "ERROR: Not logged in to Azure" -ForegroundColor Red
        Write-Host "   Please run: az login" -ForegroundColor Yellow
        exit 1
    }

    # Modify Resource Group tags
    Write-Host "Modifying Resource Group tags..." -ForegroundColor Yellow
    
    $currentDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    
    az group update `
        --name $rgName `
        --tags `
            Environment=production `
            ManagedBy=manual `
            Project=drift-detector-test `
            Purpose=testing-drift-detection `
            DriftCreated=true `
            ModifiedBy=drift-script `
            ModifiedAt=$currentDate `
        --output none

    if ($LASTEXITCODE -eq 0) {
        Write-Host "   [OK] Resource Group tags modified" -ForegroundColor Green
    } else {
        Write-Host "   [ERROR] Failed to modify Resource Group tags" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "Modifying Storage Account settings..." -ForegroundColor Yellow

    # Modify storage account minimum TLS version (safe change)
    az storage account update `
        --name $storageName `
        --resource-group $rgName `
        --min-tls-version TLS1_0 `
        --output none

    if ($LASTEXITCODE -eq 0) {
        Write-Host "   [OK] Storage Account TLS version changed to TLS1_0" -ForegroundColor Green
    } else {
        Write-Host "   [ERROR] Failed to modify Storage Account" -ForegroundColor Red
    }

    # Add tags to storage account
    az storage account update `
        --name $storageName `
        --resource-group $rgName `
        --tags `
            Environment=production `
            ManagedBy=manual `
            DriftCreated=true `
            ModifiedBy=drift-script `
        --output none

    if ($LASTEXITCODE -eq 0) {
        Write-Host "   [OK] Storage Account tags modified" -ForegroundColor Green
    } else {
        Write-Host "   [ERROR] Failed to modify Storage Account tags" -ForegroundColor Red
    }

    # Try to create an additional blob container (this will show as drift)
    Write-Host ""
    Write-Host "Creating additional blob container..." -ForegroundColor Yellow
    
    # Use Azure AD authentication instead of storage account key
    az storage container create `
        --name "drift-test-container" `
        --account-name $storageName `
        --auth-mode login `
        --output none
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   [OK] Additional blob container created: drift-test-container" -ForegroundColor Green
    } else {
        Write-Host "   [WARN] Could not create additional container - may already exist or insufficient permissions" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "✅ Drift created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Summary of changes made to Terragrunt-managed resources:" -ForegroundColor Cyan
    Write-Host "   - Resource Group tags changed: Environment dev->production, ManagedBy terragrunt->manual" -ForegroundColor White
    Write-Host "   - Storage Account TLS version changed: TLS1_2 -> TLS1_0" -ForegroundColor White
    Write-Host "   - Storage Account tags added: DriftCreated, ModifiedBy" -ForegroundColor White
    Write-Host "   - Additional blob container created: drift-test-container" -ForegroundColor White
    Write-Host ""
    Write-Host "NOTE: These changes create drift between Terragrunt configuration and actual Azure state" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "[?] Run drift detection to see the changes:" -ForegroundColor Cyan
    Write-Host "   terragrunt run-all plan    # See what Terragrunt would change" -ForegroundColor White
    Write-Host ""
    Write-Host "[*] Terragrunt commands for reference:" -ForegroundColor Cyan
    Write-Host "   terragrunt run-all plan    # Check planned changes" -ForegroundColor White
    Write-Host "   terragrunt run-all apply   # Apply all configurations" -ForegroundColor White
    Write-Host "   terragrunt run-all destroy # Cleanup all resources" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "ERROR: An error occurred during drift creation: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}
