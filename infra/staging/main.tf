locals {
  name = "${var.project}-${var.env}"
}

resource "azurerm_resource_group" "rg" {
  name     = "${local.name}-rg"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${local.name}-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${local.name}-dns"

  default_node_pool {
    name       = "system"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity { type = "SystemAssigned" }

  network_profile { network_plugin = "azure" }
}

# Random suffix keeps storage account globally unique (lowercase only)
resource "random_string" "suffix" {
  length  = 5
  upper   = false
  lower   = true
  numeric = true
  special = false
}

resource "azurerm_storage_account" "sa" {
  name                     = replace("${local.name}sa${random_string.suffix.result}", "-", "")
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  public_network_access_enabled = true
}

resource "azurerm_storage_container" "container" {
  name                  = "staging-data"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

# Lookup your existing ACR by name
data "azurerm_container_registry" "acr" {
  name = var.shared_acr_name
  resource_group_name = var.shared_acr_rg
}

# Let AKS pull images from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}