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
  # DRIFT: Tags cleared - drift-script replaced all storage tags with only common tags
  # Original tags removed by drift-script: Component, Service, Replication
  resource_tags = {
    # Empty - storage account only has common tags from root.hcl in current cloud state
  }
}