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
  # DRIFT: Updated to match current cloud state (drift-script set specific RG tags)
  resource_tags = {
    Project      = "drift-detector-test"
    Purpose      = "testing-drift-detection"  # DRIFT: Changed from 'testing-terragrunt-integration'
    ModifiedAt   = "2025-10-14T16:55:02Z"     # DRIFT: Added by drift-script
    # Original tags removed by drift-script:
    # Component = "infrastructure"
    # Service   = "shared"
  }
}