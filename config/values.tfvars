aks_name                   = "myakscluster"
location                   = "East US"
dnszone_resourcegroup_name = "myaks-rg"

argocd_config = {
  hostname                     = "testdomain.xyz.com"
  ingress_class_name           = "webapprouting.kubernetes.azure.com"
  redis_ha_enabled             = false
  autoscaling_enabled          = true
  argocd_notifications_enabled = false
  cluster_issuer               = "letsencrypt-prod"
}

namespace          = "argocd"
ingress_class_name = "webapprouting.kubernetes.azure.com"

cluster_issuer        = "letsencrypt-prod"
create_cluster_issuer = true
deploy_cert_manager   = true
letsencrypt_email     = ""
