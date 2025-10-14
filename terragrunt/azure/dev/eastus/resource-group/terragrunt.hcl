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
  resource_tags = {
    Project      = "drift-detector-test"
    Purpose      = "testing-drift-detection"
    DriftCreated = "true"  # RECOMMENDATION: Remove once drift is resolved
    ModifiedBy   = "drift-script"  # RECOMMENDATION: Remove once drift is resolved
    ModifiedAt   = "2025-10-14T15:01:26-04:00"  # RECOMMENDATION: Remove once drift is resolved
  }
}