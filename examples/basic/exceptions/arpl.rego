package Azure_Proactive_Resiliency_Library_v2

import rego.v1

exception contains rules if {
  rules = [
      "virtual_machine_scaleset_zonal_support", 
      "virtual_machine_scaleset_enable_automatic_repair",
      "public_ip_use_standard_sku_and_zone_redundant_ip",
      "virtual_machine_scaleset_orchestration_mode_flexible",
  ]
}