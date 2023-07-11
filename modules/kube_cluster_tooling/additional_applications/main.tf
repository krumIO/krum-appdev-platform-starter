## Providers ##
terraform {
  required_providers {
    civo = {
      source  = "civo/civo"
      version = "1.0.34"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.20.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.9.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.13.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "1.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}

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

variable "rancher_server_admin_password" {
  description = "The password for the Rancher server admin."
  type        = string
}

variable "argo_cd_version" {
  description = "The version of the Argo CD to be deployed."
  type        = string
}

variable "email" {
  description = "The email for letsencrypt setup."
  type        = string
}

# Uncomment this if you want to deploy argo workflows
variable "argo_workflows_version" {
  description = "The version of the Argo Workflows to be deployed."
  type        = string
}

variable "argo_events_version" {
  description = "The version of the Argo Events to be deployed."
  type        = string
}

variable "kube_config_file" {
  description = "Path to kubeconfig file"
  type        = string
}


# ##############################################
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
    name  = "ingress.ingressClassName"
    value = var.ingress_class_name
  }
  set {
    name  = "ingress.tls.source"
    value = "cert-manager"
  }
  set {
    name  = "ingress.tls.certManager.issuerName"
    value = "letsencrypt-production"
  }
  set {
    name  = "ingress.tls.secretName"
    value = "tls-rancher-cert"
  }
  set {
    name  = "ingress.tls.hosts"
    value = "rancher.${var.dns_domain}"
  }
  set {
    name  = "ingress.annotations.cert-manager\\.io/cluster-issuer"
    value = "letsencrypt-production"
  }
  set {
    name  = "bootstrapPassword"
    value = var.rancher_server_admin_password
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


}

##############################################
## ArgoCD ##



resource "helm_release" "argo_cd" {
  name       = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argo_cd_version

  namespace        = "argocd"
  create_namespace = true

  values = [<<EOF
configs:
  cm:
    data:
      rbac.defaultPolicy: role:admin
      rbac.policy.csv: |
        p, role:admin, applications, *, */*
        g, admin, role:admin
    exec.enabled: false
    url: "https://argocd.${var.dns_domain}"
  params:
    server.insecure: true

server:
  certificate:
    domain: "argocd.${var.dns_domain}"
  resources:
    limits:
      cpu: 1000m
      memory: 2Gi
    requests:
      cpu: 1000m
      memory: 1Gi
  ingress:
    enabled: true
    hosts:
      - argocd.${var.dns_domain}
    servicePort: 80
    annotations:
      traefik.ingress.kubernetes.io/router.tls.certresolver: letsencrypt-production
      kubernetes.io/ssl-passthrough: "true"
    tls:
      - hosts:
        - argocd.${var.dns_domain}
        secretName: "argocd-secret"
EOF
  ]


}

// argo-workflows
resource "helm_release" "argo_workflows" {
  name       = "argo-workflows"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-workflows"
  version    = var.argo_workflows_version

  namespace        = "argocd"
  create_namespace = false

  values = [local.argo_workflows_values]

  depends_on = [
    helm_release.argo_cd,
  ]
}

locals {
  argo_workflows_values = <<YAML
server:
  extraArgs:
  - --auth-mode=server
  ingress:
    annotations:
      traefik.ingress.kubernetes.io/router.tls.certresolver: letsencrypt-production
      kubernetes.io/ssl-passthrough: "true"
    enabled: true
    hosts:
    - argo-workflows.${var.dns_domain}
    servicePort: 80
    tls:
    - hosts:
      - argo-workflows.${var.dns_domain}
      secretName: "tls-argo-workflows-cert"
YAML
}

// argo-events
resource "helm_release" "argo_events" {
  name       = "argo-events"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-events"
  version    = var.argo_events_version

  namespace        = "argocd"
  create_namespace = false

  set {
    name  = "crds.install"
    value = "true"
  }

  # values = [local.argo_events_values]

  depends_on = [
    helm_release.argo_cd,
  ]

}



##################################################################################
