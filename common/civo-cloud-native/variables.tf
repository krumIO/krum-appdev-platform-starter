variable "civo_token" {
  description = "Civo API Token"
}
variable "civo_region" {
  description = "Specify Civo region for the deployment"
  default     = "NYC1"
}

variable "email" {
  description = "Email address for use with lets-encrypt certificate requests"
}

variable "cert_manager_version" {
  description = "cert-manager version"
  default     = "1.12.2"
}

variable "rancher_version" {
  description = "rancher version"
  default     = "2.7.5"
}

variable "traefik_version" {
  description = "traefik version"
  default     = "23.1.0"
}

variable "ingress_class_name" {
  description = "ingress class name"
  default     = "traefik"
}

variable "ignore_rancher_metadata" {
  description = "ignore rancher metadata"
  default     = false
}

// Civo Database
variable "db_name" {
  description = "Name of the database"
  default     = "nxrmdb"
}

variable "db_node_count" {
  description = "Number of nodes for the database"
  default     = 1
}

variable "db_firewall_ingress_cidr" {
  description = "CIDR for ingress rules"
  default     = ["0.0.0.0/0"]
}

variable "kube_config_file" {
  description = "Path to kubeconfig file"
  default     = "./artifacts/output_files/kubeconfig"
}

variable "nexus_license_file_path" {
  description = "The path to the Sonatype Nexus license file."
  type        = string
  default    = null
}

variable "rancher_installed" {
  description = "rancher installed"
  default     = true
}

variable "artifact_output_directory" {
  description = "The directory where the output files will be stored."
  default     = "./artifacts/output_files"
}

//enable modules
####################
variable "proxy_argo_workflows_via_rancher" {
  description = "proxy argo workflows via rancher"
  default     = false
}

variable "enable_nexus_rm" {
  description = "enable nexus rm"
  default     = false
}

variable "enable_nexus_iq" {
  description = "enable nexus iq"
  default     = false
}

variable "enable_managed_civo_db" {
  description = "enable managed civo db"
  default     = false
}

variable "proxy_nexus_iq_admin_via_rancher" {
  description = "proxy nexus iq via rancher"
  default     = false
}

variable "enable_neuvector" {
  description = "enable neuvector"
  default     = false
}

variable "enable_coder" {
  description = "enable coder"
  default     = false
}

variable "enable_argo_suite" {
  description = "enable argo suite"
  default     = false
}

variable "enable_rancher" {
  description = "enable rancher"
  default     = false
}

variable "enable_kube_loadbalancer" {
  description = "enable kube loadbalancer"
  default     = false
}

variable "enable_nexus_docker_registry" {
  description = "enable nxrm docker registry"
  default     = false
}