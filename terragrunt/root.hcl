# Root Terragrunt configuration for test environment
# Provides common configuration and remote state setup

locals {
  # Parse the relative path to extract environment details
  # Expected format: azure/{account}/{region}/{resource-type}/{resource-name}
  path_parts = split("/", path_relative_to_include())
  
  # Extract standardized values from path
  cloud_provider = length(local.path_parts) > 0 ? local.path_parts[0] : "azure"
  account        = length(local.path_parts) > 1 ? local.path_parts[1] : "dev"
  region         = length(local.path_parts) > 2 ? local.path_parts[2] : "eastus"
  resource_type  = length(local.path_parts) > 3 ? local.path_parts[3] : "unknown"
  resource_name  = length(local.path_parts) > 4 ? local.path_parts[4] : "default"
  
  # Common tags for all resources
  common_tags = {
    Environment   = "production"
    ManagedBy     = "manual"
    Project       = "drift-detector-test"
    Purpose       = "testing-drift-detection"
    CloudProvider = local.cloud_provider
    Region        = local.region
    ResourceType  = local.resource_type
    DriftCreated  = "true"
    ModifiedBy    = "drift-script"
  }
}

# Remote state configuration using Azure Storage with Azure AD authentication
# Each module gets its own state file with unique key path
remote_state {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate6406"
    container_name       = "tfstate"
    key                  = "${path_relative_to_include()}/terraform.tfstate"
    use_azuread_auth     = true
  }
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  
  # Use Azure AD authentication for storage account data plane operations
  storage_use_azuread = true
}
EOF
}

# Make common inputs available to all child configurations
inputs = {
  environment    = local.account
  location       = local.region
  cloud_provider = local.cloud_provider
  resource_type  = local.resource_type
  
  # Common tags
  tags = local.common_tags
  
  # Naming convention
  name_suffix = "drift-test"
  name_prefix = "${local.cloud_provider}-${local.account}-${local.region}"
}