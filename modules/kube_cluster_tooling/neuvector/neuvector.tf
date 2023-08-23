// Create random password for neuvector admin user
resource "random_password" "neuvector_admin_password" {
  length           = 16
  special          = false
  override_special = "_%@"
}

// Output random password for neuvector admin and neuvector url to a file
resource "local_file" "neuvector_admin_password_and_url" {
  content = <<EOT
neuvector_admin_password = "${random_password.neuvector_admin_password.result}"
neuvector_url = "https://neuvector.${var.dns_domain}"
EOT
  filename          = "${var.file_output_directory}/neuvector-admin-password-and-url.txt"
}


resource "helm_release" "neuvector" {

  name             = "neuvector"
  chart            = "https://neuvector.github.io/neuvector-helm/core-${var.neuvector_chart_version}.tgz"
  namespace        = "cattle-neuvector-system"
  create_namespace = true
  wait             = true

  values = [
    <<EOT
%{if var.rancher_installed}
global:
  cattle:
    url: "https://rancher.${var.dns_domain}/"
%{endif}
controller:
  replicas: 1
  apisvc:
    type: ClusterIP
%{if var.rancher_installed}
  ranchersso:
    enabled: true
%{endif}
  secret:
    enabled: true
    data:
      sysinitcfg.yaml:
        Cluster_Name: ${var.cluster_name}
      userinitcfg.yaml:
        users:
        - Fullname: admin
          Username: admin
          Role: admin
          Password: ${random_password.neuvector_admin_password.result}
pvc:
  enabled: true
  capacity: 10Gi
cve:
  scanner:
    replicas: 1
manager:
  ingress:
    enabled: ${var.ingress_enabled}
    ingressClassName: ${var.ingress_class_name}
    host: "neuvector.${var.dns_domain}"
    annotations:
      cert-manager.io/cluster-issuer: ${var.tls_cluster_issuer_name}
      nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    tls: true
    secretName: neuvector-tls-secret

k3s:
  enabled: ${var.k3s_enabled}
    EOT
  ]
}


variable "neuvector_chart_version" {
  default = "1.0.0"
}

variable "k3s_enabled" {
  default = false
}

variable "ingress_enabled" {
  default = true
}

variable "rancher_installed" {
  default = false
}

variable "cluster_name" {
  default = "neuvector"
}

variable "dns_domain" {
  default = "example.com"
}

variable "file_output_directory" {
  default = "/tmp"
}

variable "tls_cluster_issuer_name" {
  default = "letsencrypt-production"
}

variable "ingress_class_name" {
  default = "traefik"
}