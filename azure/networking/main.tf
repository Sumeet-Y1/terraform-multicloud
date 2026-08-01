terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.environment}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
  }
}

# ---------- SUBNETS ----------
resource "azurerm_subnet" "public" {
  for_each             = var.public_subnets
  name                 = "${var.environment}-public-${each.key}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value]
}

resource "azurerm_subnet" "private" {
  for_each             = var.private_subnets
  name                 = "${var.environment}-private-${each.key}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value]
}

resource "azurerm_subnet" "database" {
  for_each             = var.database_subnets
  name                 = "${var.environment}-database-${each.key}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value]
}

# ---------- AZURE BASTION (managed jump-host service, no VM to patch/manage) ----------
# Must be named exactly "AzureBastionSubnet" and be at least /26
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.bastion_subnet_cidr]
}

resource "azurerm_public_ip" "bastion" {
  name                = "${var.environment}-bastion-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_bastion_host" "main" {
  name                = "${var.environment}-bastion"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = {
    Environment = var.environment
  }
}

# ---------- NAT GATEWAY ----------
resource "azurerm_public_ip" "nat" {
  name                = "${var.environment}-nat-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_nat_gateway" "main" {
  name                = "${var.environment}-nat-gw"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard"

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id        = azurerm_nat_gateway.main.id
  public_ip_address_id  = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "private" {
  for_each       = azurerm_subnet.private
  subnet_id      = each.value.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}

# ---------- PRIVATE ENDPOINT (Azure Storage access without internet) ----------
resource "azurerm_private_endpoint" "storage" {
  count               = var.storage_account_id != "" ? 1 : 0
  name                = "${var.environment}-storage-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private["a"].id

  private_service_connection {
    name                           = "${var.environment}-storage-psc"
    private_connection_resource_id = var.storage_account_id
    subresource_names               = ["blob"]
    is_manual_connection            = false
  }

  tags = {
    Environment = var.environment
  }
}

# ---------- APPLICATION SECURITY GROUPS ----------
resource "azurerm_application_security_group" "web" {
  name                = "${var.environment}-web-asg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_application_security_group" "app" {
  name                = "${var.environment}-app-asg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_application_security_group" "database" {
  name                = "${var.environment}-database-asg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
  }
}

# ---------- NETWORK SECURITY GROUPS ----------
resource "azurerm_network_security_group" "public" {
  name                = "${var.environment}-public-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_network_security_rule" "web_http_https" {
  name                                        = "allow-http-https"
  priority                                    = 100
  direction                                   = "Inbound"
  access                                       = "Allow"
  protocol                                    = "Tcp"
  source_port_range                           = "*"
  destination_port_ranges                     = ["80", "443"]
  source_address_prefix                       = "*"
  destination_application_security_group_ids  = [azurerm_application_security_group.web.id]
  resource_group_name                          = azurerm_resource_group.main.name
  network_security_group_name                  = azurerm_network_security_group.public.name
}

resource "azurerm_network_security_group" "private" {
  name                = "${var.environment}-private-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_network_security_rule" "app_from_web" {
  name                                         = "allow-from-web-asg"
  priority                                     = 100
  direction                                    = "Inbound"
  access                                        = "Allow"
  protocol                                     = "Tcp"
  source_port_range                            = "*"
  destination_port_range                       = "8080"
  source_application_security_group_ids        = [azurerm_application_security_group.web.id]
  destination_application_security_group_ids   = [azurerm_application_security_group.app.id]
  resource_group_name                           = azurerm_resource_group.main.name
  network_security_group_name                   = azurerm_network_security_group.private.name
}

# SSH access to app/db tiers only from the AzureBastionSubnet range
resource "azurerm_network_security_rule" "app_ssh_from_bastion" {
  name                         = "allow-ssh-from-bastion"
  priority                     = 110
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = "22"
  source_address_prefix        = var.bastion_subnet_cidr
  destination_address_prefix   = "*"
  resource_group_name          = azurerm_resource_group.main.name
  network_security_group_name  = azurerm_network_security_group.private.name
}

resource "azurerm_network_security_group" "database" {
  name                = "${var.environment}-database-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_network_security_rule" "db_from_app" {
  name                                         = "allow-from-app-asg"
  priority                                     = 100
  direction                                    = "Inbound"
  access                                        = "Allow"
  protocol                                     = "Tcp"
  source_port_range                            = "*"
  destination_port_range                       = "5432"
  source_application_security_group_ids        = [azurerm_application_security_group.app.id]
  destination_application_security_group_ids    = [azurerm_application_security_group.database.id]
  resource_group_name                           = azurerm_resource_group.main.name
  network_security_group_name                   = azurerm_network_security_group.database.name
}

resource "azurerm_network_security_rule" "db_ssh_from_bastion" {
  name                         = "allow-ssh-from-bastion"
  priority                     = 110
  direction                    = "Inbound"
  access                       = "Allow"
  protocol