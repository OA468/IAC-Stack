provider "azurerm" {
   features {}
}

resource "azurerm_resource_group" "playground" {
  name     = "playground"
  location = "West Europe"
}

resource "azurerm_container_registry" "acr" {
  name                = "playgroundregistryhs"
  resource_group_name = azurerm_resource_group.playground.name
  location            = azurerm_resource_group.playground.location
  sku                 = "Premium"
  admin_enabled       = false
}

resource "azurerm_kubernetes_cluster" "playground-cluster" {
  name                = "playground-cluster"
  location            = azurerm_resource_group.playground.location
  resource_group_name = azurerm_resource_group.playground.name
  dns_prefix = "playground-aks"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "standard_d2ads_v5"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
  }
}

resource "azurerm_role_assignment" "playground-assignment" {
  principal_id                     = azurerm_kubernetes_cluster.playground-cluster.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.playground-cluster.kube_config.0.client_certificate
  sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.playground-cluster.kube_config_raw

  sensitive = true
}