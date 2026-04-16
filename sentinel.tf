
resource "azurerm_log_analytics_workspace" "workspace" {
  name = "workspace"
  resource_group_name = azurerm_resource_group.resource_group.name
  location = azurerm_resource_group.resource_group.location
  sku = "PerGB2018"
  retention_in_days = 30
  daily_quota_gb = 1
}

# azurerm_log_analytics_workspace_table
resource "azurerm_log_analytics_workspace_table" "workspace-table" {
  workspace_id = azurerm_log_analytics_workspace.workspace.workspace_id
  name = "workspace-table"
  plan = "Basic"
  retention_in_days = 8
}

resource "azurerm_sentinel_log_analytics_workspace_onboarding" "sentinel-workspace" {
  workspace_id = azurerm_log_analytics_workspace.workspace.id
}

# azurerm_virtual_machine_extension
resource "azurerm_virtual_machine_extension" "ama" {
  name = "agent-vm"
  virtual_machine_id = azurerm_windows_virtual_machine.windows_vm.id
  publisher = "Microsoft.Azure.Monitor"
  type = "AzureMonitorWindowsAgent"
  type_handler_version = "1.10"
  auto_upgrade_minor_version = "true"
}

# azurerm_monitor_data_collection_endpoint
resource "azurerm_monitor_data_collection_endpoint" "monitor-endpoint" {
  name = "monitor-endpoint"
  resource_group_name = azurerm_resource_group.resource_group.name
  location = azurerm_resource_group.resource_group.location
  kind = "Windows"
  public_network_access_enabled = true
  description = "monitor-endpoint"
  tags = {
    Environment = "Honeypot-lab"
  }
}

# azurerm_monitor_data_collection_rule
resource "azurerm_monitor_data_collection_rule" "dcr-honeypot" {
  name = "dcr-honeypot"
  resource_group_name = azurerm_resource_group.resource_group.name
  location = azurerm_resource_group.resource_group.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.monitor-endpoint.id

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.workspace.id
      name = "destination-log-analytics"
    }

    storage_blob {
      storage_account_id = azurerm_storage_account.storage-account.id
      container_name = azurerm_storage_container.storage-container.name
      name = "destination-log-storage"
    }
  }

  data_flow {
    streams = ["Microsoft-SecurityEvent"]
    destinations = ["destination-log-analytics", "destination-log-storage"]
  }

  data_flow {
    streams = ["Microsoft-W3CIISLog"]
    destinations = ["destination-log-analytics", "destination-log-storage"]
  }

  data_sources {
    windows_event_log {
      streams = ["Microsoft-SecurityEvent"]
      x_path_queries = ["Security!*[System[(EventID=4625)]]"]
      name = "datasource-windows-securityevent"
    }

    iis_log {
      streams = ["Microsoft-W3CIISLog"]
      name = "datasource-iis"
    }
  }

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.identity_logs.id]
  }
}

# azurerm_monitor_data_collection_rule_association
resource "azurerm_monitor_data_collection_rule_association" "dcra-rule" {
  name = "dcra-rule"
  target_resource_id = azurerm_windows_virtual_machine.windows_vm.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr-honeypot.id
  description = "data-collection-rule-association-vm"
}

resource "azurerm_monitor_data_collection_rule_association" "dcra-endpoint" {
  name = "dcra-endpoint"
  target_resource_id = azurerm_windows_virtual_machine.windows_vm.id
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.monitor-endpoint.id
  description = "data-collection-endpoint-association-vm"
}

# azurerm_network_watcher
resource "azurerm_network_watcher" "network-watcher" {
  name = "network-watcher"
  resource_group_name = azurerm_resource_group.resource_group.name
  location = azurerm_resource_group.resource_group.location
}

# azurerm_network_watcher_flow_log 
resource "azurerm_network_watcher_flow_log" "network-watcher-flow-log" {
  network_watcher_name = azurerm_network_watcher.network-watcher.name
  resource_group_name = azurerm_resource_group.resource_group.name
  name = "network-watcher-flow-log"
  target_resource_id = azurerm_virtual_network.virtual_network.id
  storage_account_id = azurerm_storage_account.storage-account.id
  enabled = true

  retention_policy {
    enabled = false
    days = 0
  }

  traffic_analytics {
    enabled = true
    workspace_id = azurerm_log_analytics_workspace.workspace.id
    workspace_region = azurerm_log_analytics_workspace.workspace.location
    workspace_resource_id = azurerm_log_analytics_workspace.workspace.id
    interval_in_minutes = 10
  }
}

#identity user assigned 
resource "azurerm_user_assigned_identity" "identity_logs" {
  location = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  name = "user-identity"
}

# azurerm_role_assignment  Monitoring Metrics Publisher
resource "azurerm_role_assignment" "log-identity-role" {
  scope = azurerm_resource_group.resource_group.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id = azurerm_user_assigned_identity.identity_logs.principal_id
}

resource "azurerm_role_assignment" "vm-identity-role" {
  scope = azurerm_resource_group.resource_group.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id = azurerm_windows_virtual_machine.windows_vm.identity[0].principal_id
}

# azurerm_sentinel_alert_rule_scheduled
resource "azurerm_sentinel_alert_rule_scheduled" "sentinel-rule-scheduled" {
  name = "vm-login-failed"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id
  display_name = "Failed-login-windows-multiple-honeypot"
  severity = "High"
  query = <<QUERY
  SecurityEvent
  | where EventID == 4625
  | where AccountType == "User"
  | summarize count() by TargetAccount, IpAddress, Computer
  | where count_ > 10
  QUERY
}

# connect to azure build terraform resources 







# optional
# azurerm_monitor_diagnostic_setting

#azurerm_private_endpoint
# only add if you needed when blocking all outbound you will need private endpoint to send azure agent logs

# 📊 9. Visualization Layer
# 🔹 Workbooks
# Dashboards showing:
# Attack origin countries
# Login attempts
# Timeline

# Terraform:

# azurerm_sentinel_alert_rule_* (some overlap)
# Workbook JSON deployments

# 8. Detection Layer (Where Sentinel becomes useful)
# 🔹 Analytics Rules

# Terraform:

# azurerm_sentinel_alert_rule_scheduled
# Example Detections:
# Brute force (multiple 4625 events)
# Impossible travel
# Suspicious IPs


# azurerm_sentinel_data_connector_azure_active_directory
# see what ips are signing into your azure account