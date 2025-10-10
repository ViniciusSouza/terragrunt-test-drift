# Storage Account Module Outputs - Enhanced for Terragrunt

output "name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "location" {
  description = "Location of the storage account"
  value       = azurerm_storage_account.main.location
}

output "resource_group_name" {
  description = "Resource group name of the storage account"
  value       = azurerm_storage_account.main.resource_group_name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "primary_access_key" {
  description = "Primary access key for the storage account"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "connection_string" {
  description = "Primary connection string"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "tags" {
  description = "All tags applied to the storage account"
  value       = azurerm_storage_account.main.tags
}

output "test_container_name" {
  description = "Name of the test container (if created)"
  value       = var.create_test_container ? azurerm_storage_container.test[0].name : null
}