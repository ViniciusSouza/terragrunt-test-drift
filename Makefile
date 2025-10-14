# Terragrunt Test Drift Makefile
# This Makefile provides convenient targets for managing Terragrunt resources and testing drift detection

.PHONY: help deploy create-resources clean-resources clean-all add-drift plan status check-deps

# Default target - show help
help:
	@echo "=== Terragrunt Test Drift Management ==="
	@echo ""
	@echo "Available targets:"
	@echo "  help            - Show this help message"
	@echo "  check-deps      - Check if required tools are installed"
	@echo "  deploy          - Deploy/update Terragrunt configuration"
	@echo "  create-resources - Create all Terragrunt resources in Azure"
	@echo "  clean-resources  - Destroy all Terragrunt resources in Azure"
	@echo "  clean-all       - Complete cleanup (resources + cache + state)"
	@echo "  add-drift       - Create drift by modifying Azure resources (legacy)"
	@echo "  drift-test      - Complete drift test workflow (enable access + create drift + cleanup)"
	@echo "  drift-test-keep - Drift test workflow but keep storage access open"
	@echo "  storage-enable  - Enable storage access for manual testing"
	@echo "  storage-disable - Disable storage access to restore security"
	@echo "  storage-status  - Check current storage access status"
	@echo "  plan            - Show what Terragrunt would change (detect drift)"
	@echo "  status          - Show current status of Terragrunt resources"
	@echo ""
	@echo "Typical workflow:"
	@echo "  1. make check-deps      # Ensure tools are installed"
	@echo "  2. make deploy          # Deploy infrastructure (or make create-resources for first time)"
	@echo "  3. make drift-test      # Automated: enable access + create drift + secure cleanup"
	@echo "  4. make plan            # Detect the drift"
	@echo "  5. make clean-resources # Clean up when done"
	@echo ""
	@echo "Alternative manual workflow:"
	@echo "  3a. make storage-enable # Manually enable storage access"
	@echo "  3b. make add-drift      # Create drift using legacy method"
	@echo "  3c. make storage-disable # Manually disable storage access"
	@echo ""

# Check if required dependencies are installed
check-deps:
	@echo "🔍 Checking dependencies..."
	@powershell -Command "if (Get-Command terragrunt -ErrorAction SilentlyContinue) { Write-Host '   ✅ Terragrunt: Found' -ForegroundColor Green } else { Write-Host '   ❌ Terragrunt: Not found' -ForegroundColor Red; exit 1 }"
	@powershell -Command "if (Get-Command az -ErrorAction SilentlyContinue) { Write-Host '   ✅ Azure CLI: Found' -ForegroundColor Green } else { Write-Host '   ❌ Azure CLI: Not found' -ForegroundColor Red; exit 1 }"
	@powershell -Command "try { az account show | Out-Null; Write-Host '   ✅ Azure CLI: Logged in' -ForegroundColor Green } catch { Write-Host '   ❌ Azure CLI: Not logged in (run: az login)' -ForegroundColor Red; exit 1 }"
	@echo ""
	@echo "✅ All dependencies are ready!"

# Deploy Terragrunt configuration (streamlined for regular updates)
deploy: check-deps
	@echo "🚀 Deploying Terragrunt configuration..."
	@echo ""
	@cd terragrunt && terragrunt apply --all --non-interactive
	@echo ""
	@echo "✅ Deployment completed successfully!"

# Create all Terragrunt resources (with interactive plan review)
create-resources: check-deps
	@echo "🏗️ Creating Terragrunt resources..."
	@echo ""
	@cd terragrunt && terragrunt init --all
	@cd terragrunt && terragrunt plan --all
	@echo ""
	@echo "⚠️  Review the plan above. Press Enter to apply or Ctrl+C to cancel..."
	@powershell -Command "Read-Host"
	@cd terragrunt && terragrunt apply --all --non-interactive
	@echo ""
	@echo "✅ Resources created successfully!"

# Destroy all Terragrunt resources
clean-resources:
	@echo "🧹 Cleaning up Terragrunt resources..."
	@echo ""
	@cd terragrunt && terragrunt plan --all -destroy
	@echo ""
	@echo "⚠️  Review the destruction plan above. Press Enter to destroy or Ctrl+C to cancel..."
	@powershell -Command "Read-Host"
	@cd terragrunt && terragrunt destroy --all --non-interactive
	@echo ""
	@echo "✅ Resources cleaned up successfully!"

