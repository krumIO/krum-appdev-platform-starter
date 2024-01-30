terraform {
  required_providers {
    civo = {
      source  = "civo/civo"
      version = "1.0.39"
    }
  }
}

variable "network_name" {}

variable "module_enabled" {
  description = "Is module enabled"
  type        = bool
  default     = true
}

resource "civo_network" "custom_net" {
  count = var.module_enabled ? 1 : 0
  label = "${var.network_name}"
}

output "network_id" {
  value = resource.civo_network.custom_net[0].id
}

