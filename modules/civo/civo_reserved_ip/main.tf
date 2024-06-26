terraform {
  required_providers {
    civo = {
      source  = "civo/civo"
      version = "1.0.45"
    }
  }
}

variable "name" {
  type = string
}

resource "civo_reserved_ip" "www" {
  name = var.name
}


output "ip" {
  value = civo_reserved_ip.www.ip
}
