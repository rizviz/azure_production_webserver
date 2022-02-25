provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
}
# Create VNETs and associated subnets
resource "azurerm_virtual_network" "ProdVNET" {
  name                = "${var.prefix}-ProdVNET"
  address_space       = ["10.170.160.0/20"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}
resource "azurerm_virtual_network" "NonProdVNET" {
  name                = "${var.prefix}-NonProdVNET"
  address_space       = ["10.180.160.0/20"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}
resource "azurerm_subnet" "ProdPubSubnet" {
  name                 = "ProdPubSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.ProdVNET.name
  address_prefixes     = ["10.170.161.0/24"]
}

resource "azurerm_subnet" "ProdPvtSubnet" {
   name                 = "ProdPvtSubnet"
   resource_group_name  = azurerm_resource_group.main.name
   virtual_network_name = azurerm_virtual_network.ProdVNET.name
   address_prefixes     = ["10.170.171.0/24"]
 }


resource "azurerm_public_ip" "pub_ip" {
  name                = "${var.prefix}-pub_ip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic1"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.ProdPubSubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pub_ip.id
  }
}

resource "azurerm_network_interface" "ProdPubSubnet" {
  name                      = "${var.prefix}-nic2"
  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "ProdPubSubnet"
    subnet_id                     = azurerm_subnet.ProdPubSubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Azure Network Watcher Group Explicit declaration because TF won't delete defualt one created by Azure
resource "azurerm_resource_group" "nwatcher" {
  name     = "${var.prefix}-prod-nwwatcher"
  location = var.location
}

resource "azurerm_network_watcher" "nwatcher" {
  name                = "${var.prefix}-prod-nwwatcher"
  location            = azurerm_resource_group.nwatcher.location
  resource_group_name = azurerm_resource_group.nwatcher.name
}

# Security Groups to allow for services to connect

resource "azurerm_network_security_group" "inbound_tcp_ports" {
  name                = "InboundNSG1"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_network_security_group" "inbound_udp_ports" {
   name                = "InboundNSG2"
   location            = azurerm_resource_group.main.location
   resource_group_name = azurerm_resource_group.main.name
 }

resource "azurerm_network_security_rule" "tcp_ports" {
   count = "${length(var.tcp_ports)}"
   name                       = "sg-rule-${count.index}"
   direction                  = "Inbound"
   access                     = "Allow"
   priority                   = "${(100 * (count.index + 1))}"
   source_address_prefix      = "*"
   source_port_range          = "*"
   destination_address_prefix = "*"
   destination_port_range     = "${element(var.tcp_ports, count.index)}"
   protocol                   = "TCP"
   resource_group_name         = azurerm_resource_group.main.name
   network_security_group_name = azurerm_network_security_group.inbound_tcp_ports.name
 }

resource "azurerm_network_security_rule" "udp_ports" {
    count = "${length(var.tcp_ports)}"
    name                       = "sg-rule-${count.index}"
    direction                  = "Inbound"
    access                     = "Allow"
    priority                   = "${(100 * (count.index + 1))}"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "${element(var.udp_ports, count.index)}"
    protocol                   = "UDP"
    resource_group_name         = azurerm_resource_group.main.name
    network_security_group_name = azurerm_network_security_group.inbound_udp_ports.name
  }


resource "azurerm_network_interface_security_group_association" "web1" {
  network_interface_id      = azurerm_network_interface.ProdPubSubnet.id
  network_security_group_id = azurerm_network_security_group.inbound_tcp_ports.id
}

resource "azurerm_network_interface_security_group_association" "web2" {
   network_interface_id      = azurerm_network_interface.ProdPubSubnet.id
   network_security_group_id = azurerm_network_security_group.inbound_udp_ports.id
 }


resource "azurerm_linux_virtual_machine" "main" {
  name                            = "${var.prefix}-vm"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_B1ms"
  admin_username                  = "adminuser"
  admin_password                  = "P@ssw0rd1234!"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.main.id,
    azurerm_network_interface.ProdPubSubnet.id,
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  
  admin_ssh_key {
    username = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}
