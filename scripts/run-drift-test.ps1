# Comprehensive drift creation script with storage access management
# This script handles the entire workflow of enabling storage access, creating drift, and cleanup

param(
    [switch]$KeepAccessOpen,
    [switch]$SkipStorageManagement,
    [string]$StorageAccountName = "stterraformstate6406",
    [string]$ResourceGroupName = "rg-terraform-state"
)

$ErrorActionPreference = "Stop"

# Get script directory for relative paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RootDir = Split-Path -Parent $ScriptDir

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

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "🔄 $Message" -ForegroundColor Magenta
    Write-Host "$(('-' * ($Message.Length + 4)))" -ForegroundColor Magenta
}

# Main execution
Write-Host ""
Write-Host "🌊 Terragrunt Drift Creation Workflow" -ForegroundColor Magenta
Write-Host "=====================================" -ForegroundColor Magenta
Write-Host ""

$originalLocation = Get-Location
$accessWasEnabled = $false

try {
    # Step 1: Check prerequisites
    Write-Step "Checking Prerequisites"
    
    # Check Azure CLI login
    $account = az account show --output json 2>$null
    if (-not $account) {
        Write-Error "Not logged in to Azure CLI. Please run 'az login' first."
        exit 1
    }
    
    $accountInfo = $account | ConvertFrom-Json
    Write-Info "Logged in as: $($accountInfo.user.name)"
    Write-Info "Subscription: $($accountInfo.name)"
    
    # Check Terragrunt installation
    $terragruntVersion = terragrunt --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Terragrunt not found. Please install Terragrunt first."
        exit 1
    }
    Write-Info "Terragrunt version: $($terragruntVersion -split "`n" | Select-Object -First 1)"
    
    # Step 2: Manage storage access (if not skipped)
    if (-not $SkipStorageManagement) {
        Write-Step "Managing Storage Access"
        
        # Check current storage status
        $storageScript = Join-Path $ScriptDir "manage-storage-access.ps1"
        
        Write-Info "Checking current storage access status..."
        & $storageScript -Action status
        
        Write-Info "Enabling storage access for drift testing..."
        & $storageScript -Action enable
        $accessWasEnabled = $true
        
        Write-Success "Storage access is now enabled"
    } else {
        Write-Info "Skipping storage access management (--SkipStorageManagement specified)"
    }
    
    # Step 3: Navigate to terragrunt directory
    Write-Step "Preparing Terragrunt Environment"
    
    $terragruntDir = Join-Path $RootDir "terragrunt"
    if (-not (Test-Path $terragruntDir)) {
        Write-Error "Terragrunt directory not found at $terragruntDir"
        exit 1
    }
    
    Push-Location $terragruntDir
    Write-Info "Working in: $terragruntDir"
    
    # Step 4: Verify remote state access
    Write-Step "Verifying Remote State Access"
    
    Write-Info "Testing Terragrunt state access..."
    $stateTest = terragrunt output --all 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Terragrunt state access test failed:"
        Write-Host $stateTest -ForegroundColor Red
        
        if (-not $SkipStorageManagement -and -not $KeepAccessOpen) {
            Write-Info "Attempting to restore storage security..."
            Pop-Location
            & $storageScript -Action disable
        }
        exit 1
    }
    
    Write-Success "Remote state access verified!"
    
    # Step 5: Execute drift creation
    Write-Step "Creating Configuration Drift"
    
    $driftScript = Join-Path $ScriptDir "create-drift.ps1"
    if (-not (Test-Path $driftScript)) {
        Write-Error "Drift creation script not found at $driftScript"
        exit 1
    }
    
    Write-Info "Executing drift creation script..."
    & $driftScript
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Drift creation completed successfully!"
    } else {
        Write-Error "Drift creation failed with exit code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
    
    # Step 6: Post-execution summary
    Write-Step "Execution Summary"
    
    Write-Success "Drift creation workflow completed successfully!"
    Write-Info "Resources have been modified to create detectable drift."
    Write-Info "You can now run 'terragrunt plan' or 'terragrunt run-all plan' to detect changes."
    
    if ($accessWasEnabled -and -not $KeepAccessOpen) {
        Write-Host ""
        Write-Info "Storage access will be disabled to restore security..."
    } elseif ($KeepAccessOpen) {
        Write-Warning "Storage access remains enabled for continued testing."
        Write-Warning "Remember to run 'scripts/manage-storage-access.ps1 -Action disable' when done."
    }

} catch {
    Write-Error "Workflow failed: $($_.Exception.Message)"
    $exitCode = 1
} finally {
    # Step 7: Cleanup (restore storage security if we enabled it)
    if ($accessWasEnabled -and -not $KeepAccessOpen -and -not $SkipStorageManagement) {
        Write-Step "Restoring Storage Security"
        
        Pop-Location | Out-Null
        Set-Location $originalLocation
        
        $storageScript = Join-Path $ScriptDir "manage-storage-access.ps1"
        Write-Info "Disabling public storage access to restore security..."
        
        try {
            & $storageScript -Action disable
            Write-Success "Storage security restored"
        } catch {
            Write-Warning "Failed to restore storage security. Please manually disable access:"
            Write-Host "  scripts/manage-storage-access.ps1 -Action disable" -ForegroundColor Yellow
        }
    } else {
        Pop-Location | Out-Null
        Set-Location $originalLocation
    }
}

Write-Host ""
if ($exitCode -eq 0 -or -not $exitCode) {
    Write-Host "🎉 Workflow completed!" -ForegroundColor Green
} else {
    Write-Host "💥 Workflow failed!" -ForegroundColor Red
    exit $exitCode
}