
resource "azurerm_network_interface" "nic" {
    name = "honeypot-nic"
    resource_group_name = azurerm_resource_group.resource_group.name
    location = azurerm_network_security_group.network_security_group.location

ip_configuration {
    name = "External"
    subnet_id = azurerm_subnet.subnet-honeypot.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pip.id
    }
}

resource "azurerm_network_interface_security_group_association" "nsg_network_interface" {
    network_interface_id = azurerm_network_interface.nic.id
    network_security_group_id = azurerm_network_security_group.network_security_group.id
}

resource "azurerm_windows_virtual_machine" "windows_vm" {
    name = "honeypot-vm"
    resource_group_name = "azurerm_resource_group.resource_group.name"
    location = "azurerm_resource_group.resource_group.location"
    size = "Standard_D2ls_v5"
    admin_username = var.admin_username_honeypot
    admin_password  = azurerm_key_vault_secret.vm-admin-password.value
    priority = "Spot"
    eviction_policy = "Deallocate"
    max_bid_price = -1

    network_interface_ids = [
        azurerm_network_interface.nic.id
    ]

    os_disk {
        caching = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_id = {
        publisher = "MicrosoftWindowsServer"
        offer = "WindowsServer"
        sku = "2025-datacenter-azure-edition-smalldisk"
        version = "latest"
    }

    identity {
      type = "SystemAssigned"
    }

}