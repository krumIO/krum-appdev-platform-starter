
# Terraform Rancher Deployment Module

This Terraform module facilitates the deployment and management of Rancher within a Kubernetes cluster. Rancher is an open-source platform for managing Kubernetes clusters.

## Prerequisites

- Terraform 0.14+
- Kubernetes Cluster
- Kubectl
- Helm

## Features

- Deploys Rancher into a Kubernetes cluster
- Generates a random admin password for Rancher
- Outputs important information such as Rancher URL and admin password

## Usage

Include this module in your `main.tf` file:

```hcl
module "rancher_deployment" {
  source = "<Your-Module-Source>"

  // ... set your variables here
}
```

## Input Variables

| Variable              | Type    | Default | Description                          |
|-----------------------|---------|---------|--------------------------------------|
| `rancher_version`     | string  | N/A     | Version of Rancher to be deployed    |
| `dns_domain`          | string  | N/A     | DNS domain for the Rancher setup     |
| `ingress_class_name`  | string  | N/A     | Ingress Class Name                   |
| `email`               | string  | N/A     | Email for Let's Encrypt setup        |
| `kube_config_file`    | string  | N/A     | Path to kubeconfig file              |
| `file_output_directory` | string | N/A    | Directory to save generated files    |
| `enable_module`       | bool    | `true`  | Enable or disable the module         |

> **Note**: Most of the variables do not have default values and must be explicitly set.

## Example

```hcl
module "rancher_deployment" {
  source = "<Your-Module-Source>"
  
  rancher_version      = "2.6.0"
  dns_domain           = "example.com"
  ingress_class_name   = "nginx"
  email                = "admin@example.com"
  kube_config_file     = "~/.kube/config"
  file_output_directory = "/tmp"
  enable_module        = true
}
```

## Outputs

- `rancher_url`: The URL to access the Rancher Dashboard
- `rancher_admin_password`: Randomly generated admin password for Rancher
- `helm_repo_url`: The Helm repository URL used for the Rancher deployment
- `helm_repo_name`: The Helm release name for the Rancher deployment

