variable "civo_token" {
  description = "Civo API Token"
}
variable "civo_region" {
  description = "Specify Civo region for the deployment"
  default     = "PHX1"
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
  default     = ["204.116.188.66"]
}

variable "kube_config_file" {
  description = "Path to kubeconfig file"
  default     = "./artifacts/output_files/kubeconfig"
}

variable "nexus_license_file_path" {
  description = "The path to the Sonatype Nexus license file."
  type        = string
}