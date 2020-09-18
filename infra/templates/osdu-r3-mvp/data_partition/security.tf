//  Copyright © Microsoft Corporation
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.


/*
.Synopsis
   Terraform Security Control
.DESCRIPTION
   This file holds security settings.
*/


#-------------------------------
# Private Variables
#-------------------------------
locals {
  role = "Contributor"
  rbac_principals = [
    data.terraform_remote_state.central_resources.outputs.osdu_identity_principal_id,
    data.terraform_remote_state.central_resources.outputs.principal_objectId
  ]

  storage_account_name = format("%s-storage", var.data_partition_name)
  storage_key_name     = format("%s-key", local.storage_account_name)

  cosmos_connection  = format("%s-cosmos-connection", var.data_partition_name)
  cosmos_endpoint    = format("%s-cosmos-endpoint", var.data_partition_name)
  cosmos_primary_key = format("%s-cosmos-primary-key", var.data_partition_name)

  sb_namespace_name = format("%s-sb-namespace", var.data_partition_name)
  sb_connection     = format("%s-sb-connection", var.data_partition_name)

  eventgrid_domain_name            = format("%s-eventgrid", var.data_partition_name)
  eventgrid_domain_key_name        = format("%s-key", local.eventgrid_domain_name)
  eventgrid_records_topic_name     = format("%s-recordstopic", local.eventgrid_domain_name)
  eventgrid_records_topic_endpoint = format("https://%s.%s-1.eventgrid.azure.net/api/events", local.eventgrid_records_topic, var.resource_group_location)
}



#-------------------------------
# Storage
#-------------------------------

// Add the Storage Account Name to the Vault
resource "azurerm_key_vault_secret" "storage_name" {
  name         = local.storage_account_name
  value        = module.storage_account.name
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

// Add the Storage Key to the Vault
resource "azurerm_key_vault_secret" "storage_key" {
  name         = local.storage_key_name
  value        = module.storage_account.primary_access_key
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

// Add Access Control to Principal
resource "azurerm_role_assignment" "storage_access" {
  count = length(local.rbac_principals)

  role_definition_name = "Contributor"
  principal_id         = local.rbac_principals[count.index]
  scope                = module.storage_account.id
}



#-------------------------------
# CosmosDB
#-------------------------------

// Add the CosmosDB Connection to the Vault
resource "azurerm_key_vault_secret" "cosmos_connection" {
  name         = local.cosmos_connection
  value        = module.cosmosdb_account.properties.cosmosdb.connection_strings[0]
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

// Add the CosmosDB Endpoint to the Vault
resource "azurerm_key_vault_secret" "cosmos_endpoint" {
  name         = local.cosmos_endpoint
  value        = module.cosmosdb_account.properties.cosmosdb.endpoint
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

// Add the CosmosDB Key to the Vault
resource "azurerm_key_vault_secret" "cosmos_key" {
  name         = local.cosmos_primary_key
  value        = module.cosmosdb_account.properties.cosmosdb.primary_master_key
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

// Add DB Reader Role 
resource "azurerm_role_assignment" "database_roles" {
  count = length(local.rbac_principals)

  role_definition_name = "Cosmos DB Account Reader Role"
  principal_id         = local.rbac_principals[count.index]
  scope                = module.cosmosdb_account.account_id
}



#-------------------------------
# Azure Service Bus
#-------------------------------

// Add the ServiceBus Connection to the Vault
resource "azurerm_key_vault_secret" "sb_namespace" {
  name         = local.sb_namespace_name
  value        = module.service_bus.name
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

// Add the ServiceBus Connection to the Vault
resource "azurerm_key_vault_secret" "sb_connection" {
  name         = local.sb_connection
  value        = module.service_bus.default_connection_string
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

// Add SB Data Sender Role
resource "azurerm_role_assignment" "service_bus_roles" {
  count = length(local.rbac_principals)

  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = local.rbac_principals[count.index]
  scope                = module.service_bus.id
}



#-------------------------------
# Azure Event Grid
#-------------------------------

// Add the Event Grid Name to the Vault
resource "azurerm_key_vault_secret" "eventgrid_name" {
  name         = local.eventgrid_domain_name
  value        = module.event_grid.name
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

// Add the Event Grid Key to the Vault
resource "azurerm_key_vault_secret" "eventgrid_key" {
  name         = local.eventgrid_domain_key_name
  value        = module.event_grid.primary_access_key
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

// Add the Record Topic Name to the Vault
resource "azurerm_key_vault_secret" "recordstopic_name" {
  name         = local.eventgrid_records_topic_name
  value        = local.eventgrid_records_topic_endpoint
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}

// Add EventGrid Reader Role
resource "azurerm_role_assignment" "eventgrid_roles" {
  count = length(local.rbac_principals)

  role_definition_name = "EventGrid EventSubscription Reader"
  principal_id         = local.rbac_principals[count.index]
  scope                = module.event_grid.id
}
