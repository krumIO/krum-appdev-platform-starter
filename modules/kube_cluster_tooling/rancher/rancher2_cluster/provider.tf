terraform {
  required_providers {
    rancher2 = {
      source = "rancher/rancher2"
      version = "4.1.0"
    }
  }
}

provider "rancher2" {

  api_url  = var.rancher_api_url
  insecure = false
  # ca_certs  = data.kubernetes_secret.rancher_cert.data["ca.crt"]
  token_key = var.token_key
  timeout   = "300s"
  bootstrap = false
}