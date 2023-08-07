terraform {
  required_providers {
    civo = {
      source  = "civo/civo"
      version = "1.0.35"
    }
  }
}

variable "network_name" {}

resource "civo_network" "custom_net" {
  label = "${var.network_name}"
}

output "network_id" {
  value = resource.civo_network.custom_net.id
}

