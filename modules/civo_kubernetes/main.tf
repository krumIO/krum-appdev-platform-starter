terraform {
  required_providers {
    civo = {
      source = "civo/civo"
      version = "1.0.35"
    }
  }
}

variable "kube_config_output_path" {
  description = "Path to write the kubeconfig file to"
  type = string
}
variable "cluster_name" {}
variable "cluster_type" {}
variable "firewall_name" {}
variable "node_count" {}
variable "node_size" {
  description = "Node size for the cluster. Supported values: xsmall, large"
  type = string
}
variable "applications" {}

variable "node_pool_name" {}
variable "network_id" {}

data "civo_size" "xsmall" {
  filter {
    key = "type"
    values = ["kubernetes"]
  }
  sort {
    key = "ram"
    direction = "asc"
  }
}

data "civo_size" "large" {
  filter {
    key = "type"
    values = ["kubernetes"]
  }
  sort {
    key = "ram"
    direction = "asc"
  }
}

resource "civo_firewall" "cluster_firewall" {
  name = var.firewall_name
  network_id = var.network_id
  create_default_rules = false
  ingress_rule {
    label = "kubernetes-api-server"
    protocol = "tcp"
    port_range = "6443"
    cidr = ["0.0.0.0/0"]
    action = "allow" 

  }
}


resource "civo_kubernetes_cluster" "cluster" {
  name = var.cluster_name
  firewall_id = civo_firewall.cluster_firewall.id
  network_id = var.network_id
  cluster_type = var.cluster_type
  applications = var.applications
  pools {
    label = var.node_pool_name // Optional
    size = var.node_size
    node_count = var.node_count
  }
}

resource "local_file" "civo_sandbox_cluster-kubeconfig" {
  filename          = var.kube_config_output_path
  sensitive_content = resource.civo_kubernetes_cluster.cluster.kubeconfig


  depends_on = [resource.civo_kubernetes_cluster.cluster]
}

output "cluster_id" {
  value = civo_kubernetes_cluster.cluster.id
}

output "firewall_id" {
  value = civo_firewall.cluster_firewall.id
}

output "kubeconfig" {
  description = "Kubeconfig for the created cluster"
  value       = civo_kubernetes_cluster.cluster.kubeconfig
  sensitive   = true
}
