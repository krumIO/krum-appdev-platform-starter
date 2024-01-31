## Providers ##
terraform {
  required_providers {
    civo = {
      source  = "civo/civo"
      version = "1.0.39"
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
  insecure               = false
}

provider "helm" {
  kubernetes {
    # config_path = "./artifacts/output_files/kubeconfig.yaml"
    host                   = module.civo_sandbox_cluster.api_endpoint
    client_certificate     = base64decode(yamldecode(module.civo_sandbox_cluster.kubeconfig).users[0].user.client-certificate-data)
    client_key             = base64decode(yamldecode(module.civo_sandbox_cluster.kubeconfig).users[0].user.client-key-data)
    cluster_ca_certificate = base64decode(yamldecode(module.civo_sandbox_cluster.kubeconfig).clusters[0].cluster.certificate-authority-data)
    insecure               = false
  }
}

provider "kubectl" {
  # config_path = "./artifacts/output_files/kubeconfig.yaml"
  host                   = module.civo_sandbox_cluster.api_endpoint
  client_certificate     = base64decode(yamldecode(module.civo_sandbox_cluster.kubeconfig).users[0].user.client-certificate-data)
  client_key             = base64decode(yamldecode(module.civo_sandbox_cluster.kubeconfig).users[0].user.client-key-data)
  cluster_ca_certificate = base64decode(yamldecode(module.civo_sandbox_cluster.kubeconfig).clusters[0].cluster.certificate-authority-data)
  load_config_file       = false
}

// Use a random suffix to ensure the cluster name is unique
resource "random_id" "suffix" {
  byte_length = 4
}

#############################################################
// Civo Infrastructure
module "civo_sandbox_cluster" {
  source         = "../../modules/civo/civo_kubernetes"
  module_enabled = true

  cluster_name            = "civo-sandbox-${random_id.suffix.hex}"
  cluster_type            = "k3s"
  kube_config_output_path = "./artifacts/output_files/kubeconfig.yaml"
  firewall_name           = "civo-sandbox-firewall-${random_id.suffix.hex}"
  network_id              = module.civo_sandbox_cluster_network.network_id
  node_pool_name          = "sandbox-pool-${random_id.suffix.hex}"
  node_count              = 3
  node_size               = "g4s.kube.large"
  applications            = null

  depends_on = [module.civo_sandbox_cluster_network]
}

module "civo_sandbox_cluster_network" {
  source       = "../../modules/civo/civo_network"
  network_name = "civo_sandbox_cluster-network-${random_id.suffix.hex}"
}

#############################################################
// Cluster Tooling

// Loadbalancer Ingress Controller, Cert Manager
module "kube_loadbalancer" {
  source           = "../../modules/kube_cluster_tooling/loadbalancer_resources"
  kube_config_file = var.kube_config_file
  module_enabled   = var.enable_kube_loadbalancer

  // Email for letsencrypt. Supplied in terraform.tfvars
  email = var.email
  // Chart versions
  traefik_chart_version      = "26.0.0"
  cert_manager_chart_version = "1.13.1"

  depends_on = [module.civo_sandbox_cluster,
  ]
}

// Rancher
module "rancher" {
  source           = "../../modules/kube_cluster_tooling/rancher"
  kube_config_file = var.kube_config_file
  enable_module    = var.enable_rancher

  // Chart versions
  rancher_version = "2.8.1"
  // Ingress details
  email              = var.email
  dns_domain         = module.kube_loadbalancer.module_enabled ? join(".", [module.kube_loadbalancer.load_balancer_ip, "sslip.io"]) : null
  ingress_class_name = "traefik"
  // Rancher admin password
  file_output_directory = var.artifact_output_directory // This is where the random password will be stored. No need to change this for workshop.

  depends_on = [module.kube_loadbalancer,
  ]
}

// Argo suite
module "argo" {
  source           = "../../modules/kube_cluster_tooling/argo"
  kube_config_file = var.kube_config_file
  module_enabled   = var.enable_argo_suite


  // chart versions
  argo_cd_chart_version        = "5.46.8"
  argo_workflows_chart_version = "0.40.9"
  argo_events_chart_version    = "2.4.2"
  // ingress details
  email              = var.email
  dns_domain         = module.kube_loadbalancer.module_enabled ? join(".", [module.kube_loadbalancer.load_balancer_ip, "sslip.io"]) : null
  ingress_class_name = "traefik"

  depends_on = [module.kube_loadbalancer,
  ]
}

// Workflows Ingress Proxied
module "argo_workflows_ingress_proxied" {
  source         = "../../modules/kube_cluster_tooling/rancher_ingress_proxy"
  module_enabled = var.proxy_argo_workflows_via_rancher

  ingress_display_name = "argo-workflows"
  protocol             = "http"
  service_name         = "argo-workflows-server"
  service_port         = 2746
  namespace            = "argocd"
  dns_domain           = module.kube_loadbalancer.module_enabled ? join(".", [module.kube_loadbalancer.load_balancer_ip, "sslip.io"]) : null
  ingress_class_name   = "traefik"

  depends_on = [module.kube_loadbalancer,
    module.rancher,
    module.argo,
  ]
}

// Sonatype Nexus and IQ Server with PostgreSQL database if required
module "nexus" {
  source            = "../../modules/kube_cluster_tooling/sonatype_nexus"
  module_enabled    = var.enable_nexus_rm // if true, nexus helm chart is installed
  iq_server_enabled = var.enable_nexus_iq // if true, iq server helm chart is installed

  environment = "development" // production or development
  // chart version
  nxrm_chart_version      = "58.1.0"
  iq_server_chart_version = "165.0.0"
  // license
  nexus_license_file = var.nexus_license_file_path
  // enable self-hosted docker registry with nxrm
  nxrm_docker_registry_enabled = var.enable_nexus_docker_registry
  // database details
  db_name             = "nexusdb"
  postgresql_version  = "12.6.5"
  postgresql_username = "nxrm"
  outputs_path        = var.artifact_output_directory
  // ingress details
  dns_domain         = module.kube_loadbalancer.module_enabled ? join(".", [module.kube_loadbalancer.load_balancer_ip, "sslip.io"]) : null
  ingress_class_name = "traefik"

  // Only required for the production environment
  prod_db_host     = module.nxrm_database.dns_endpoint        # existing-db-host
  prod_db_username = "civo"                                   # existing-db-username
  prod_db_password = module.nxrm_database.database_password   # existing-db-password
  prod_db_name     = "${var.db_name}-${random_id.suffix.hex}" # existing-db-name

  depends_on = [
    module.kube_loadbalancer, //required for both production and development environments
    module.nxrm_database,     // Only required for the production environment  - Comment out if development
  ]
}


##########################################################
// Civo Database Used with Sonatype Nexus in Production Environment
module "nxrm_database" {
  source         = "../../modules/civo/civo_db"
  module_enabled = var.enable_managed_civo_db // if true, database is created

  db_name               = "${var.db_name}-${random_id.suffix.hex}"
  region                = var.civo_region
  node_count            = var.db_node_count
  db_network_id         = module.civo_sandbox_cluster_network.network_id
  firewall_ingress_cidr = var.db_firewall_ingress_cidr

  depends_on = [module.civo_sandbox_cluster]
}

// Local file to store database credentials
locals {
  # count = module.nxrm_database.module_enabled ? 1 : 0
  db_username    = "civo" # Change this to "root" if you're using MySQL
  db_credentials = module.nxrm_database.module_enabled ? "username: ${local.db_username}\npassword: ${module.nxrm_database.database_password}" : null
}

resource "local_sensitive_file" "database_credentials" {
  count    = module.nxrm_database.module_enabled ? 1 : 0
  content  = local.db_credentials
  filename = "${var.artifact_output_directory}/database-credentials.txt"
}

// Create Ingress for QI admin interface
module "iq_admin_ingress_proxied" {
  source         = "../../modules/kube_cluster_tooling/rancher_ingress_proxy"
  module_enabled = var.proxy_nexus_iq_admin_via_rancher

  ingress_display_name = "nxiq-admin"
  protocol             = "http"
  service_name         = "nexus-iq-server"
  service_port         = 8071
  namespace            = "nexus"
  dns_domain           = module.kube_loadbalancer.module_enabled ? join(".", [module.kube_loadbalancer.load_balancer_ip, "sslip.io"]) : null

  ingress_class_name = "traefik"

  depends_on = [module.kube_loadbalancer,
    module.rancher,
    module.nexus
  ]
}


##########################################################
// Neuvector Helm Install
module "neuvector" {
  source         = "../../modules/kube_cluster_tooling/neuvector"
  module_enabled = var.enable_neuvector // if true, neuvector helm chart is installed

  // Chart versions
  neuvector_chart_version = "2.7.1"

  // Additional Config and Options
  rancher_installed = true // sets ingress to false if rancher is installed and enables rancher sso

  // Set Container Runtime
  k3s_enabled        = true  // sets containerd runtime path for k3s if true
  docker_enabled     = false // sets docker runtime path if true
  containerd_enabled = false // sets containerd runtime path if true
  crio_enabled       = false // sets crio runtime path if true

  cluster_name = module.civo_sandbox_cluster.cluster_name

  // output_files directory
  file_output_directory = var.artifact_output_directory // This is where the random password will be stored. No need to change this for workshop.


  // Ingress details
  // If rancher_installed is true, then the ingress will be disabled and access will be through rancher
  dns_domain              = module.kube_loadbalancer.module_enabled ? join(".", [module.kube_loadbalancer.load_balancer_ip, "sslip.io"]) : null
  ingress_class_name      = "traefik"
  tls_cluster_issuer_name = "letsencrypt-production"

  depends_on = [module.kube_loadbalancer,
    module.rancher,
  ]
}

module "coder" {
  source        = "../../modules/kube_cluster_tooling/coder"
  coder_enabled = var.enable_coder // if true, coder helm chart is installed

  // Chart versions
  coder_chart_version = "2.1.0"

  // Ingress details
  dns_domain = module.kube_loadbalancer.module_enabled ? join(".", [module.kube_loadbalancer.load_balancer_ip, "sslip.io"]) : null

  ingress_class_name = "traefik"

  file_output_directory = var.artifact_output_directory // This is where the random password will be stored. No need to change this for workshop.

  depends_on = [module.kube_loadbalancer,
  ]
}

// Longhorn
module "longhorn" {
  source           = "../../modules/kube_cluster_tooling/longhorn"
  enable_module   = var.enable_longhorn

  // Chart versions
  longhorn_version = "1.5.3"

  // Ingress details
  ingress_class_name = "traefik"
  # dns_domain         = module.kube_loadbalancer.module_enabled ? join(".", [module.kube_loadbalancer.load_balancer_ip, "sslip.io"]) : null

  // output_files directory
  artifact_output_directory = var.artifact_output_directory // This is where the random password will be stored. No need to change this for workshop.
  
  depends_on = [module.civo_sandbox_cluster,
  ]
}
