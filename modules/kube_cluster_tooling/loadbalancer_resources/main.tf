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

variable "email" {
  description = "Email address used for certificate issuers and certificate resolvers"
  type        = string
}

variable "traefik_version" {
  description = "Version of Traefik Helm chart to be deployed"
  type        = string
}

variable "traefik_dashboard_password" {
  description = "Password for accessing Traefik dashboard"
  type        = string
  sensitive   = true
}

variable "kube_config_file" {
  description = "Path to kubeconfig file"
  type        = string
}

##############################################
## Cert Manager ##
resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.12.1"

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
          class: nginx
YAML
  depends_on = [helm_release.cert-manager]
}

resource "kubectl_manifest" "cluster-issuer-letsencrypt-production" {
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
          class: nginx
YAML
  depends_on = [helm_release.cert-manager]
}

##############################################
## Traefik ##
resource "helm_release" "traefik_ingress_controller" {
  name             = "traefik"
  repository       = "https://helm.traefik.io/traefik"
  chart            = "traefik"
  version          = var.traefik_version
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
    redirectTo: websecure
providers:
  kubernetesCRD:
    enabled: true
    namespaces: []
  kubernetesIngress:
    enabled: true
    namespaces: []
    publishedService:
      enabled: true
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
  #     - "admin:${var.traefik_dashboard_password}"



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
  metadata {
    name      = "traefik"
    namespace = "traefik"
  }
  depends_on = [helm_release.traefik_ingress_controller]
}


resource "kubectl_manifest" "rbac_cluster_role" {
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

# resource "kubectl_manifest" "traefik_dashboard_auth_secret" {
#   provider   = kubectl
#   yaml_body  = <<YAML
# apiVersion: v1
# kind: Secret
# metadata:
#   name: traefik-dashboard-auth
#   namespace: traefik
# type: Opaque
# data:
#     users: ${base64encode("admin:${var.traefik_dashboard_password}")}
# YAML
#   depends_on = [helm_release.traefik_ingress_controller]
# }

# resource "kubectl_manifest" "traefik_dashboard_auth_middleware" {
#   provider  = kubectl
#   yaml_body = <<-YAML
# apiVersion: traefik.containo.us/v1alpha1
# kind: Middleware
# metadata:
#   name: basic-auth
#   namespace: traefik
# spec:
#   basicAuth:
#     secret: traefik-dashboard-auth
# YAML

#   depends_on = [
#     helm_release.traefik_ingress_controller,
#     kubectl_manifest.traefik_dashboard_auth_secret,
#   ]
# }


output "load_balancer_ip" {
  value       = data.kubernetes_service.traefik.status[0].load_balancer.0.ingress[0].ip
  description = "The load balancer IP address."
}
