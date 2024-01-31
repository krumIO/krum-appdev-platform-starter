terraform {
  required_providers {
    civo = {
      source  = "civo/civo"
      version = "1.0.39"
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

variable "module_enabled" {
  description = "Is module enabled"
  type        = bool
  default     = false
}

############################################
// Civo Database
data "civo_size" "small" {
  count = var.module_enabled ? 1 : 0
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
  count = var.module_enabled ? 1 : 0
  filter {
    key    = "engine"
    values = ["postgresql"]
  }
}

resource "civo_database" "custom_database" {
  count      = var.module_enabled ? 1 : 0
  name        = var.db_name
  size        = element(data.civo_size.small[0].sizes, 0).name
  nodes       = var.node_count
  region      = var.region
  network_id  = var.db_network_id
  firewall_id = civo_firewall.db_firewall[0].id
  engine      = element(data.civo_database_version.postgresql[0].versions, 0).engine
  version     = element(data.civo_database_version.postgresql[0].versions, 0).version
}

resource "civo_firewall" "db_firewall" {
  count               = var.module_enabled ? 1 : 0
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
  count = var.module_enabled ? 1 : 0
  name   = civo_database.custom_database[0].name
  region = civo_database.custom_database[0].region

  depends_on = [civo_database.custom_database]
}
############################################

output "database_password" {
  value     = var.module_enabled ? civo_database.custom_database[0].password : null
  sensitive = true
}


output "dns_endpoint" {
  value = var.module_enabled ? data.civo_database.custom[0].endpoint : null
}

output "module_enabled" {
  value = var.module_enabled 
}