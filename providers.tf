/*********************************
vm
Standard_D2s_v3 - 2 vcpus, 8 GiB memory ($0.02033)
azure spot
$20 a month


providers.tf: To tell Terraform to talk to Azure.

network.tf: For the VNet, Subnet, and NSG.

vm.tf: For the VM and Public IP.

sentinel.tf: For the Log Analytics Workspace and SIEM setup.

budget alerts when close to $10-$20

**********************************/ 


terraform {
    required_providers {
      azurerm = {
        source = "hashicorp/azurerm"
        version = "~> 4.0"
      }
    }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
  }
}