# Resource Group Module Variables - Enhanced for Terragrunt

variable "name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the resource group"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to the resource group (from parent)"
  type        = map(string)
  default     = {}
}

variable "resource_tags" {
  description = "Resource-specific tags to apply to the resource group"
  type        = map(string)
  default     = {}
}