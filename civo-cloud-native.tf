module "civo-cloud-native" {
  source = "./common/civo-cloud-native"

  // Civo resources
  civo_region = var.civo_region
  civo_token  = var.civo_token

  // For Cert Manager SSL Certificates via LetsEncrypt
  # must be a valid email address
  email = var.email

  // if deploying a database module
  db_name                  = "nxrmdb"
  db_node_count            = 1
  db_firewall_ingress_cidr = ["0.0.0.0/0"]

  // Sonatype License
  # If no license exists, set to null
  nexus_license_file_path = null # "./artifacts/input_files/sonatype.lic"

  ##################################################
  ## Enable Modules:

  // Core Dependency: Set enable_kube_loadbalancer to true to activate other features
  enable_kube_loadbalancer = true
  ## Note: The following features depend on enable_kube_loadbalancer being true

  // Rancher
  # Set enable_rancher to true or false as needed
  enable_rancher = true

  // Argo Suite: ArgoCD, Argo Workflows, Argo Events
  # Note: Requires enable_kube_loadbalancer to be true
  enable_argo_suite = true
  # Proxy Argo Workflows via Rancher
  # Note: Requires enable_rancher to be true
  proxy_argo_workflows_via_rancher = true

  // Nexus Repository Manager
  # Set enable_nexus_rm to true or false as needed
  enable_nexus_rm              = false
  enable_nexus_docker_registry = false //requires enable_nexus_rm to be true
  # Nexus IQ Server
  enable_nexus_iq = false // Note: Requires enable_nexus_rm to be true
  # Proxy Nexus IQ Server via Rancher
  # Note: Requires enable_rancher to be true
  proxy_nexus_iq_admin_via_rancher = false

  // Managed Civo Database
  # Set enable_managed_civo_db to true or false as needed
  # Note: Required if var.environment="production" for Nexus Repository Manager
  enable_managed_civo_db = false

  // NeuVector
  # Set enable_neuvector to true or false as needed
  enable_neuvector = false

  // Coder
  # Set enable_coder to true or false as needed
  enable_coder = false
}
