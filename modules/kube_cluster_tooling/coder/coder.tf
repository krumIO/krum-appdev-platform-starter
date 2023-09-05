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

resource "kubernetes_namespace" "coder_development_env" {
  count = var.coder_enabled ? 1 : 0
  metadata {
    name = "coder-development-environments"
  }
}

// Create random password for postgresql
resource "random_password" "postgresql_password" {
  count            = var.coder_enabled && var.environment == "development" ? 1 : 0
  length           = 16
  special          = true
  override_special = "_%@"
}

// export the password to a file
resource "local_sensitive_file" "postgresql_password" {
  count    = var.coder_enabled && var.environment == "development" ? 1 : 0
  content  = random_password.postgresql_password[0].result
  filename = "${var.file_output_directory}/coder-postgresql-password.txt"
}

// Dev Database Container
resource "helm_release" "postgresql" {
  count = var.coder_enabled && var.environment == "development" ? 1 : 0

  name       = "coder-db-postgresql"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = var.postgresql_version

  namespace        = "coder"
  create_namespace = true

  set {
    name  = "auth.username"
    value = "coder"
  }

  set {
    name  = "auth.password"
    value = random_password.postgresql_password[0].result
  }

  set {
    name  = "auth.database"
    value = "coder"
  }
  depends_on = [ kubernetes_namespace.coder_development_env, random_password.postgresql_password ]
}

// Postgresql Service Internal URL
data "kubernetes_service" "coder-postgresql" {
  count = var.coder_enabled && var.environment == "development" ? 1 : 0

  metadata {
    name      = "postgresql"
    namespace = "coder"
  }

  depends_on = [helm_release.postgresql]
}

resource "kubectl_manifest" "coder-db-url" {
  count    = var.coder_enabled && var.environment == "development" ? 1 : 0
  provider = kubectl

  yaml_body = <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: coder-db-url
  namespace: coder
type: Opaque
stringData:
  url: "postgres://coder:${random_password.postgresql_password[0].result}@${helm_release.postgresql[0].name}/coder?sslmode=disable"
YAML
  
    depends_on = [helm_release.postgresql, random_password.postgresql_password]
}

resource "helm_release" "coder" {
  count = var.coder_enabled ? 1 : 0
  name             = "coder"
  repository       = "https://helm.coder.com/v2"
  chart            = "coder"
  version          = var.coder_chart_version
  namespace        = "coder"
  create_namespace = true
  wait             = true

  values = [
    <<EOT
coder:
  env:
    - name: CODER_PG_CONNECTION_URL
      valueFrom:
        secretKeyRef:
          name: coder-db-url
          key: url
    - name: CODER_ACCESS_URL
      value: "https://coder.212.2.247.221.sslip.io"
  
  service:
    enabled: true
    type: ClusterIP
    port: 80

  serviceAccount:
    enableDeployments: true

  # tls:
  #   # coder.tls.secretNames -- A list of TLS server certificate secrets to mount
  #   # into the Coder pod. The secrets should exist in the same namespace as the
  #   # Helm deployment and should be of type "kubernetes.io/tls". The secrets
  #   # will be automatically mounted into the pod if specified, and the correct
  #   # "CODER_TLS_*" environment variables will be set for you.
  #   secretNames: ["coder-tls-cert"]
  
#   ingress:
#     enable: false
#     ingressClassName: "traefik"
#     host: "coder.${var.dns_domain}"
#     port: 80
#     annotations: 
#       cert-manager.io/cluster-issuer: "letsencrypt-production"
#     tls:
#       enable: true
#       secretName: "coder-tls-cert"


EOT
  ]

  depends_on = [
    helm_release.postgresql,
    kubectl_manifest.coder-db-url,
    kubernetes_namespace.coder_development_env,
  ]
}

