terraform {
  required_providers {
    civo = {
      source  = "civo/civo"
      version = "1.0.35"
    }
  }
}

variable "network_name" {}

// Create a random ID for the network suffix to avoid conflicts
resource "random_id" "network_suffix" {
  byte_length = 4
}

resource "civo_network" "custom_net" {
  label = "${var.network_name}-${random_id.network_suffix.hex}"
}

output "network_id" {
  value = resource.civo_network.custom_net.id
}

