##################################################################################
## Sonatype Nexus ##
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

variable "environment" {
  description = "The deployment environment (development or production)."
  type        = string
}

variable "nxrm_version" {
  description = "The version of the Sonatype Nexus to be deployed."
  type        = string
}

variable "nexus_license_file" {
  description = "The path to the Sonatype Nexus license file."
  type        = string
}

variable "db_name" {
  description = "The name of the database to be created."
  type        = string
}

variable "postgresql_version" {
  description = "The version of the PostgreSQL to be deployed."
  type        = string
}

variable "postgresql_username" {
  description = "The username for the PostgreSQL."
  type        = string
}

variable "outputs_path" {
  description = "The path to the outputs folder."
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

// Prod Values
variable "prod_db_host" {
  description = "The host of the external database for the production environment."
  type        = string
  default     = ""
}

variable "prod_db_username" {
  description = "The username for the external database for the production environment."
  type        = string
  default     = ""
}

variable "prod_db_password" {
  description = "The password for the external database for the production environment."
  type        = string
  sensitive   = true
  default     = ""
}

variable "prod_db_name" {
  description = "The name of the external database for the production environment."
  type        = string
  default     = ""
}

// Create random password for postgresql
resource "random_password" "postgresql_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

// export the password to a file
resource "local_file" "postgresql_password" {
  sensitive_content = random_password.postgresql_password.result
  filename          = "${var.outputs_path}/postgresql-password.txt"
}

// Dev Database Container
resource "helm_release" "postgresql" {
  count = var.environment == "development" ? 1 : 0

  name       = "postgresql"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = var.postgresql_version

  namespace        = "nexus"
  create_namespace = true

  set {
    name  = "postgresqlUsername"
    value = var.postgresql_username
  }

  set {
    name  = "postgresqlPassword"
    value = random_password.postgresql_password.result
  }

  set {
    name  = "postgresqlDatabase"
    value = var.db_name
  }
}

// Postgresql Service Internal URL
data "kubernetes_service" "nexus-postgresql" {
  count = var.environment == "development" ? 1 : 0

  metadata {
    name      = "postgresql"
    namespace = "nexus"
  }

  depends_on = [helm_release.postgresql]
}

locals {
  nexus_license_base64 = filebase64(var.nexus_license_file)
}

// Nexus
resource "helm_release" "nxrm" {
  name       = "nxrm"
  repository = "https://sonatype.github.io/helm3-charts"
  chart      = "nexus-repository-manager"
  version    = var.nxrm_version

  namespace        = "nexus"
  create_namespace = true

  values = [local.nxrm_values]

  set {
    name  = "nexus.datastore.nexus.jdbcUrl"
    value = "jdbc:postgresql://${var.environment == "development" ? "${helm_release.postgresql[0].name}-postgresql" : var.prod_db_host}:5432/${var.environment == "development" ? var.db_name : var.prod_db_name}"
  }

}

//nxrm_values
locals {
  nxrm_values = <<-YAML

env:
  # minimum recommended memory settings for a small, person instance from
  # https://help.sonatype.com/repomanager3/product-information/system-requirements
  - name: INSTALL4J_ADD_VM_PARAMS
    value: |-
      ${var.environment == "development" ? "-Xms2703M -Xmx2703M -XX:+UnlockExperimentalVMOptions -XX:ActiveProcessorCount=4 -XX:+UseCGroupMemoryLimitForHeap" : ""}
      -Djava.util.prefs.userRoot=/nexus-data/javaprefs
      -Dnexus.licenseFile=/etc/nexus-license/license.lic
      -Dnexus.datastore.enabled=true
      -Dnexus.datastore.nexus.username=${var.environment == "development" ? var.postgresql_username : var.prod_db_username}
      -Dnexus.datastore.nexus.password=${var.environment == "development" ? random_password.postgresql_password.result : var.prod_db_password}
  - name: NEXUS_SECURITY_RANDOMPASSWORD
    value: "true"
ingress:
  enabled: true
  ingressClassName: ${var.ingress_class_name}
  annotations:
    traefik.ingress.kubernetes.io/router.tls.certresolver: letsencrypt-production
    traefik.ingress.kubernetes.io/rewrite-target: "0"
  hostPath: /
  hostRepo: "nexus.${var.dns_domain}"
  tls:
  - hosts:
    - "nexus.${var.dns_domain}"
    secretName: "tls-nexus-cert"
namespaces:
  nexusNs: nxrm
secret:
  enabled: true
  mountPath: /etc/nexus-license/
  data:
    license.lic: ${local.nexus_license_base64}
service:
  nexus:
    type: ClusterIP
statefulset.container.env.nexusDBPort: 5432
YAML
}


output "postgresql_service_name" {
  value = var.environment == "development" ? helm_release.postgresql[0].name : ""
}

