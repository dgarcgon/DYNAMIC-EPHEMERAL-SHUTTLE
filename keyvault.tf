data "azurerm_client_config" "current" {
  provider = azurerm.local
}

resource "azurerm_key_vault" "local" {
  provider                    = azurerm.local
  name                        = "${var.deployment_def.code}-kvt"
  location                    = azurerm_resource_group.local.location
  resource_group_name         = azurerm_resource_group.local.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"
}

resource "azurerm_key_vault_access_policy" "tfaccess" {
  provider     = azurerm.local
  key_vault_id = azurerm_key_vault.local.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  key_permissions = [
    "Get",
    "List",
    "Update",
    "Create",
    "Import",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "Purge",
  ]

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "Purge",
  ]

  certificate_permissions = [
    "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts",
    "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update",
  ]

  storage_permissions = [
    "Get",
  ]

}

resource "azurerm_key_vault_access_policy" "writeaccess" {
  for_each     = var.deployment_def.keyvault.accessrights.writenoread
  provider     = azurerm.local
  key_vault_id = azurerm_key_vault.local.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.value.userid

  key_permissions = [
    "List",
    "Update",
    "Create"
  ]

  secret_permissions = [
    "List",
    "Set"
  ]

  certificate_permissions = [
    "Create",
    "List",
    "ListIssuers"
  ]

  storage_permissions = [
    "Get",
  ]
}

resource "azurerm_key_vault_access_policy" "readwrite" {
  for_each     = var.deployment_def.keyvault.accessrights.readwrite
  provider     = azurerm.local
  key_vault_id = azurerm_key_vault.local.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.value.userid

  key_permissions = [
    "Get",
    "List",
    "Update",
    "Create",
    "Import",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "Purge",
  ]

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "Purge",
  ]

  certificate_permissions = [
    "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts",
    "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update",
  ]

  storage_permissions = [
    "Get",
  ]
}

resource "azurerm_key_vault_certificate" "mev_wildcard" {
  depends_on = [
    azurerm_key_vault_access_policy.tfaccess,
    azurerm_key_vault_access_policy.readwrite
  ]
  provider     = azurerm.local
  name         = var.deployment_def.ssl_cert_name
  key_vault_id = azurerm_key_vault.local.id

  certificate {
    contents = filebase64("${path.module}/files/mev-wildcard-2025-2026.pfx")
    password = "SSL_CERT_SECRET"
  }
}
