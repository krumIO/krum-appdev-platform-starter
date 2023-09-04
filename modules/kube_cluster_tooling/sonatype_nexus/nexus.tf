##########################################################################################

// Create random password for postgresql
resource "random_password" "postgresql_password" {
  count            = var.environment == "development" && var.module_enabled ? 1 : 0
  length           = 16
  special          = true
  override_special = "_%@"
}

// export the password to a file
resource "local_sensitive_file" "postgresql_password" {
  count    = var.environment == "development" && var.module_enabled ? 1 : 0
  content  = random_password.postgresql_password[0].result
  filename = "${var.outputs_path}/nexus-postgresql-password.txt"
}

// Dev Database Container
resource "helm_release" "postgresql" {
  count = var.environment == "development" && var.module_enabled ? 1 : 0

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
    value = random_password.postgresql_password[0].result
  }

  set {
    name  = "postgresqlDatabase"
    value = var.db_name
  }
}

// Postgresql Service Internal URL
data "kubernetes_service" "nexus-postgresql" {
  // count if environment is development and module is enabled
  count = var.environment == "development" && var.module_enabled ? 1 : 0

  metadata {
    name      = "postgresql"
    namespace = "nexus"
  }

  depends_on = [helm_release.postgresql]
}

# locals {
#   nexus_license_base64 = filebase64(var.nexus_license_file)
# }

locals {
  nexus_license_base64 = var.nexus_license_file != null ? filebase64(var.nexus_license_file) : "dummy_license_content"
}

// Nexus
resource "helm_release" "nxrm" {
  count      = var.module_enabled ? 1 : 0
  name       = "nxrm"
  repository = "https://sonatype.github.io/helm3-charts"
  chart      = "nexus-repository-manager"
  version    = var.nxrm_chart_version

  namespace        = "nexus"
  create_namespace = true

  values = [local.nxrm_values]

  set {
    name = "nexus.datastore.nexus.jdbcUrl"
    value = var.environment == "development" ? (
      length(helm_release.postgresql) > 0 ? "jdbc:postgresql://${helm_release.postgresql[0].name}-postgresql:5432/${var.db_name}" : "fallback_for_dev"
      ) : (
      var.prod_db_host != null ? "jdbc:postgresql://${var.prod_db_host}:5432/${var.prod_db_name}" : "fallback_for_prod"
    )
  }

  set {
    name  = "nexus.docker.enabled"
    value = var.nxrm_docker_registry_enabled
  }

  set {
    name  = "nexus.docker.registries[0].host"
    value = "docker.${var.dns_domain}"
  }

  set {
    name  = "nexus.docker.registries[0].port"
    value = "9090"
  }

  set {
    name  = "nexus.docker.registries[0].secretName"
    value = "example-docker-registry"
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
      # ${var.nexus_license_file != null ? "-Dnexus.licenseFile=/etc/nexus-license/license.lic" : ""}
      -Dnexus.datastore.enabled=true
      -Dnexus.datastore.nexus.username=${var.environment != null ? (var.environment == "development" ? (var.postgresql_username != null ? var.postgresql_username : "") : (var.prod_db_username != null ? var.prod_db_username : "")) : ""}
      -Dnexus.datastore.nexus.password=${local.password_value != null ? local.password_value : ""}
  - name: NEXUS_SECURITY_RANDOMPASSWORD
    value: "true"
ingress:
  enabled: true
  ingressClassName: "${var.ingress_class_name != null ? var.ingress_class_name : ""}"
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-production
    traefik.ingress.kubernetes.io/rewrite-target: "0"
  hostPath: /
  hostRepo: "${local.nexus_host_repo}"
  tls:
  - hosts:
    - "${local.nexus_host_value}"
    secretName: "tls-nexus-cert"
namespaces:
  nexusNs: nxrm
secret:
  enabled: ${var.nexus_license_file != null ? "true" : "false"}
  mountPath: /etc/nexus-license/
  data:
    license.lic: ${local.nexus_license_base64}
service:
  nexus:
    type: ClusterIP
statefulset.container.env.nexusDBPort: 5432
YAML
}


resource "kubernetes_secret" "iq_server_license_secret" {
  # count = var.nexus_license_file != null ? 1 : 0
  count = (var.module_enabled && var.nexus_license_file != null) ? 1 : 0


  metadata {
    name      = "iq-server-license-secret"
    namespace = "nexus"
  }
  depends_on = [helm_release.nxrm]
  data = {
    "license_lic" = local.nexus_license_base64
  }
}


//db secret
resource "kubernetes_secret" "nxrm_db_secret" {
  count = var.environment == "development" && var.module_enabled ? 1 : 0
  metadata {
    name      = "nxrm-db-secret"
    namespace = "nexus"
  }
  depends_on = [helm_release.nxrm]
  data = {
    username = var.environment == "development" ? var.postgresql_username : var.prod_db_username
    password = var.environment == "development" ? random_password.postgresql_password[0].result : var.prod_db_password
  }
}

// output helm repo url and name
output "postgresql_service_name" {
  value       = var.module_enabled && var.environment == "development" ? helm_release.postgresql[0].name : ""
  description = "The name of the PostgreSQL service when deployed in a development environment."
}

output "helm_repo_url" {
  value       = var.module_enabled ? helm_release.nxrm[0].repository : ""
  description = "The URL of the Helm repository used for Nexus Repository Manager."
}

output "helm_repo_name" {
  value = var.module_enabled ? helm_release.nxrm[0].name : ""
}
