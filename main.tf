## Providers ##
terraform {
  required_providers {
    civo = {
      source  = "civo/civo"
      version = "1.0.35"
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

#############################################################

// Cluster Tooling
module "kube_loadbalancer" {
  source           = "./modules/kube_cluster_tooling/loadbalancer_resources"
  kube_config_file = var.kube_config_file

  email           = var.email
  traefik_version = "23.1.0"

  depends_on = [module.civo_sandbox_cluster,
  ]
}

module "rancher" {
  source           = "./modules/kube_cluster_tooling/rancher"
  kube_config_file = var.kube_config_file

  email                 = var.email
  rancher_version       = "2.7.5"
  dns_domain            = join(".", [module.kube_loadbalancer.load_balancer_ip, "sslip.io"])
  ingress_class_name    = "traefik"
  file_output_directory = "./artifacts/output_files" // This is where the random password will be stored

  depends_on = [module.kube_loadbalancer,
  ]
}

module "argo" {
  source           = "./modules/kube_cluster_tooling/argo"
  kube_config_file = var.kube_config_file

  email                  = var.email
  argo_cd_version        = "5.38.0"
  argo_workflows_version = "0.30.0"
  argo_events_version    = "2.4.0"
  dns_domain             = join(".", [module.kube_loadbalancer.load_balancer_ip, "sslip.io"])
  ingress_class_name     = "traefik"

  depends_on = [module.kube_loadbalancer,
  ]
}

module "nexus" {
  source = "./modules/kube_cluster_tooling/sonatype_nexus"

  environment         = "production"
  nxrm_version        = "57.0.0"
  nexus_license_file  = var.nexus_license_file_path
  db_name             = "nexusdb"
  postgresql_version  = "12.6.5"
  postgresql_username = "nxrm"
  outputs_path        = "./artifacts/output_files"
  dns_domain          = join(".", [module.kube_loadbalancer.load_balancer_ip, "sslip.io"])
  ingress_class_name  = "traefik"

  // Only required for the production environment
  prod_db_host     = module.nxrm_database.dns_endpoint      # existing-db-host
  prod_db_username = "civo"                                 # existing-db-username
  prod_db_password = module.nxrm_database.database_password # existing-db-password
  prod_db_name     = "nexusdb"                              # existing-db-name

  depends_on = [
    module.kube_loadbalancer, //required for both production and development environments
    module.nxrm_database,     // Only required for the production environment  - Commend out if development
  ]
}


##########################################################
## Database ##


module "nxrm_database" {
  source = "./modules/civo_db"

  db_name               = var.db_name
  region                = var.civo_region
  node_count            = var.db_node_count
  db_network_id         = module.civo_sandbox_cluster_network.network_id
  firewall_ingress_cidr = var.db_firewall_ingress_cidr
}

locals {
  db_username    = "civo" # Change this to "root" if you're using MySQL
  db_credentials = "username: ${local.db_username}\npassword: ${module.nxrm_database.database_password}"
}

resource "local_file" "database_credentials" {
  sensitive_content = local.db_credentials
  filename          = "./artifacts/output_files/database-credentials.txt"
}
##########################################################
