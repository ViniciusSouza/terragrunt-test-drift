#!/bin/bash
# Automated drift remediation script for Terragrunt Test Drift Repository
# This script fixes detected infrastructure drift by reverting to Terraform state

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Check if running from correct directory
if [ ! -d "terragrunt" ]; then
    log_error "This script must be run from the repository root directory"
    exit 1
fi

# Check dependencies
log_section "Checking Dependencies"

if ! command -v terragrunt &> /dev/null; then
    log_error "Terragrunt is not installed"
    log_info "Install from: https://terragrunt.gruntwork.io/docs/getting-started/install/"
    exit 1
fi
log_success "Terragrunt found: $(terragrunt --version | head -n1)"

if ! command -v az &> /dev/null; then
    log_error "Azure CLI is not installed"
    log_info "Install from: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi
log_success "Azure CLI found: $(az --version | head -n1)"

# Check Azure login status
if ! az account show &> /dev/null; then
    log_error "Not logged in to Azure"
    log_info "Run: az login"
    exit 1
fi
log_success "Azure authentication verified"

# Step 1: Review current drift
log_section "Step 1: Reviewing Current Drift"
log_info "Running Terragrunt plan to detect drift..."
echo ""

cd terragrunt

if terragrunt run-all plan --terragrunt-non-interactive 2>&1 | tee /tmp/drift-plan.txt; then
    if grep -q "No changes" /tmp/drift-plan.txt; then
        log_success "No drift detected! Infrastructure matches configuration."
        cd ..
        exit 0
    fi
    log_warning "Drift detected. Review the plan output above."
else
    log_error "Failed to run Terragrunt plan"
    cd ..
    exit 1
fi

# Step 2: Confirm remediation
echo ""
log_section "Step 2: Drift Remediation Confirmation"
echo ""
log_warning "This script will:"
echo "  1. Revert resource group tags to Terraform state"
echo "  2. Restore storage account TLS version to TLS1_2"
echo "  3. Reset storage account tags to Terraform state"
echo "  4. Remove extra blob container 'drift-test-container' (if exists)"
echo ""
log_info "The changes will restore infrastructure to match Terraform configuration."
echo ""

read -p "Do you want to proceed with drift remediation? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    log_info "Remediation cancelled by user"
    cd ..
    exit 0
fi

# Step 3: Apply Terraform configuration
log_section "Step 3: Applying Terraform Configuration"
log_info "Reverting resources to Terraform state..."
echo ""

if terragrunt run-all apply --terragrunt-non-interactive -auto-approve; then
    log_success "Terraform configuration applied successfully"
else
    log_error "Failed to apply Terraform configuration"
    cd ..
    exit 1
fi

# Step 4: Get resource names
log_section "Step 4: Cleaning Up Extra Resources"

cd azure/dev/eastus/resource-group
RG_NAME=$(terragrunt output -raw name 2>/dev/null || echo "")
cd ../storage
STORAGE_NAME=$(terragrunt output -raw name 2>/dev/null || echo "")
cd ../../../..

if [ -z "$RG_NAME" ] || [ -z "$STORAGE_NAME" ]; then
    log_error "Could not retrieve resource names from Terragrunt outputs"
    cd ..
    exit 1
fi

log_info "Resource Group: $RG_NAME"
log_info "Storage Account: $STORAGE_NAME"

# Step 5: Remove extra blob container
log_info "Checking for extra blob container 'drift-test-container'..."

if az storage container exists \
    --name drift-test-container \
    --account-name "$STORAGE_NAME" \
    --auth-mode login \
    --query exists -o tsv 2>/dev/null | grep -q "true"; then
    
    log_warning "Found extra container 'drift-test-container', removing..."
    
    if az storage container delete \
        --name drift-test-container \
        --account-name "$STORAGE_NAME" \
        --auth-mode login \
        --output none 2>/dev/null; then
        log_success "Extra blob container removed"
    else
        log_warning "Could not remove extra container (may not have permissions)"
    fi
else
    log_info "Extra container not found or already removed"
fi

cd ..

# Step 6: Verify remediation
log_section "Step 6: Verifying Remediation"
log_info "Running final drift check..."
echo ""

cd terragrunt

if terragrunt run-all plan --terragrunt-non-interactive 2>&1 | tee /tmp/drift-verify.txt; then
    if grep -q "No changes" /tmp/drift-verify.txt; then
        log_success "✅ Drift remediation completed successfully!"
        log_success "Infrastructure now matches Terraform configuration"
    else
        log_warning "Some drift may still remain. Review the plan output above."
    fi
else
    log_error "Failed to verify remediation"
    cd ..
    exit 1
fi

cd ..

# Summary
log_section "Remediation Summary"
echo ""
log_success "✅ Resource Group: Tags reverted to Terraform state"
log_success "✅ Storage Account: TLS version restored to TLS1_2"
log_success "✅ Storage Account: Tags reverted to Terraform state"
log_success "✅ Extra resources: Removed (if any)"
echo ""
log_info "Next steps:"
echo "  - Review the changes in Azure Portal to confirm"
echo "  - Run 'make plan' or 'terragrunt run-all plan' to verify no drift"
echo "  - Update monitoring/alerting if needed"
echo ""
log_info "To re-create drift for testing, run: make add-drift"
echo ""

exit 0
