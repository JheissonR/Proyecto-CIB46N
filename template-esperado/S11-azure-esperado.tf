# S11 (esperado) - Almacenamiento NoSQL: Cosmos DB
# Equivalencia: aws_dynamodb_table -> azurerm_cosmosdb_account + azurerm_cosmosdb_table
resource "azurerm_resource_group" "main" {
  name     = "rg-migraiac-s11"
  location = "eastus"
}

resource "azurerm_cosmosdb_account" "main" {
  name                = "cosmos-migraiac-s11"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  capabilities {
    name = "EnableTable"
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.main.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_table" "users" {
  name                = "migraiac-users-s11"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  throughput          = 400
}
