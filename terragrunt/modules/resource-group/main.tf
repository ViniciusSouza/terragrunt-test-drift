# Enhanced Resource Group Module for Terragrunt
# Supports tag merging and flexible configuration

resource "azurerm_resource_group" "main" {
  name     = var.name
  location = var.location
  tags     = merge(var.tags, var.resource_tags)
}