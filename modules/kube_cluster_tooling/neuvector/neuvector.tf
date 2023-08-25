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
    enabled: ${var.rancher_installed ? false : true}
    ingressClassName: ${var.ingress_class_name}
    host: "neuvector.${var.dns_domain}"
    annotations:
      cert-manager.io/cluster-issuer: ${var.tls_cluster_issuer_name}
      ${var.ingress_class_name}.ingress.kubernetes.io/backend-protocol: "HTTPS"
    tls: true
    secretName: neuvector-tls-secret
  env:
    ssl: ${var.rancher_installed ? true : false}
k3s:
  enabled: ${var.k3s_enabled ? true : false}
containerd:
  enabled: ${var.containerd_enabled ? true : false}
docker:
  enabled: ${var.docker_enabled ? true : false}
crio:
  enabled: ${var.crio_enabled ? true : false}
    EOT
  ]
}


variable "neuvector_chart_version" {
  default = "2.6.1"
  type = string
  description = "value to set neuvector chart version"
}

variable "k3s_enabled" {
  default = false
  type = bool
  description = "value to enable k3s runtime"
}

variable "rancher_installed" {
  default = false
  type = bool
  description = "if true, sets ingress to false and enables rancher sso"
}

variable "cluster_name" {
  default = "neuvector"
  type = string
  description = "value to set cluster name"
}

variable "dns_domain" {
  default = "example.com"
  type = string
  description = "value to set dns domain"
}

variable "file_output_directory" {
  default = "/tmp"
  type = string
  description = "value to set file output directory"
}

variable "tls_cluster_issuer_name" {
  default = "letsencrypt-production"
  type = string
  description = "value to set cluster issuer name"
}

variable "ingress_class_name" {
  default = "traefik"
  type = string
  description = "value to set ingress class name"
}

variable "docker_enabled" {
  default = false
  type = bool
  description = "value to enable docker runtime"
}

variable "containerd_enabled" {
  default = false
  type = bool
  description = "value to enable containerd runtime"
}

variable "crio_enabled" {
  default = false
  type = bool
  description = "value to enable crio runtime"
}

// output helm repo url and name
output "helm_repo_url" {
  value = helm_release.neuvector.repository
}

output "helm_repo_name" {
  value = helm_release.neuvector.name
}