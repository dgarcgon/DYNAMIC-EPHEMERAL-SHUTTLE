terraform {
  backend "azurerm" {}
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.99.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.deployment_def.subscription_id
  alias           = "local"
  features {}
}

provider "azurerm" {
  subscription_id = var.deployment_def.hub_subscription_id
  alias           = "remote"
  features {}
}

provider "azurerm" {
  subscription_id = var.deployment_def.sup_subscription_id
  alias           = "sup"
  features {}
}

resource "azurerm_resource_group" "local" {
  provider = azurerm.local
  name     = "${var.deployment_def.code}-base-rg"
  location = var.deployment_def.deployment_location
}

resource "azurerm_virtual_network" "local" {
  provider            = azurerm.local
  name                = "${var.deployment_def.code}-vnet"
  location            = azurerm_resource_group.local.location
  resource_group_name = azurerm_resource_group.local.name
  address_space       = ["${var.deployment_def.vnet_supernet}"]
  dns_servers         = var.deployment_def.vnet_dns
}

data "azurerm_resource_group" "remote" {
  provider = azurerm.remote
  name     = "hub-base-rg"
}

data "azurerm_resource_group" "sup" {
  provider = azurerm.sup
  name     = "sup-rg"
}

data "azurerm_virtual_network" "remote" {
  provider            = azurerm.remote
  name                = "hub-vnet"
  resource_group_name = data.azurerm_resource_group.remote.name
}

data "azurerm_virtual_network" "sup" {
  provider            = azurerm.sup
  name                = "sup-vnet"
  resource_group_name = data.azurerm_resource_group.sup.name
}

resource "azurerm_virtual_network_peering" "local-remote" {
  provider                     = azurerm.local
  name                         = "hub-${var.deployment_def.code}-vnet-peering"
  resource_group_name          = azurerm_resource_group.local.name
  virtual_network_name         = azurerm_virtual_network.local.name
  remote_virtual_network_id    = data.azurerm_virtual_network.remote.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = true
}

resource "azurerm_virtual_network_peering" "remote-local" {
  provider                  = azurerm.remote
  name                      = "${var.deployment_def.code}-hub-vnet-peering"
  resource_group_name       = data.azurerm_resource_group.remote.name
  virtual_network_name      = data.azurerm_virtual_network.remote.name
  remote_virtual_network_id = azurerm_virtual_network.local.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

resource "azurerm_virtual_network_peering" "local-sup" {
  provider                     = azurerm.local
  name                         = "sup-${var.deployment_def.code}-vnet-peering"
  resource_group_name          = azurerm_resource_group.local.name
  virtual_network_name         = azurerm_virtual_network.local.name
  remote_virtual_network_id    = data.azurerm_virtual_network.sup.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "sup-local" {
  provider                  = azurerm.sup
  name                      = "${var.deployment_def.code}-sup-vnet-peering"
  resource_group_name       = data.azurerm_resource_group.sup.name
  virtual_network_name      = data.azurerm_virtual_network.sup.name
  remote_virtual_network_id = azurerm_virtual_network.local.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

resource "azurerm_public_ip" "natgw" {
  provider            = azurerm.local
  name                = "${var.deployment_def.code}-nat-gateway-publicIP"
  location            = azurerm_resource_group.local.location
  resource_group_name = azurerm_resource_group.local.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

resource "azurerm_nat_gateway" "natgw" {
  provider                = azurerm.local
  name                    = "${var.deployment_def.code}-nat-gateway"
  location                = azurerm_resource_group.local.location
  resource_group_name     = azurerm_resource_group.local.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_nat_gateway_public_ip_association" "natgw" {
  provider             = azurerm.local
  nat_gateway_id       = azurerm_nat_gateway.natgw.id
  public_ip_address_id = azurerm_public_ip.natgw.id
}
