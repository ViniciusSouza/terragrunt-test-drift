# Example Terragrunt configuration for testing
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../src/test/terraform/modules/resource-group"
}

# Get locals from root configuration
locals {
  root_vars = read_terragrunt_config(find_in_parent_folders("root.hcl"))
}

# The root.hcl provides standardized inputs, we can add module-specific ones here
inputs = {
  # Simple name for example module
  name = "picpay-example-rg"
  
  # Use location from environment or default
  location = "East US"
  
  # Basic tags for testing
  tags = {
    Environment = "test"
    ManagedBy   = "terragrunt"
    Component   = "resource-group"
    Module      = "example-module"
  }
}