terraform {
  required_providers {
    civo = {
      source  = "civo/civo"
      version = "1.0.35"
    }
  }
}

variable "db_name" {}
variable "node_count" {}
variable "region" {}


variable "firewall_name" {
  description = "Name of the firewall"
  type        = string
  default     = "db-firewall"
}

variable "db_network_id" {
  description = "ID of the network"
  type        = string
  default     = "network-id"
}
variable "db_port" {
  description = "Port of the database"
  type        = string
  default     = "5432"
}

variable "firewall_ingress_cidr" {
  description = "CIDR for ingress rules"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "egress_rules" {
  description = "List of egress rules"
  type = list(object({
    label      = string
    protocol   = string
    port_range = string
    cidr       = list(string)
    action     = string
  }))
  default = [
    {
      label      = "all"
      protocol   = "tcp"
      port_range = "1-65535"
      cidr       = ["0.0.0.0/0"]
      action     = "allow"
    },
  ]
}

############################################
// Civo Database
data "civo_size" "small" {
  filter {
    key      = "name"
    values   = ["db.small"]
    match_by = "re"
  }
  filter {
    key    = "type"
    values = ["database"]
  }
}

data "civo_database_version" "postgresql" {
  filter {
    key    = "engine"
    values = ["postgresql"]
  }
}

resource "civo_database" "custom_database" {
  name        = var.db_name
  size        = element(data.civo_size.small.sizes, 0).name
  nodes       = var.node_count
  region      = var.region
  network_id  = var.db_network_id
  firewall_id = civo_firewall.db_firewall.id
  engine      = element(data.civo_database_version.postgresql.versions, 0).engine
  version     = element(data.civo_database_version.postgresql.versions, 0).version
}

resource "civo_firewall" "db_firewall" {
  name                 = "${var.db_name}-firewall"
  network_id           = var.db_network_id
  create_default_rules = false
  ingress_rule {
    label      = "db-access"
    protocol   = "tcp"
    port_range = 5432
    cidr       = var.firewall_ingress_cidr
    action     = "allow"
  }

}

data "civo_database" "custom" {
  name   = civo_database.custom_database.name
  region = civo_database.custom_database.region

  depends_on = [civo_database.custom_database]
}
############################################

output "database_password" {
  value     = civo_database.custom_database.password
  sensitive = true
}


output "dns_endpoint" {
  value = data.civo_database.custom.endpoint
}