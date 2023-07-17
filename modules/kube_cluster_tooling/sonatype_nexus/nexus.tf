##########################################################################################

// Create random password for postgresql
resource "random_password" "postgresql_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

// export the password to a file
resource "local_sensitive_file" "postgresql_password" {
  content  = random_password.postgresql_password.result
  filename = "${var.outputs_path}/postgresql-password.txt"
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


//license secret
resource "kubernetes_secret" "iq_server_license_secret" {
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
  metadata {
    name      = "nxrm-db-secret"
    namespace = "nexus"
  }
  depends_on = [helm_release.nxrm]
  data = {
    username = var.environment == "development" ? var.postgresql_username : var.prod_db_username
    password = var.environment == "development" ? random_password.postgresql_password.result : var.prod_db_password
  }
}

