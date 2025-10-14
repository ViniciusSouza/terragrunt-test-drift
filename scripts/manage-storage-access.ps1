# Script to manage public network access for the Terraform state storage account
# This is needed to bypass Microsoft Defender for Storage restrictions during testing

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("enable", "disable", "status")]
    [string]$Action,
    
    [string]$StorageAccountName = "stterraformstate6406",
    [string]$ResourceGroupName = "rg-terraform-state"
)

$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message) 
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Get-StorageAccountStatus {
    Write-Info "Checking storage account status..."
    
    try {
        $account = az storage account show --name $StorageAccountName --resource-group $ResourceGroupName --query "{publicAccess: publicNetworkAccess, defenderEnabled: networkRuleSet.resourceAccessRules[0].resourceId}" --output json | ConvertFrom-Json
            
        Write-Host ""
        Write-Host "📊 Storage Account Status:" -ForegroundColor Magenta
        Write-Host "  • Account: $StorageAccountName" -ForegroundColor White
        Write-Host "  • Resource Group: $ResourceGroupName" -ForegroundColor White
        Write-Host "  • Public Network Access: $($account.publicAccess)" -ForegroundColor $(if ($account.publicAccess -eq "Enabled") { "Green" } else { "Red" })
        
        if ($account.defenderEnabled) {
            Write-Host "  • Microsoft Defender: Enabled (with access restrictions)" -ForegroundColor Yellow
        } else {
            Write-Host "  • Microsoft Defender: No access restrictions" -ForegroundColor Green
        }
        
        return $account.publicAccess
    }
    catch {
        Write-Error "Failed to get storage account status: $($_.Exception.Message)"
        exit 1
    }
}

function Enable-StorageAccess {
    Write-Info "Enabling public network access for storage account..."
    
    try {
        az storage account update --name $StorageAccountName --resource-group $ResourceGroupName --public-network-access "Enabled" --output none
            
        Write-Success "Public network access enabled for $StorageAccountName"
        
        # Wait a moment for the change to propagate
        Start-Sleep -Seconds 3
        
        # Test access
        Write-Info "Testing storage access..."
        az storage blob list --container-name tfstate --account-name $StorageAccountName --auth-mode login --output json | Out-Null
            
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Storage access test successful!"
        } else {
            Write-Warning "Storage access enabled but test failed. May need a few more seconds to propagate."
        }
    }
    catch {
        Write-Error "Failed to enable storage access: $($_.Exception.Message)"
        exit 1
    }
}

function Disable-StorageAccess {
    Write-Info "Disabling public network access for storage account..."
    
    try {
        az storage account update --name $StorageAccountName --resource-group $ResourceGroupName --public-network-access "Disabled" --output none
            
        Write-Success "Public network access disabled for $StorageAccountName"
        Write-Info "Storage account is now secured with Microsoft Defender restrictions"
    }
    catch {
        Write-Error "Failed to disable storage access: $($_.Exception.Message)"
        exit 1
    }
}

# Main execution
Write-Host ""
Write-Host "🔐 Terraform State Storage Access Manager" -ForegroundColor Magenta
Write-Host "==========================================" -ForegroundColor Magenta
Write-Host ""

# Check if Azure CLI is logged in
$account = az account show --output json 2>$null
if (-not $account) {
    Write-Error "Not logged in to Azure CLI. Please run 'az login' first."
    exit 1
}

$accountInfo = $account | ConvertFrom-Json
Write-Info "Logged in as: $($accountInfo.user.name)"
Write-Info "Subscription: $($accountInfo.name)"
Write-Host ""

switch ($Action.ToLower()) {
    "enable" {
        Enable-StorageAccess
    }
    "disable" {
        Disable-StorageAccess
    }
    "status" {
        Get-StorageAccountStatus | Out-Null
    }
}

Write-Host ""
Write-Host "Operation completed." -ForegroundColor Green