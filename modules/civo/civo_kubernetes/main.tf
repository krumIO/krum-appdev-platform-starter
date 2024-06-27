terraform {
  required_providers {
    civo = {
      source  = "civo/civo"
      version = "1.0.39"
    }
  }
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

variable "kube_config_output_path" {
  description = "Path to write the kubeconfig file to"
  type        = string
}
variable "cluster_name" {}
variable "cluster_type" {}
variable "firewall_name" {}
variable "node_count" {}
variable "node_size" {
  description = "Node size for the cluster. Supported values: xsmall, large"
  type        = string
}
variable "applications" {}

variable "node_pool_name" {}
variable "network_id" {}

variable "module_enabled" {
  description = "Is module enabled"
  type        = bool
  default     = true
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.27.11-k3s1"
}

variable "cni" {
  description = "CNI plugin to use"
  type        = string
  default     = "flannel"
}

data "civo_size" "xsmall" {
  count = var.module_enabled ? 1 : 0
  filter {
    key    = "type"
    values = ["kubernetes"]
  }
  sort {
    key       = "ram"
    direction = "asc"
  }
}

data "civo_size" "large" {
  count = var.module_enabled ? 1 : 0
  filter {
    key    = "type"
    values = ["kubernetes"]
  }
  sort {
    key       = "ram"
    direction = "asc"
  }
}

resource "civo_firewall" "cluster_firewall" {
  count                = var.module_enabled ? 1 : 0
  name                 = var.firewall_name
  network_id           = var.network_id
  create_default_rules = false
  ingress_rule {
    label      = "kubernetes-api-server"
    protocol   = "tcp"
    port_range = "6443"
    cidr       = ["0.0.0.0/0"]
    action     = "allow"

  }
}


resource "civo_kubernetes_cluster" "cluster" {
  count              = var.module_enabled ? 1 : 0
  name               = var.cluster_name
  firewall_id        = civo_firewall.cluster_firewall[0].id
  network_id         = var.network_id
  cluster_type       = var.cluster_type
  kubernetes_version = var.kubernetes_version
  cni                = var.cni
  applications       = var.applications

  pools {
    label      = var.node_pool_name // Optional
    size       = var.node_size
    node_count = var.node_count
  }
}

resource "local_sensitive_file" "civo_sandbox_cluster-kubeconfig" {
  count    = var.module_enabled ? 1 : 0
  filename = var.kube_config_output_path
  content  = resource.civo_kubernetes_cluster.cluster[0].kubeconfig


  depends_on = [resource.civo_kubernetes_cluster.cluster]
}

output "cluster_id" {
  value = var.module_enabled ? civo_kubernetes_cluster.cluster[0].id : null
}


output "firewall_id" {
  value = var.module_enabled ? civo_firewall.cluster_firewall[0].id : null
}


output "kubeconfig" {
  description = "Kubeconfig for the created cluster"
  value       = var.module_enabled ? civo_kubernetes_cluster.cluster[0].kubeconfig : null
  sensitive   = true
}

output "api_endpoint" {
  description = "API endpoint for the created cluster"
  value       = var.module_enabled ? civo_kubernetes_cluster.cluster[0].api_endpoint : null
}

// output cluster name
output "cluster_name" {
  description = "Cluster name"
  value       = var.module_enabled ? civo_kubernetes_cluster.cluster[0].name : null
}

output "kubernetes_version" {
  description = "Kubernetes version"
  value       = var.module_enabled ? civo_kubernetes_cluster.cluster[0].kubernetes_version : null
}