# Complete cleanup - resources, cache, and state files
clean-all:
	@echo "🧹 Performing complete cleanup (resources + cache + state)..."
	@echo ""
	@echo "🔍 Checking for drift-test resource groups..."
	@powershell -Command "$$groups = az group list --query \"[?contains(name, 'drift-test') || contains(name, 'terragrunt')].[name]\" -o tsv; if ($$groups) { $$groups | ForEach-Object { Write-Host \"   Deleting: $$_\" -ForegroundColor Red; az group delete --name $$_ --yes --no-wait } } else { Write-Host \"   No resource groups found\" -ForegroundColor Green }"
	@echo ""
	@echo "🗂️  Cleaning Terragrunt cache and state files..."
	@powershell -Command "Get-ChildItem -Path 'terragrunt' -Recurse -Directory -Name '*terragrunt-cache*' | ForEach-Object { Remove-Item -Path \"terragrunt\\$$_\" -Recurse -Force -ErrorAction SilentlyContinue }"
	@powershell -Command "Get-ChildItem -Path 'terragrunt' -Recurse -Name 'terraform.tfstate*' | ForEach-Object { Remove-Item -Path \"terragrunt\\$$_\" -Force -ErrorAction SilentlyContinue }"
	@powershell -Command "Get-ChildItem -Path 'terragrunt' -Recurse -Name '.terraform.lock.hcl' | ForEach-Object { Remove-Item -Path \"terragrunt\\$$_\" -Force -ErrorAction SilentlyContinue }"
	@powershell -Command "Get-ChildItem -Path 'terragrunt' -Recurse -Directory -Name '.terraform' | ForEach-Object { Remove-Item -Path \"terragrunt\\$$_\" -Recurse -Force -ErrorAction SilentlyContinue }"
	@echo ""
	@echo "✅ Complete cleanup finished! Ready for fresh start."

# Add drift by running the PowerShell script
add-drift: check-deps
	@echo "🔧 Adding drift to existing resources..."
	@echo ""
	@powershell -ExecutionPolicy Bypass -File "scripts/create-drift.ps1"

# Show what Terragrunt would change (drift detection)
plan:
	@echo "🔍 Checking for drift (running terragrunt plan)..."
	@echo ""
	@cd terragrunt && terragrunt plan --all

# Show current status of resources
status:
	@echo "📊 Current Terragrunt status..."
	@echo ""
	@cd terragrunt && terragrunt show --all

# Quick validation target
validate:
	@echo "✅ Validating Terragrunt configuration..."
	@cd terragrunt && terragrunt validate --all

# Initialize Terragrunt modules without applying
init:
	@echo "🔧 Initializing Terragrunt modules..."
	@cd terragrunt && terragrunt init --all

# Force refresh state
refresh:
	@echo "🔄 Refreshing Terragrunt state..."
	@cd terragrunt && terragrunt refresh --all

# === Storage Access Management Targets ===

# Complete automated drift test workflow
drift-test: check-deps
	@echo "🌊 Running complete drift test workflow..."
	@echo ""
	@powershell -ExecutionPolicy Bypass -File "scripts/run-drift-test.ps1"

# Drift test workflow but keep storage access open for continued testing
drift-test-keep: check-deps
	@echo "🌊 Running drift test workflow (keeping storage access open)..."
	@echo ""
	@powershell -ExecutionPolicy Bypass -File "scripts/run-drift-test.ps1" -KeepAccessOpen

# Enable storage access for manual testing
storage-enable:
	@echo "🔓 Enabling storage access..."
	@powershell -ExecutionPolicy Bypass -File "scripts/manage-storage-access.ps1" -Action enable

# Disable storage access to restore security
storage-disable:
	@echo "🔒 Disabling storage access..."
	@powershell -ExecutionPolicy Bypass -File "scripts/manage-storage-access.ps1" -Action disable

# Check storage access status
storage-status:
	@echo "📊 Checking storage access status..."
	@powershell -ExecutionPolicy Bypass -File "scripts/manage-storage-access.ps1" -Action status