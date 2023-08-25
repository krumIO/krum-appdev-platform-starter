variable "environment" {
  description = "The deployment environment (development or production)."
  type        = string
}

variable "nxrm_chart_version" {
  description = "The version of the Sonatype Nexus to be deployed."
  type        = string
}

variable "nexus_license_file" {
  description = "The path to the Sonatype Nexus license file."
  type        = string
}

variable "db_name" {
  description = "The name of the database to be created."
  type        = string
}

variable "postgresql_version" {
  description = "The version of the PostgreSQL to be deployed."
  type        = string
}

variable "postgresql_username" {
  description = "The username for the PostgreSQL."
  type        = string
}

variable "outputs_path" {
  description = "The path to the outputs folder."
  type        = string
}

variable "dns_domain" {
  description = "The DNS domain to be used for the setup."
  type        = string
}

variable "ingress_class_name" {
  description = "The Ingress Class Name."
  type        = string
}

// Prod Values
variable "prod_db_host" {
  description = "The host of the external database for the production environment."
  type        = string
  default     = ""
}

variable "prod_db_username" {
  description = "The username for the external database for the production environment."
  type        = string
  default     = ""
}

variable "prod_db_password" {
  description = "The password for the external database for the production environment."
  type        = string
  sensitive   = true
  default     = ""
}

variable "prod_db_name" {
  description = "The name of the external database for the production environment."
  type        = string
  default     = ""
}

variable "iq_server_chart_version" {
  description = "The version of the Sonatype Nexus IQ Server Chart to be deployed."
  type        = string
}

variable "nxrm_docker_registry_enabled" {
  description = "Whether to enable the Docker Registry for the Sonatype Nexus."
  type        = bool
  default     = false
}