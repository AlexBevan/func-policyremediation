data "azurerm_resource_group" "this" {
    name = var.resource_group_name
}

resource "azurecaf_name" "names" {
  resource_type  = "azurerm_resource_group"
  resource_types = ["azurerm_storage_account", "azurerm_app_service_plan", "azurerm_function_app"]
  suffixes = var.suffixes
  random_length  = 4
}

resource "azurerm_storage_account" "this" {
  name                     = azurecaf_name.names.results["azurerm_storage_account"]
  resource_group_name      = data.azurerm_resource_group.this.name
  location                 = data.azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "this" {
  name                = azurecaf_name.names.results["azurerm_app_service_plan"]
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_function_app" "this" {
  name                       = azurecaf_name.names.results["azurerm_function_app"]
  location                   = data.azurerm_resource_group.this.location
  resource_group_name        = data.azurerm_resource_group.this.name
  app_service_plan_id        = azurerm_app_service_plan.this.id
  storage_account_name       = azurerm_storage_account.this.name
  storage_account_access_key = azurerm_storage_account.this.primary_access_key
  version = "~3"
  site_config {
    always_on = true
  }
  app_settings = {
    "FUNCTIONS_EXTENSION_VERSION": "~3",
    "FUNCTIONS_WORKER_RUNTIME": "powershell",
    "Schedule": "0 */2 * * *",
    "MG_NAME": "${var.mg_name}",
    "WEBSITE_RUN_FROM_PACKAGE": "https://alexbevan.github.io/func-policyremediation/func-policyremediation.zip"
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "this" {
  scope                = "/providers/Microsoft.Management/managementGroups/${var.mg_name}"
  role_definition_name = "Contributor"
  principal_id         = azurerm_function_app.this.identity[0].principal_id
}

variable "resource_group_name" {
  description = "Name of existing resource group where this function will be deployed"
}

variable "suffixes" {
    default = ["policyremediation"]
    description = "List of suffixes to append to resouces created by this module"
}

variable "mg_name" {
  description = "name of the management group to remediate"
}

output "function_app" {
  value = azurerm_function_app.this
  sensitive = true
}