resource "kubectl_manifest" "coder-ingress" {
  count = var.coder_enabled ? 1 : 0
  provider = kubectl

  yaml_body = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: coder
  namespace: coder
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-production"
spec:
  rules:
  - host: "coder.${var.dns_domain}"
    http:
      paths:
      - path: /
        pathType: ImplementationSpecific
        backend:
          service:
            name: coder
            port:
              number: 80
  ingressClassName: "traefik"
  tls:
  - hosts:
    - "coder.${var.dns_domain}"
    secretName: coder-tls-cert
YAML
  
    depends_on = [helm_release.coder]
}

resource "kubectl_manifest" "coder-service-account" {
  count = var.coder_enabled ? 1 : 0
  provider  = kubectl
  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: coder
YAML
  depends_on = [kubernetes_namespace.coder_development_env]
}

resource "kubectl_manifest" "coder-role-binding" {
  count = var.coder_enabled ? 1 : 0
  provider  = kubectl
  yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: coder
subjects:
  - kind: ServiceAccount
    name: coder
roleRef:
  kind: Role
  name: coder
  apiGroup: rbac.authorization.k8s.io
YAML
  
    depends_on = [kubernetes_namespace.coder_development_env, kubectl_manifest.coder-role]
}

resource "kubectl_manifest" "coder-role" {
  count = var.coder_enabled ? 1 : 0
  provider  = kubectl
  yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: coder
rules:
- apiGroups: [""]
  resources: ["pods"]  
  verbs: ["get", "list", "watch"] 
- apiGroups: [""]
  resources: ["persistentvolumeclaims"]
  verbs: ["get", "list", "watch", "create", "delete"]
YAML
    
      depends_on = [kubernetes_namespace.coder_development_env]
}

resource "kubectl_manifest" "coder-pvc-manager-role" {
  count = var.coder_enabled ? 1 : 0
  provider  = kubectl
  yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pvc-manager
  namespace: coder-development-environments
rules:
- apiGroups: [""]
  resources: ["pods"]  
  verbs: ["get", "list", "watch"] 
- apiGroups: [""]
  resources: ["persistentvolumeclaims"]
  verbs: ["get", "list", "watch", "create", "delete"]
YAML

  depends_on = [kubernetes_namespace.coder_development_env]
}

resource "kubectl_manifest" "coder-pvc-manager-role-binding" {
  count = var.coder_enabled ? 1 : 0
  provider  = kubectl
  yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pvc-manager
  namespace: coder-development-environments
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pvc-manager
subjects:
- kind: ServiceAccount
  name: coder
  namespace: coder
YAML

  depends_on = [kubernetes_namespace.coder_development_env, kubectl_manifest.coder-pvc-manager-role]
}

resource "kubernetes_role" "deployment_creator" {
  count = var.coder_enabled ? 1 : 0
  metadata {
    name      = "deployment-creator-role"
    namespace = "coder-development-environments"
  }
  
  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["create", "get", "list", "watch", "update", "patch", "delete"]  # or just ["*"]
  }

  depends_on = [kubernetes_namespace.coder_development_env, kubectl_manifest.coder-pvc-manager-role]
}

resource "kubernetes_role_binding" "deployment_creator_binding" {
  count = var.coder_enabled ? 1 : 0
  metadata {
    name      = "deployment-creator-binding"
    namespace = "coder-development-environments"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind     = "Role"
    name     = kubernetes_role.deployment_creator[count.index].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "coder"
    namespace = "coder"
  }
  depends_on = [kubernetes_namespace.coder_development_env, kubernetes_role.deployment_creator]
}


variable "dns_domain" {
  type    = string
  default = "example.com"
}

variable "coder_chart_version" {
  type    = string
  default = "2.1.0"
}

variable "postgresql_version" {
  type    = string
  default = "12.6.5"
}

variable "environment" {
  type    = string
  default = "development"
}

variable "file_output_directory" {
  type = string
}

variable "ingress_class_name" {
  type    = string
  default = "traefik"
}

variable "coder_enabled" {
  type    = bool
  default = false
}
