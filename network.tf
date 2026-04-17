
resource "azurerm_resource_group" "resource_group" {
  name = "honeypot-resource-group"
  location = "westus3"
}

resource "azurerm_virtual_network" "virtual_network" {
  name = "honeypot-virtual-network"
  address_space = [ var.address_space_vnet ]
  resource_group_name = azurerm_resource_group.resource_group.name
  location = azurerm_resource_group.resource_group.location
}

resource "azurerm_subnet" "subnet-honeypot" {
  name = "internal-subnet"
  resource_group_name = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes = [ var.address_space_subnet_honeypot ]
}

resource "azurerm_network_security_group" "network_security_group" {
  name = "honeypot-network-security-group"
  resource_group_name = azurerm_resource_group.resource_group.name
  location = azurerm_resource_group.resource_group.location
}

resource "azurerm_subnet_network_security_group_association" "subnet-sga" {
  subnet_id = azurerm_subnet.subnet-honeypot.id
  network_security_group_id = azurerm_network_security_group.network_security_group.id
}

# inbound
resource "azurerm_network_security_rule" "rdp-allow-rule" {
  name = "AllowRDPInbound"
  priority = 100
  direction = "Inbound"
  access = "Allow"
  protocol = "Tcp"
  source_port_range = "*"
  destination_port_range = "3389"
  source_address_prefix = var.personal_public_ip
  # change source prefix to allow attackers from every country for now public ip to test
  destination_address_prefix = var.address_space_subnet_honeypot
  resource_group_name = azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.network_security_group.name
}

resource "azurerm_network_security_rule" "deny-all-rule" {
  name = "DenyAllInbound"
  priority = 400
  direction = "Inbound"
  access = "Deny"
  protocol = "Tcp"
  source_port_range = "*"
  destination_port_range = "*"
  source_address_prefix = "*"
  destination_address_prefix = "*"
  resource_group_name = azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.network_security_group.name
}

# outbound
resource "azurerm_network_security_rule" "logs-allow-rule" {
  name = "AllowLogsRule"
  priority = 100
  direction = "Outbound"
  access = "Allow"
  protocol = "Tcp"
  source_port_range = "*"
  destination_port_range = "443"
  source_address_prefix = "*"
  destination_address_prefix = "AzureMonitor"
  resource_group_name = azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.network_security_group.name
}

resource "azurerm_network_security_rule" "deny-internet-rule" {
  name = "DenyInternetRule"
  priority = 400
  direction = "Outbound"
  access = "Deny"
  protocol = "*"
  source_port_range = "*"
  destination_port_range = "*"
  source_address_prefix = "*"
  destination_address_prefix = "Internet"
  resource_group_name = azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.network_security_group.name
}

resource "azurerm_public_ip" "pip" {
  name = "honeypot-pip"
  resource_group_name = azurerm_resource_group.resource_group.name
  location = azurerm_resource_group.resource_group.location
  allocation_method = "Static"
}

#storage
resource "azurerm_storage_account_network_rules" "storage-network" {
  storage_account_id = azurerm_storage_account.storage-account.id
  default_action = "Deny"
  ip_rules = [var.personal_public_ip]
  virtual_network_subnet_ids = [azurerm_subnet.subnet-honeypot.id]
  bypass = ["Logging", "Metrics", "AzureServices"]
}