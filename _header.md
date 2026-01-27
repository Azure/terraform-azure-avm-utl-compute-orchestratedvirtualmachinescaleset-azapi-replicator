# terraform-azure-avm-utl-compute-orchestratedvirtualmachinescaleset-azapi-replicator

This is a replicator module that help you to migrate your `azurerm_orchestrated_virtual_machine_scale_set` resource into AzAPI provider. Assuming you have AzureRM resource like:

```hcl
resource "azurerm_orchestrated_virtual_machine_scale_set" "test" {
  name                = "acctestOVMSS-${random_integer.number.result}"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
...
}
```

Now you want to use a preview API version and try some preview features by setting these preview arguments, but you cannot do this by using AzureRM provider, since it doesn't accept preview features.

Now you can call this module like:

```hcl
module "vmss_replicator" {
  source = "utl-compute-orchestratedvirtualmachinescaleset-azapi-replicator"

  name                        = "acctestOVMSS-${random_integer.number.result}"
  location                    = azurerm_resource_group.test.location
  resource_group_id           = azurerm_resource_group.test.id
  platform_fault_domain_count = 2

  zones = []

  sku_name  = "Standard_D1_v2"
  instances = 2
...
}

resource "azapi_resource" "this" {
  type                 = module.vmss_replicator.azapi_header.type
  name                 = module.vmss_replicator.azapi_header.name
  location             = module.vmss_replicator.azapi_header.location
  parent_id            = module.vmss_replicator.azapi_header.parent_id
  tags                 = module.vmss_replicator.azapi_header.tags
  body                 = module.vmss_replicator.body
  ignore_null_property = module.vmss_replicator.azapi_header.ignore_null_property

  sensitive_body         = module.vmss_replicator.sensitive_body
  sensitive_body_version = module.vmss_replicator.sensitive_body_version

  replace_triggers_external_values = module.vmss_replicator.replace_triggers_external_values

  locks = module.vmss_replicator.locks

  dynamic "identity" {
    for_each = can(module.vmss_replicator.azapi_header.identity) ? [module.vmss_replicator.identity] : []
    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  retry = module.vmss_replicator.retry

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
  type           = module.vmss_replicator.post_creation_updates[0].azapi_header.type
  name           = module.vmss_replicator.post_creation_updates[0].azapi_header.name
  parent_id      = module.vmss_replicator.post_creation_updates[0].azapi_header.parent_id
  body           = module.vmss_replicator.post_creation_updates[0].body
  sensitive_body = try(module.vmss_replicator.post_creation_updates[0].sensitive_body, null)
  depends_on     = [azapi_resource.this]
  lifecycle {
    ignore_changes = all
  }
}
```

This module utilizes the flexibility of AzAPI at the bottom layer while perfectly replicating the rigorous logic of AzureRM at the top layer, allowing you to enjoy freedom while still having solid security guarantees. 
