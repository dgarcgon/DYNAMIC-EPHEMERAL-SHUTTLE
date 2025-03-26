## Loop for subnets ##

resource "azurerm_subnet" "subnets" {
  for_each                                  = var.deployment_def.subnets
  provider                                  = azurerm.local
  name                                      = each.key
  virtual_network_name                      = azurerm_virtual_network.local.name
  address_prefixes                          = ["${each.value.ip}"]
  resource_group_name                       = azurerm_resource_group.local.name
  private_endpoint_network_policies         = each.value.privep
}

### Create NSGs for subnet ###

resource "azurerm_network_security_group" "nsgs" {
  for_each            = var.deployment_def.subnets
  provider            = azurerm.local
  resource_group_name = azurerm_resource_group.local.name
  location            = azurerm_resource_group.local.location
  name                = "${var.deployment_def.code}-${each.key}-nsg"
}

### Associate NSGs to Subnets ###

resource "azurerm_subnet_network_security_group_association" "nsgassociation" {
  for_each                  = var.deployment_def.subnets
  provider                  = azurerm.local
  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsgs[each.key].id
}

### Associate subnets to NATGW ###

resource "azurerm_subnet_nat_gateway_association" "natgwassociation" {
  for_each       = var.deployment_def.subnets
  provider       = azurerm.local
  subnet_id      = azurerm_subnet.subnets[each.key].id
  nat_gateway_id = azurerm_nat_gateway.natgw.id
}
