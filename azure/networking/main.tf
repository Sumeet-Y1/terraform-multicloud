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

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
  }
}

# Virtual Network
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

# ---------- NAT GATEWAY (for private subnet outbound internet) ----------
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
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

# Associate NAT Gateway with private subnets (so they get outbound internet)
resource "azurerm_subnet_nat_gateway_association" "private" {
  for_each       = azurerm_subnet.private
  subnet_id      = each.value.id
  nat_gateway_id = azurerm_nat_gateway.main.id
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
  name                                       = "allow-http-https"
  priority                                   = 100
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_ranges                    = ["80", "443"]
  source_address_prefix                      = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.web.id]
  resource_group_name                        = azurerm_resource_group.main.name
  network_security_group_name                = azurerm_network_security_group.public.name
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
  name                                        = "allow-from-web-asg"
  priority                                    = 100
  direction                                   = "Inbound"
  access                                      = "Allow"
  protocol                                    = "Tcp"
  source_port_range                           = "*"
  destination_port_range                      = "8080"
  source_application_security_group_ids       = [azurerm_application_security_group.web.id]
  destination_application_security_group_ids  = [azurerm_application_security_group.app.id]
  resource_group_name                         = azurerm_resource_group.main.name
  network_security_group_name