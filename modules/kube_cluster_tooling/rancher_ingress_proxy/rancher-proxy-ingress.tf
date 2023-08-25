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

//ingress
resource "kubectl_manifest" "ingress" {

    yaml_body = local.ingress_config
}

locals {
    ingress_config = <<-EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${var.ingress_display_name}
  namespace: "cattle-system"
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-production
    traefik.ingress.kubernetes.io/rewrite-target: "0"
spec:
    ingressClassName: ${var.ingress_class_name}
    rules:
    - host: rancher.${var.dns_domain}
      http:
        paths:
        - path: "/api/v1/namespaces/${var.namespace}/services/${var.protocol}:${var.service_name}:${var.service_port}/proxy/"
          pathType: Prefix
          backend:
            service:
              name: rancher
              port:
                number: 80
    tls:
    - hosts:
      - rancher.${var.dns_domain}
      secretName: ${var.tls_secret_name}
EOF
}



variable "protocol" {
  type    = string
  default = "http"
}

variable "service_name" {
  type    = string
  default = "rancher"
}

variable "service_port" {
  type    = number
  default = 80
}

variable "namespace" {
  type    = string
  default = "cattle-system"
}

variable "dns_domain" {
  type    = string
  default = "sslip.io"
}

variable "ingress_class_name" {
  type    = string
  default = "traefik"
}

variable "ingress_display_name" {
  type    = string
  default = "rancher"
}

variable "tls_secret_name" {
  type    = string
  default = "tls-rancher-cert"
}