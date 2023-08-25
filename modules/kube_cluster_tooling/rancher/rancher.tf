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
  }
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

// Generate a random password for rancher admin user auth and traefik dashboard basic-auth
resource "random_password" "rancher_admin_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "local_sensitive_file" "rancher_admin_password_and_url" {
  content = "Admin Password: ${random_password.rancher_admin_password.result}\nRancher Server URL: ${join(".", ["https://rancher", "${var.dns_domain}"])}"
  filename          = "${var.file_output_directory}/rancher-admin-password-and-url.txt"
}

###############################################
## Rancher ##
resource "helm_release" "rancher" {
  name       = "rancher"
  repository = "https://releases.rancher.com/server-charts/stable"
  chart      = "rancher"
  version    = var.rancher_version

  namespace        = "cattle-system"
  create_namespace = true
  wait             = true

  set {
    name  = "hostname"
    value = "rancher.${var.dns_domain}"
  }
  set {
    name = "letsEncrypt.ingress.class"
    value = "${var.ingress_class_name}"
  }
  set {
    name  = "bootstrapPassword"
    value = "${random_password.rancher_admin_password.result}"
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
    name = "bootstrapPassword"
    value = "${random_password.rancher_admin_password.result}"
  }

depends_on = [random_password.rancher_admin_password]

}

// output rancher url
output "rancher_url" {
  value = "https://rancher.${var.dns_domain}"
}

// output rancher admin password
output "rancher_admin_password" {
  value = random_password.rancher_admin_password.result
}

// output helm repo url and name
output "helm_repo_url" {
  value = helm_release.rancher.repository
}

output "helm_repo_name" {
  value = helm_release.rancher.name
}
