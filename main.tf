## Providers ##
terraform {
  required_providers {
    civo = {
      source  = "civo/civo"
      version = "1.0.35"
    }
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



provider "civo" {
  # Configuration options
  token  = var.civo_token
  region = var.civo_region
}

provider "kubernetes" {
  # config_path = "./artifacts/output_files/kubeconfig.yaml"
  host                   = module.civo_sandbox_cluster.api_endpoint
  client_certificate     = base64decode(yamldecode(module.civo_sandbox_cluster.kubeconfig).users[0].user.client-certificate-data)
  client_key             = base64decode(yamldecode(module.civo_sandbox_cluster.kubeconfig).users[0].user.client-key-data)
  cluster_ca_certificate = base64decode(yamldecode(module.civo_sandbox_cluster.kubeconfig).clusters[0].cluster.certificate-authority-data)
  insecure = false
}

provider "helm" {
  kubernetes {
    # config_path = "./artifacts/output_files/kubeconfig.yaml"
    host                   = module.civo_sandbox_cluster.api_endpoint
    client_certificate     = base64decode(yamldecode(module.civo_sandbox_cluster.kubeconfig).users[0].user.client-certificate-data)
    client_key             = base64decode(yamldecode(module.civo_sandbox_cluster.kubeconfig).users[0].user.client-key-data)
    cluster_ca_certificate = base64decode(yamldecode(module.civo_sandbox_cluster.kubeconfig).clusters[0].cluster.certificate-authority-data)
    insecure = false
  }
}

provider "kubectl" {
  # config_path = "./artifacts/output_files/kubeconfig.yaml"
  host                   = module.civo_sandbox_cluster.api_endpoint
  client_certificate     = base64decode(yamldecode(module.civo_sandbox_cluster.kubeconfig).users[0].user.client-certificate-data)
  client_key             = base64decode(yamldecode(module.civo_sandbox_cluster.kubeconfig).users[0].user.client-key-data)
  cluster_ca_certificate = base64decode(yamldecode(module.civo_sandbox_cluster.kubeconfig).clusters[0].cluster.certificate-authority-data)
}

// Use a random suffix to ensure the cluster name is unique
resource "random_id" "suffix" {
  byte_length = 4
}

#############################################################
// Civo Infrastructure
module "civo_sandbox_cluster" {
  source = "./modules/civo/civo_kubernetes"

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
  source       = "./modules/civo/civo_network"
  network_name = "civo_sandbox_cluster-network-${random_id.suffix.hex}"
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

  depends_on = [module.civo_sandbox_cluster,
  ]
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

// Sonatype Nexus and IQ Server with PostgreSQL database if required
module "nexus" {
  source = "./modules/kube_cluster_tooling/sonatype_nexus"

  environment = "production"
  // chart version
  nxrm_version      = "58.1.0"
  iq_server_version = "165.0.0"
  // license
  nexus_license_file = var.nexus_license_file_path
  // database details
  db_name             = "nexusdb"
  postgresql_version  = "12.6.5"
  postgresql_username = "nxrm"
  outputs_path        = "./artifacts/output_files"
  // ingress details
  dns_domain         = join(".", [module.kube_loadbalancer.load_balancer_ip, "sslip.io"])
  ingress_class_name = "traefik"

  // Only required for the production environment
  prod_db_host     = module.nxrm_database.dns_endpoint      # existing-db-host
  prod_db_username = "civo"                                 # existing-db-username
  prod_db_password = module.nxrm_database.database_password # existing-db-password
  prod_db_name     = "${var.db_name}-${random_id.suffix.hex}"                              # existing-db-name

  depends_on = [
    module.kube_loadbalancer, //required for both production and development environments
    module.nxrm_database,     // Only required for the production environment  - Comment out if development
  ]
}


##########################################################
// Civo Database Used with Sonatype Nexus in Production Environment
module "nxrm_database" {
  source = "./modules/civo/civo_db"

  db_name               = "${var.db_name}-${random_id.suffix.hex}"
  region                = var.civo_region
  node_count            = var.db_node_count
  db_network_id         = module.civo_sandbox_cluster_network.network_id
  firewall_ingress_cidr = var.db_firewall_ingress_cidr
}

// Local file to store database credentials
locals {
  db_username    = "civo" # Change this to "root" if you're using MySQL
  db_credentials = "username: ${local.db_username}\npassword: ${module.nxrm_database.database_password}"
}

resource "local_sensitive_file" "database_credentials" {
  content  = local.db_credentials
  filename = "./artifacts/output_files/database-credentials.txt"
}

// Create Ingress for QI admin interface
module "iq_admin_ingress_proxied" {
  source = "./modules/kube_cluster_tooling/rancher_ingress_proxy"

  ingress_display_name = "nxiq-admin"
  protocol             = "http"
  service_name         = "nexus-iq-server"
  service_port         = 8071
  namespace            = "nexus"
  dns_domain           = join(".", [module.kube_loadbalancer.load_balancer_ip, "sslip.io"])
  ingress_class_name   = "traefik"

  depends_on = [module.kube_loadbalancer,
    module.rancher,
    module.nexus
  ]
}
# ##########################################################
