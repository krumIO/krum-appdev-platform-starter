terraform {
  required_providers {
    civo = {
      source  = "civo/civo"
      version = "1.0.39"
    }
  }
}

variable "domain_name" {}

# Create a new domain name
resource "civo_dns_domain_name" "main" {
  name = var.domain_name
}

