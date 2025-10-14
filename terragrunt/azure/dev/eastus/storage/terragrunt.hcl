# Terragrunt configuration for Storage Account
# Path: azure/dev/eastus/storage

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../modules/storage-account"
}

# Dependency on resource group
dependency "resource_group" {
  config_path = "../resource-group"
}

inputs = {
  # Generate unique name (storage accounts need globally unique names)
  name = "stazdeveastdrift123"
  
  # Use resource group from dependency
  resource_group_name = dependency.resource_group.outputs.name
  location           = dependency.resource_group.outputs.location
  
  # Resource-specific tags
  resource_tags = {
    Component    = "storage"
    Service      = "data"
    Replication  = "LRS"
    DriftCreated = "true"  # RECOMMENDATION: Remove once drift is resolved
    ModifiedBy   = "drift-script"  # RECOMMENDATION: Remove once drift is resolved
  }
}