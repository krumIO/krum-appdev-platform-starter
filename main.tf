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


provider "kubernetes" {
  config_path = "./artifacts/output_files/kubeconfig.yaml"
  insecure = false
}

provider "helm" {
  kubernetes {
    config_path = "./artifacts/output_files/kubeconfig.yaml"
    insecure = false
  }
}

provider "kubectl" {
  config_path = "./artifacts/output_files/kubeconfig.yaml"
}

#############################################################
// Cluster Tooling

// Loadbalancer Ingress Controller, Cert Manager
module "kube_loadbalancer" {
  source           = "./modules/kube_cluster_tooling/loadbalancer_resources"
  kube_config_file = var.kube_config_file

  // Email for letsencrypt. Supplied in terraform.tfvars
  email = var.email
  // Chart versions
  traefik_version = "23.1.0"

}

// Rancher
module "rancher" {
  source           = "./modules/kube_cluster_tooling/rancher"
  kube_config_file = var.kube_config_file

  // Chart versions
  rancher_version = "2.7.5"
  // Ingress details
  email              = var.email
  dns_domain         = join(".", [module.kube_loadbalancer.load_balancer_ip, "sslip.io"])
  ingress_class_name = "traefik"
  // Rancher admin password
  file_output_directory = "./artifacts/output_files" // This is where the random password will be stored. No need to change this for workshop.

  depends_on = [module.kube_loadbalancer,
  ]
}

// Argo suite
module "argo" {
  source           = "./modules/kube_cluster_tooling/argo"
  kube_config_file = var.kube_config_file


  // chart versions
  argo_cd_version        = "5.38.0"
  argo_workflows_version = "0.30.0"
  argo_events_version    = "2.4.0"
  // ingress details
  email              = var.email
  dns_domain         = join(".", [module.kube_loadbalancer.load_balancer_ip, "sslip.io"])
  ingress_class_name = "traefik"

  depends_on = [module.kube_loadbalancer,
  ]
}

// Workflows Ingress Proxied
module "argo_workflows_ingress_proxied" {
  source = "./modules/kube_cluster_tooling/rancher_ingress_proxy"

  ingress_display_name = "argo-workflows"
  protocol             = "http"
  service_name         = "argo-workflows-server"
  service_port         = 2746
  namespace            = "argocd"
  dns_domain           = join(".", [module.kube_loadbalancer.load_balancer_ip, "sslip.io"])
  ingress_class_name   = "traefik"

  depends_on = [module.kube_loadbalancer,
    module.rancher,
    module.argo,
  ]
}