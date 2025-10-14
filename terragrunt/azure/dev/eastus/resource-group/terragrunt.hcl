# Terragrunt configuration for Resource Group
# Path: azure/dev/eastus/resource-group

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../modules/resource-group"
}

inputs = {
  name = "rg-azure-dev-eastus-drift-test"
  
  # Override location if needed (defaults to region from path)
  location = "eastus"
  
  # Resource-specific tags (will be merged with common tags)
  # Updated to match actual cloud state after drift
  resource_tags = {
    Project = "drift-detector-test"
    Purpose = "testing-drift-detection"  # TODO: Update to "testing-terragrunt-integration"
  }
}