###############################################
## Provider ##
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
    rancher2 = {
      source = "rancher/rancher2"
      version = "4.1.0"
    }
  }
}

provider "rancher2" {
  alias = "bootstrap"

  api_url  = "https://rancher.${var.dns_domain != null ? var.dns_domain : ""}"
  insecure = false
  # ca_certs  = data.kubernetes_secret.rancher_cert.data["ca.crt"]
  bootstrap = true
}

provider "rancher2" {
  alias = "admin"

  api_url  = "https://rancher.${var.dns_domain != null ? var.dns_domain : ""}"
  insecure = false
  # ca_certs  = data.kubernetes_secret.rancher_cert.data["ca.crt"]
  token_key = rancher2_bootstrap.admin[0].token
  timeout   = "300s"
}

###############################################
## Variables ##
variable "rancher_version" {
  description = "The version of the Rancher to be deployed."
  type        = string
}

variable "dns_domain" {
  description = "The DNS domain to be used for the setup."
  type        = string
}

variable "ingress_class_name" {
  description = "The Ingress Class Name."
  type        = string
}

variable "email" {
  description = "The email for letsencrypt setup."
  type        = string
}

variable "kube_config_file" {
  description = "Path to kubeconfig file"
  type        = string
}

variable "file_output_directory" {
  description = "Path to output directory"
  type        = string
}

variable "enable_module" {
  description = "Enable module"
  type        = bool
  default     = true
}

variable "rancher_release_channel" {
  description = "The release channel of the Rancher to be deployed."
  type        = string
  default    = "stable"
}

variable "prefix" {
  description = "The prefix to be used for the setup."
  type        = string
}

variable "cluster2_rke2_k3s_version" {
  description = "The version of the RKE2/K3s to be deployed."
  type        = string
}

// Generate a random password for rancher admin user auth and traefik dashboard basic-auth
resource "random_password" "rancher_admin_password" {
  count            = var.enable_module ? 1 : 0
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "local_file" "rancher_admin_password_and_url" {
  count    = var.enable_module ? 1 : 0
  content  = "Admin Username: admin\nAdmin Password: ${random_password.rancher_admin_password[0].result}\nRancher Server URL: https://rancher.${var.dns_domain != null ? var.dns_domain : ""}"
  filename = "${var.file_output_directory}/rancher-admin-password-and-url.txt"
}

###############################################
## Rancher ##
resource "helm_release" "rancher" {
  count      = var.enable_module ? 1 : 0
  name       = "rancher"
  repository = "https://releases.rancher.com/server-charts/${var.rancher_release_channel}"
  chart      = "rancher"
  version    = var.rancher_version

  namespace        = "cattle-system"
  create_namespace = true
  wait             = true

  set {
    name  = "hostname"
    value = "rancher.${var.dns_domain != null ? var.dns_domain : ""}"
  }
  set {
    name  = "letsEncrypt.ingress.class"
    value = var.ingress_class_name
  }
  set {
    name  = "bootstrapPassword"
    value = random_password.rancher_admin_password[0].result
  }
  set {
    name  = "replicas"
    value = "3"
  }
  set {
    name  = "ingress.tls.source"
    value = "letsEncrypt"
  }
  set {
    name  = "letsEncrypt.email"
    value = var.email
  }
  set {
    name  = "bootstrapPassword"
    value = random_password.rancher_admin_password[0].result
  }

    // set storage class
  set {
    name  = "storageClass"
    value = "longhorn"
  }

  depends_on = [random_password.rancher_admin_password]

}

# Initialize Rancher server
resource "rancher2_bootstrap" "admin" {
  count = var.enable_module ? 1 : 0
  depends_on = [
    helm_release.rancher,
  ]

  provider = rancher2.bootstrap

  initial_password = random_password.rancher_admin_password[0].result
  password  = random_password.rancher_admin_password[0].result
  telemetry = true
}

###############################################
// multicluster configuration
module "rancher_cluster" {
  source = "./rancher2_cluster"
  name = "${var.prefix}-cluster-2"
  rke2_k3s_version = "v1.28.9+k3s1"
  token_key = rancher2_bootstrap.admin[0].token
  rancher_api_url = "https://rancher.${var.dns_domain != null ? var.dns_domain : ""}"
}

// output rancher url
output "rancher_url" {
  value = "https://rancher.${var.dns_domain != null ? var.dns_domain : ""}"
}

// output rancher admin password
output "rancher_admin_password" {
  value = var.enable_module ? random_password.rancher_admin_password[0].result : null
}

// output helm repo url and name
output "helm_repo_url" {
  value = var.enable_module ? helm_release.rancher[0].repository : null
}

output "helm_repo_name" {
  value = var.enable_module ? helm_release.rancher[0].name : null 
}
