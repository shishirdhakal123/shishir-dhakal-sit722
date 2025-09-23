output "resource_group"       { value = azurerm_resource_group.rg.name }
output "aks_name"             { value = azurerm_kubernetes_cluster.aks.name }
output "storage_account_name" { value = azurerm_storage_account.sa.name }
output "storage_container"    { value = azurerm_storage_container.container.name }