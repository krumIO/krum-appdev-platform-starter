## Providers ##
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

variable "email" {
  description = "Email address used for certificate issuers and certificate resolvers"
  type        = string
}

variable "traefik_chart_version" {
  description = "Version of Traefik Helm chart to be deployed"
  type        = string
}

variable "traefik_dashboard_password" {
  description = "Password for accessing Traefik dashboard"
  type        = string
  sensitive   = true
  default     = ""
}

variable "kube_config_file" {
  description = "Path to kubeconfig file"
  type        = string
}

variable "ingress_class_name" {
  description = "The Ingress Class Name."
  type        = string
  default    = "traefik"
}

variable "cert_manager_chart_version" {
  description = "Version of cert-manager Helm chart to be deployed"
  type        = string
}

variable "module_enabled" {
  description = "Enable module"
  type        = bool
  default     = true
}

##############################################
## Cert Manager ##
resource "helm_release" "cert-manager" {
  count     = var.module_enabled ? 1 : 0
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_chart_version

  namespace        = "cert-manager"
  create_namespace = true
  wait             = true

  set {
    name  = "installCRDs"
    value = "true"
  }

}

##############################################
## Lets encrypt staging and production issuers
resource "kubectl_manifest" "cluster-issuer-letsencrypt-staging" {
  count     = var.module_enabled ? 1 : 0
  provider   = kubectl
  yaml_body  = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: ${var.email}
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: ${var.ingress_class_name}
YAML
  depends_on = [helm_release.cert-manager]
}

resource "kubectl_manifest" "cluster-issuer-letsencrypt-production" {
  count     = var.module_enabled ? 1 : 0
  provider   = kubectl
  yaml_body  = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-production
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ${var.email}
    privateKeySecretRef:
      name: letsencrypt-production
    solvers:
    - http01:
        ingress:
          class: ${var.ingress_class_name}
YAML
  depends_on = [helm_release.cert-manager]
}

##############################################
## Traefik ##
resource "helm_release" "traefik_ingress_controller" {
  count     = var.module_enabled ? 1 : 0
  name             = "traefik"
  repository       = "https://helm.traefik.io/traefik"
  chart            = "traefik"
  version          = var.traefik_chart_version
  namespace        = "traefik"
  create_namespace = true


  values = [
    <<EOF
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"
  dashboard:
    address: ":8080"
ports:
  web:
    redirectTo:
      port: websecure
providers:
  kubernetesCRD:
    enabled: true
    namespaces: []
  kubernetesIngress:
    enabled: true
    namespaces: []
    publishedService:
      enabled: true
persistence:
  enabled: true
  path: /data
  size: 1Gi
  accessMode: ReadWriteMany
  storageClass: longhorn
ingressRoute:
  dashboard:
    entryPoints:
      - websecure
    kind: Rule
    services:
      - name: api@internal
        kind: TraefikService
    # middlewares:
    #   - name: basic-auth
  # middlewares:
  # - name: basic-auth
  #   basicAuth:
  #     users:
  #     - "admin:"



#     tls:
#       certResolver: letsencrypt-production
additionalArguments:
  - "--api.insecure=true"
  - "--api.dashboard=true"
  - "--providers.kubernetesingress"
  - "--providers.kubernetesingress.ingressclass=traefik"
  - "--providers.kubernetescrd"
  - "--certificatesresolvers.letsencrypt-staging.acme.email=${var.email}"
  - "--certificatesresolvers.letsencrypt-staging.acme.storage=/data/acme.json"
  - "--certificatesresolvers.letsencrypt-staging.acme.tlschallenge=true"
  - "--certificatesresolvers.letsencrypt-staging.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory"
  - "--certificatesresolvers.letsencrypt-production.acme.email=${var.email}"
  - "--certificatesresolvers.letsencrypt-production.acme.storage=/data/acme.json"
  - "--certificatesresolvers.letsencrypt-production.acme.tlschallenge=true"
  - "--certificatesresolvers.letsencrypt-production.acme.caserver=https://acme-v02.api.letsencrypt.org/directory"
  - "--serversTransport.insecureSkipVerify=true"
EOF
  ]


  depends_on = [
    helm_release.cert-manager,
    kubectl_manifest.cluster-issuer-letsencrypt-staging,
    kubectl_manifest.cluster-issuer-letsencrypt-production,
  ]

}

data "kubernetes_service" "traefik" {
  count = var.module_enabled ? 1 : 0
  metadata {
    name      = "traefik"
    namespace = "traefik"
  }
  depends_on = [helm_release.traefik_ingress_controller]
}


resource "kubectl_manifest" "rbac_cluster_role" {
  count    = var.module_enabled ? 1 : 0
  provider   = kubectl
  yaml_body  = <<YAML
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: traefik-role

rules:
  - apiGroups:
      - ""
    resources:
      - services
      - endpoints
      - secrets
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
      - networking.k8s.io
    resources:
      - ingresses
      - ingressclasses
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
      - networking.k8s.io
    resources:
      - ingresses/status
    verbs:
      - update
YAML
  depends_on = [helm_release.traefik_ingress_controller]
}


resource "kubectl_manifest" "rbac_cluster_role_binding" {
  count   = var.module_enabled ? 1 : 0
  provider   = kubectl
  yaml_body  = <<YAML

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: traefik
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: traefik
subjects:
- kind: ServiceAccount
  name: traefik
  namespace: traefik
YAML
  depends_on = [helm_release.traefik_ingress_controller]
}


output "load_balancer_ip" {
  value = var.module_enabled ? data.kubernetes_service.traefik[0].status[0].load_balancer[0].ingress[0].ip : null
}


// output helm repo url and name
output "helm_repo_url_traefik" {
  value = var.module_enabled ? helm_release.traefik_ingress_controller[0].repository : null
}

output "helm_repo_name_traefik" {
  value = var.module_enabled ? helm_release.traefik_ingress_controller[0].name : null
}

output "helm_repo_url_cert_manager" {
  value = var.module_enabled ? helm_release.cert-manager[0].repository : null
}

output "helm_repo_name_cert_manager" {
  value = var.module_enabled ? helm_release.cert-manager[0].name : null
}

output "module_enabled" {
  value = var.module_enabled
}