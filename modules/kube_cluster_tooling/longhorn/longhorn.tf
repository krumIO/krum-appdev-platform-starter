// Providers
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.22.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.10.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}

// Create a random password for the Longhorn UI
resource "random_password" "longhorn_ui_password" {
  count   = var.enable_module ? 1 : 0
  length  = 32
  special = false
}

// Create a namespace for Longhorn
resource "kubernetes_namespace" "longhorn" {
  count = var.enable_module ? 1 : 0
  metadata {
    name = "longhorn-system"
  }
}

// Create a secret for the Longhorn UI password
resource "kubernetes_secret" "longhorn_ui_password" {
  count = var.enable_module ? 1 : 0
  metadata {
    name      = "longhorn-ui-password"
    namespace = kubernetes_namespace.longhorn[0].metadata[0].name
  }
  data = {
    password = base64encode(random_password.longhorn_ui_password[0].result)
  }
  type = "Opaque"
}

// create local file containing longhorn ui password
resource "local_file" "longhorn_ui_password" {
  count    = var.enable_module ? 1 : 0
  filename = "${var.artifact_output_directory}/longhorn-ui-password.txt"
  content  = random_password.longhorn_ui_password[0].result
}

// helm install longhorn
resource "helm_release" "longhorn" {
  count      = var.enable_module ? 1 : 0
  name       = "longhorn"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  version    = var.longhorn_version

  namespace        = "longhorn-system"
  create_namespace = true
  wait             = true

#   values = [
#     <<EOF
#     # persistence
#     #   defaultClass: true
#     #   defaultClassReplicaCount: 3
#     ingress:
#       enabled: ${var.enable_longhorn_ingress != null ? "true" : "false"}
#       ingressClassName: ${var.ingress_class_name}
#       host: longhorn.${var.dns_domain != null ? var.dns_domain : ""}
#       tls: true
#       secureBackend: true
#       tlsSecret: longhorn-tls
#       annotations:
#         kubernetes.io/ingress.class: ${var.ingress_class_name}
#         cert-manager.io/cluster-issuer: ${var.cert_manager_cluster_issuer}
#     EOF
#   ]
}

// variables
variable "longhorn_version" {
  description = "longhorn version"
  default     = "1.1.2"
}

variable "monitoring_enabled" {
  description = "monitoring enabled"
  default     = false
}

variable "enable_longhorn_ingress" {
  description = "enable longhorn ingress"
  default     = false
}

variable "cert_manager_cluster_issuer" {
  description = "cert manager cluster issuer"
  default     = "letsencrypt-production"
}

variable "dns_domain" {
  description = "dns domain"
  default     = null
}

variable "ingress_class_name" {
  description = "ingress class name"
  default     = "traefik"
}

variable "enable_module" {
  description = "enable module"
  default     = true
}

variable "artifact_output_directory" {
  description = "artifact output directory"
}

// outputs
output "longhorn_ui_url" {
  value = var.enable_module ? "http://longhorn.${var.dns_domain != null ? var.dns_domain : ""}" : null
}
