resource "azurerm_kubernetes_cluster" "aks_cluster" {
  location                            = var.location
  name                                = var.aks_name
  dns_prefix                          = var.dns_name
  azure_policy_enabled                = false
  custom_ca_trust_certificates_base64 = []
  http_application_routing_enabled    = false
  node_os_upgrade_channel             = "NodeImage"
  oidc_issuer_enabled                 = false
  open_service_mesh_enabled           = false
  private_cluster_enabled             = false
  private_cluster_public_fqdn_enabled = false
  resource_group_name                 = var.resource_group_name
  role_based_access_control_enabled   = true
  run_command_enabled                 = true
  sku_tier                            = "Free"

  default_node_pool {
    auto_scaling_enabled         = false
    fips_enabled                 = false
    host_encryption_enabled      = false
    kubelet_disk_type            = "OS"
    max_pods                     = 250
    name                         = "master"
    node_count                   = 2
    node_public_ip_enabled       = false
    only_critical_addons_enabled = false
    orchestrator_version         = "1.32"
    os_disk_size_gb              = 150
    os_disk_type                 = "Ephemeral"
    os_sku                       = "Ubuntu"
    scale_down_mode              = "Delete"

    type              = "VirtualMachineScaleSets"
    ultra_ssd_enabled = false
    vm_size           = "Standard_D4d_v4"

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    identity_ids = []
    type         = "SystemAssigned"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
  }

  web_app_routing {
    default_nginx_controller = "AnnotationControlled"
    dns_zone_ids             = []
  }

}
