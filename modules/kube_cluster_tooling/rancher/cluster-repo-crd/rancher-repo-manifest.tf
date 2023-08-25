terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}

// Create a repository manifest for Rancher to manage life cycle via rancher interface
resource "kubectl_manifest" "rancher_repo_manifest" {
  count   = var.rancher_installed ? 1 : 0
  yaml_body = <<YAML
apiVersion: catalog.cattle.io/v1
kind: ClusterRepo
metadata:
  name: ${var.repo_name}
spec:
    url: ${var.repo_url}

YAML
}

// create veriables for string values but set default as null
variable "repo_name" {
  description = "Name of the repository"

}

variable "repo_url" {
  description = "URL of the repository"

}

variable "rancher_installed" {
  description = "Is Rancher installed"
  type        = bool
  default     = false
}

