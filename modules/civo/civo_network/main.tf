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

// Provider configuration for multi-region usage
provider "civo" {
  # Configuration options
  token  = var.civo_token
  region = var.civo_region
}

variable "civo_token" {
  description = "Civo API Token"
}

variable "civo_region" {
  description = "Specify Civo region for the deployment"
  default     = "NYC1"
}

resource "civo_network" "custom_net" {
  count = var.module_enabled ? 1 : 0
  provider = var.provider
  label = "${var.network_name}"
}

output "network_id" {
  value = resource.civo_network.custom_net[0].id
}

