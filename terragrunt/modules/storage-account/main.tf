# Enhanced Storage Account Module for Terragrunt
# Supports tag merging and flexible configuration

resource "azurerm_storage_account" "main" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type
  
  # Security settings
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  https_traffic_only_enabled      = true
  
  # Disable key-based authentication (enforced by Azure Policy)
  # Terraform provider will use Azure AD authentication instead
  shared_access_key_enabled       = false

  tags = merge(var.tags, var.resource_tags)
}

# Optional: Blob container for testing
resource "azurerm_storage_container" "test" {
  count                = var.create_test_container ? 1 : 0
  name                 = "test-container"
  storage_account_name = azurerm_storage_account.main.name
  container_access_type = "private"
}