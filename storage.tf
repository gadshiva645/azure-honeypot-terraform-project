resource "random_string" "storage_name" {
  length  = 8
  upper   = false
  special = false
}

# azurerm_storage_account
resource "azurerm_storage_account" "storage-account" {
  name = "storage${random_string.storage_name.result}"
  resource_group_name = azurerm_resource_group.resource_group.name
  location = azurerm_resource_group.resource_group.location
  account_tier = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    last_access_time_enabled = true
  }

  tags = {
    Environment = "Honeypot-lab"
  }

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.identity_logs.id]
  }
}

resource "azurerm_storage_container" "storage-container" {
  name = "storage-container"
  storage_account_id = azurerm_storage_account.storage-account.id
  container_access_type = "private"
}

# azurerm_storage_management_policy
resource "azurerm_storage_management_policy" "storage-retention-policy" {
  storage_account_id = azurerm_storage_account.storage-account.id

  rule {
    name = "delete-30-days-storage-files"
    enabled = true
    filters {
      prefix_match = ["storage-container/"]
      blob_types = ["blockBlob"]
    }

    actions {
      base_blob {
       tier_to_cold_after_days_since_creation_greater_than = 2
       delete_after_days_since_creation_greater_than = 5
      }
    }
  }

  rule {
    name = "delete-old-network-logs"
    enabled = true
    filters {
      prefix_match = ["insights-logs-flowlogflowevent"]
      blob_types = ["blockBlob"]
    }
    actions {
      base_blob {
        tier_to_cold_after_days_since_creation_greater_than = 2
        delete_after_days_since_creation_greater_than = 5
      }
    }
  }

}