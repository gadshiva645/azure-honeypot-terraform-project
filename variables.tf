variable "address_space_vnet" {
  type = string
  description = "vnet ip address space /16"
}

variable "address_space_subnet_honeypot" {
  type = string
  description = "subnet ip address honeypot space /24"
}

variable "personal_public_ip" {
  type = string
  description = "personal public ip address used access azure services. This value will change ever so often"
  sensitive = true
}

variable "admin_username_honeypot" {
  type = string
  description = "admin username for vm"
  sensitive = true
}