// create nexus iq server
resource "helm_release" "iq_server" {
  name       = "nexus-iq-server"
  repository = "https://sonatype.github.io/helm3-charts/"
  chart      = "nexus-iq-server"
  version    = var.iq_server_version

  namespace        = "nexus"
  create_namespace = true

  values = [local.iq_server_config]

  set {
    name  = "iq.licenseSecret"
    value = var.nexus_license_file != null ? local.nexus_license_base64 : "ZHVtbXlfbGljZW5zZV92YWx1ZQo=" # dummy license
  }

  set {
    name  = "iq.hostname"
    value = "nexus-iq.${var.dns_domain}"
  }

  set {
    name  = "iq.applicationPort"
    value = "8070"
  }

  set {
    name  = "iq.adminPort"
    value = "8071"
  }

  set {
    name  = "ingress.hostUI"
    value = "nexus-iq.${var.dns_domain}"
  }

  # set {
  #   name  = "ingress.hostAdmin"
  #   value = ""
  # }

  set {
    name  = "ingress.tls[0].hosts[0]"
    value = "nexus-iq.${var.dns_domain}"
  }

  set {
    name  = "ingress.tls[0].secretName"
    value = "tls-nexus-iq-cert"
  }

  # set {
  #   name  = "ingress.tls[1].hosts[0]"
  #   value = "admin-iq.${var.dns_domain}"
  # }

  # set {
  #   name  = "ingress.tls[1].secretName"
  #   value = "tls-nexus-iq-cert"
  # }

  set {
    name  = "ingress.enabled"
    value = "true"
  }

  set {
    name  = "ingress.ingressClassName"
    value = var.ingress_class_name
  }




  depends_on = [
    helm_release.nxrm,
    kubernetes_secret.nxrm_db_secret
  ]

}

locals {
  iq_server_config = <<-YAML
ingress:
  annotations:
    traefik.ingress.kubernetes.io/router.tls.certresolver: letsencrypt-production
    traefik.ingress.kubernetes.io/rewrite-target: "0"
configYaml:
  baseUrl: "https://nexus-iq.${var.dns_domain}"
  sonatypeWork: /sonatype-work
  ${var.nexus_license_file != null ? "licenseFile: /etc/nexus-iq-license/license_lic" : ""}
  features:
    enableUnauthenticatedPages: true
  server:
    applicationConnectors:
      - type: http
        port: 8070
    adminConnectors:
      - type: http
        port: 8071
    # HTTP request log settings.
    requestLog:
      appenders:
        # All appenders set to console
        - type: file
          currentLogFilename: /var/log/nexus-iq-server/request.log
          # Do not display log statements below this threshold to stdout.
          # threshold: INFO
          logFormat: "%clientHost %l %user [%date] \"%requestURL\" %statusCode %bytesSent %elapsedTime \"%header{User-Agent}\""
          archivedLogFilenamePattern: /var/log/nexus-iq-server/request-%d.log.gz
          archivedFileCount: 50
YAML
}
