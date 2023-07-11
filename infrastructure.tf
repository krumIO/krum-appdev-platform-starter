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



provider "civo" {
  # Configuration options
  token  = var.civo_token
  region = var.civo_region
}

provider "kubernetes" {
  config_path = "./artifacts/output_files/kubeconfig.yaml"
}

provider "helm" {
  kubernetes {
    config_path = "./artifacts/output_files/kubeconfig.yaml"
  }
}

provider "kubectl" {
  config_path = "./artifacts/output_files/kubeconfig.yaml"
}

resource "random_id" "suffix" {
  byte_length = 4
}

#############################################################
## Kubernetes ##
module "civo_sandbox_cluster" {
  source = "./modules/civo_kubernetes"

  cluster_name            = "civo-sandbox-${random_id.suffix.hex}"
  cluster_type            = "k3s"
  kube_config_output_path = "./artifacts/output_files/kubeconfig.yaml"
  firewall_name           = "civo-sandbox-firewall-${random_id.suffix.hex}"
  network_id              = module.civo_sandbox_cluster_network.network_id
  node_pool_name          = "sandbox-pool-${random_id.suffix.hex}"
  node_count              = 3
  node_size               = "g4s.kube.medium"
  applications            = null

  depends_on = [module.civo_sandbox_cluster_network]
}

module "civo_sandbox_cluster_network" {
  source       = "./modules/civo_network"
  network_name = "civo_sandbox_cluster-network"
}

# output "kubeconfig" {
#   description = "Kubeconfig for the created cluster"
#   value       = module.civo_sandbox_cluster.kubeconfig
#   sensitive   = true
# }

# resource "local_file" "civo_sandbox_cluster-kubeconfig" {
#   filename          = "./artifacts/output_files/kubeconfig.yaml"
#   sensitive_content = module.civo_sandbox_cluster.kubeconfig


#   depends_on = [module.civo_sandbox_cluster]
# }

#############################################################
// Out of Cluster Resources

// Generate a random password for rancher admin user auth and traefik dashboard basic-auth
resource "random_password" "rancher_admin_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "local_file" "rancher_admin_password_and_url" {
  sensitive_content = "Admin Password: ${random_password.rancher_admin_password.result}\nRancher Server URL: ${join(".", ["rancher", module.kube_loadbalancer.load_balancer_ip, "sslip.io"])}"
  filename          = "./artifacts/output_files/rancher-admin-password-and-url.txt"
}


resource "random_password" "traefik_dashboard_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "local_file" "traefik_dashboard_password" {
  sensitive_content = random_password.traefik_dashboard_password.result
  filename          = "./artifacts/output_files/traefik-dashboard-password.txt"
}

// Cluster Tooling
module "kube_loadbalancer" {
  source           = "./modules/kube_cluster_tooling/loadbalancer_resources"
  kube_config_file = var.kube_config_file

  email                      = var.email
  traefik_version            = "23.1.0"
  traefik_dashboard_password = random_password.traefik_dashboard_password.result

  depends_on = [module.civo_sandbox_cluster,
  ]
}

module "additional_applications" {
  source           = "./modules/kube_cluster_tooling/additional_applications"
  kube_config_file = var.kube_config_file

  email                         = var.email
  rancher_version               = "2.7.5"
  argo_cd_version               = "5.38.0"
  argo_workflows_version        = "0.30.0"
  argo_events_version           = "2.4.0"
  dns_domain                    = join(".", [module.kube_loadbalancer.load_balancer_ip, "sslip.io"])
  rancher_server_admin_password = random_password.rancher_admin_password.result
  ingress_class_name            = "traefik"

  depends_on = [module.kube_loadbalancer,
  ]
}

###########################################################
## Database ##


# module "nxrm_database" {
#   source = "./modules/civo_db"

#   db_name               = var.db_name
#   region                = var.civo_v2.10.1region
#   node_count            = var.db_node_count
#   db_network_id         = module.civo_sandbox_cluster-network.network_id
#   firewall_ingress_cidr = var.db_firewall_ingress_cidr
# }

# locals {
#   db_username    = "civo" # Change this to "root" if you're using MySQL
#   db_credentials = "username: ${local.db_username}\npassword: ${module.nxrm_database.database_password}"
# }

# resource "local_file" "database_credentials" {
#   sensitive_content = local.db_credentials
#   filename          = "./artifacts/output_files/database-credentials.txt"
# }
###########################################################
