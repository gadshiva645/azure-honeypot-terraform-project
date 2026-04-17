# add azure key vault to replace tfvar secret file on local computer
# azure key vault
# random password
# key vault secret


data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "key-vault" {
  name = "key-vault-${random_string.keyvault-name-gen.result}"
  location = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  enabled_for_disk_encryption = true
  tenant_id = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled = false
  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
        "Get", "List", "Set", "Delete", "Purge",
    ]
  }
}

resource "random_string" "keyvault-name-gen" {
  length = 6
  special = false
  upper = false
}

resource "random_password" "vm_password" {
  length = 20
  special = true
  override_special = "$!%^?/><:;"
}

resource "azurerm_key_vault_secret" "vm-admin-password" {
  name = "vm-admin-password"
  value = random_password.vm_password.result
  key_vault_id = azurerm_key_vault.key-vault.id
}