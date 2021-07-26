terraform {
  required_providers {
    azurecaf = {
      source = "aztfmod/azurecaf"
      version = "1.2.5"
    }
  }
}

provider "azurecaf" {
}
provider "azurerm" {
  features {
    
  }
}
module "example1" {
    source = "../"
    resource_group_name = azurerm_resource_group.example.name
    mg_name = "root"
    depends_on = [
      azurerm_resource_group.example
    ]
}

resource "azurerm_resource_group" "example" {
  name     = "example2"
  location = "UK South"
}

output "module_output" {
  value = module.example1
  sensitive = true
}
