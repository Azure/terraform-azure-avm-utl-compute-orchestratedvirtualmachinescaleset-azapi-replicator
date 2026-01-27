resource "random_integer" "number" {
  max = 100000
  min = 10000
}

resource "random_string" "name" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_resource_group" "test" {
  location = "westus"
  name     = "vmss-replicator-${random_integer.number.result}"
}

resource "azurerm_public_ip" "test" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.test.location
  name                = "vmss-replicator-pip-${random_integer.number.result}"
  resource_group_name = azurerm_resource_group.test.name
  sku                 = "Standard"
}

resource "azurerm_virtual_network" "test" {
  location            = azurerm_resource_group.test.location
  name                = "acctvn-${random_integer.number.result}"
  resource_group_name = azurerm_resource_group.test.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "test" {
  address_prefixes     = ["10.0.2.0/24"]
  name                 = "acctsub-${random_integer.number.result}"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test.name
}

resource "azurerm_nat_gateway" "test" {
  location                = azurerm_resource_group.test.location
  name                    = "acctng-${random_integer.number.result}"
  resource_group_name     = azurerm_resource_group.test.name
  idle_timeout_in_minutes = 10
  sku_name                = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "test" {
  nat_gateway_id       = azurerm_nat_gateway.test.id
  public_ip_address_id = azurerm_public_ip.test.id
}

resource "azurerm_subnet_nat_gateway_association" "example" {
  nat_gateway_id = azurerm_nat_gateway.test.id
  subnet_id      = azurerm_subnet.test.id
}

ephemeral "random_password" pass {
  length  = 16
  lower   = true
  numeric = true
  special = true
  upper   = true
}

module "vmss_replicator" {
  source = "../.."

  location                    = azurerm_resource_group.test.location
  name                        = "acctestOVMSS-${random_integer.number.result}"
  platform_fault_domain_count = 2
  resource_group_id           = azurerm_resource_group.test.id
  enable_telemetry            = var.enable_telemetry
  instances                   = 2
  network_interface = [
    {
      name    = "TestNetworkProfile-${random_integer.number.result}"
      primary = true

      ip_configuration = [
        {
          name      = "TestIPConfiguration"
          primary   = true
          subnet_id = azurerm_subnet.test.id

          public_ip_address = [
            {
              name                    = "TestPublicIPConfiguration"
              domain_name_label       = "test-domain-label"
              idle_timeout_in_minutes = 4
            }
          ]
        }
      ]
    }
  ]
  os_disk = {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  os_profile = {
    linux_configuration = {
      computer_name_prefix            = "testvm-${random_integer.number.result}"
      admin_username                  = "myadmin"
      disable_password_authentication = false
    }
  }
  os_profile_linux_configuration_admin_password         = ephemeral.random_password.pass.result
  os_profile_linux_configuration_admin_password_version = 1
  sku_name                                              = "Standard_D1_v2"
  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  zones = []
}

resource "azapi_resource" "this" {
  location                         = module.vmss_replicator.azapi_header.location
  name                             = module.vmss_replicator.azapi_header.name
  parent_id                        = module.vmss_replicator.azapi_header.parent_id
  type                             = module.vmss_replicator.azapi_header.type
  body                             = module.vmss_replicator.body
  ignore_null_property             = module.vmss_replicator.azapi_header.ignore_null_property
  locks                            = module.vmss_replicator.locks
  replace_triggers_external_values = module.vmss_replicator.replace_triggers_external_values
  retry                            = module.vmss_replicator.retry
  sensitive_body                   = module.vmss_replicator.sensitive_body
  sensitive_body_version           = module.vmss_replicator.sensitive_body_version
  tags                             = module.vmss_replicator.azapi_header.tags

  dynamic "identity" {
    for_each = can(module.vmss_replicator.azapi_header.identity) ? [module.vmss_replicator.identity] : []

    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }
  dynamic "timeouts" {
    for_each = module.vmss_replicator.timeouts != null ? [module.vmss_replicator.timeouts] : []

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azapi_update_resource" "update0" {
  name           = module.vmss_replicator.post_creation_updates[0].azapi_header.name
  parent_id      = module.vmss_replicator.post_creation_updates[0].azapi_header.parent_id
  type           = module.vmss_replicator.post_creation_updates[0].azapi_header.type
  body           = module.vmss_replicator.post_creation_updates[0].body
  sensitive_body = try(module.vmss_replicator.post_creation_updates[0].sensitive_body, null)

  depends_on = [azapi_resource.this]

  lifecycle {
    ignore_changes = all
  }
}
