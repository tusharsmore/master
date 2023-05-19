provider "azurerm" {
  features {}
}


variable "prefix" {
  default = "tushar"
}

resource "azurerm_resource_group" "tushar" {
  name     = "${var.prefix}-resources"
  location = "West Europe"
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.tushar.location
  resource_group_name = azurerm_resource_group.tushar.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.tushar.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.tushar.name
  location            = azurerm_resource_group.tushar.location
  allocation_method   = "Static"

}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.tushar.location
  resource_group_name = azurerm_resource_group.tushar.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_windows_virtual_machine" "main" {
    name                  = "test-vm"
    location              = azurerm_resource_group.tushar.location
    resource_group_name   = azurerm_resource_group.tushar.name
    network_interface_ids = [azurerm_network_interface.main.id]
    size                  = "Standard_B2s"
    admin_username        = "adminuser"
    admin_password        = "P@$$w0rd1234!"



 os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"

    
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

}

resource "azurerm_managed_disk" "Data_disk" {
  name                 = "Data_disk"
  location             = azurerm_resource_group.tushar.location
  resource_group_name  = azurerm_resource_group.tushar.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1"

  tags = {
    environment = "staging"
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "example" {
  managed_disk_id    = azurerm_managed_disk.Data_disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.main.id
  lun                = "10"
  caching            = "ReadWrite"
}