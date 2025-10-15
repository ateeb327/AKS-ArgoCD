terraform {
  required_version = ">= 1.1.5"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0.2"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

# Get AKS cluster data
data "azurerm_kubernetes_cluster" "primary" {
  name                = var.aks_name
  resource_group_name = var.resource_group_name
}

# Configure Kubernetes Provider
provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.primary.kube_config[0].host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config[0].client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config[0].cluster_ca_certificate)
}

# Configure Helm Provider
provider "helm" {
  kubernetes = {
    host                   = data.azurerm_kubernetes_cluster.primary.kube_config[0].host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config[0].client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config[0].cluster_ca_certificate)
  }
}

# Configure kubectl Provider
provider "kubectl" {
  host                   = data.azurerm_kubernetes_cluster.primary.kube_config[0].host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config[0].client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config[0].cluster_ca_certificate)
  load_config_file       = false
}

# Create ArgoCD namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name" = "argocd"
    }
  }
}

### [CERT-MANAGER] ###
# Deploy cert-manager
resource "helm_release" "cert_manager" {
  count = var.deploy_cert_manager ? 1 : 0

  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = "v1.14.5"

  set = [
    {
      name  = "installCRDs"
      value = "true"
    },
    {
      name  = "global.leaderElection.namespace"
      value = "cert-manager"
    }
  ]

  wait          = true
  wait_for_jobs = true
  timeout       = 300
}

# Wait for cert-manager to be ready before creating issuers
resource "time_sleep" "wait_for_cert_manager" {
  count = var.deploy_cert_manager ? 1 : 0

  depends_on = [helm_release.cert_manager]

  create_duration = "30s"
}

# Create Let's Encrypt ClusterIssuer (Production)
resource "kubectl_manifest" "letsencrypt_prod" {
  count = var.create_cluster_issuer ? 1 : 0

  depends_on = [
    helm_release.cert_manager,
    time_sleep.wait_for_cert_manager
  ]

  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-prod
    spec:
      acme:
        server: https://acme-v02.api.letsencrypt.org/directory
        email: ${var.letsencrypt_email}
        privateKeySecretRef:
          name: letsencrypt-prod
        solvers:
        - http01:
            ingress:
              class: ${var.ingress_class_name}
  YAML
}


### [Cert-manager END] ###
resource "helm_release" "argocd_deploy" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.6.8" # Use latest stable version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  # Wait for deployment to complete
  wait          = true
  wait_for_jobs = true
  timeout       = 600

  values = [
    templatefile("${path.module}/argocd-values.yaml", {
      hostname              = var.argocd_config.hostname
      ingress_class_name    = var.ingress_class_name
      redis_ha_enabled      = var.argocd_config.redis_ha_enabled
      autoscaling_enabled   = var.argocd_config.autoscaling_enabled
      notifications_enabled = var.argocd_config.argocd_notifications_enabled
      cluster_issuer        = var.argocd_config.cluster_issuer
    })
  ]

  depends_on = [kubernetes_namespace.argocd]
}

# Get ArgoCD initial admin secret
data "kubernetes_secret" "argocd_secret" {
  depends_on = [helm_release.argocd_deploy]
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = var.namespace
  }
}

# Get ArgoCD server service for LoadBalancer IP
data "kubernetes_service" "argocd_server" {
  depends_on = [helm_release.argocd_deploy]
  metadata {
    name      = "argocd-server"
    namespace = var.namespace
  }
}
