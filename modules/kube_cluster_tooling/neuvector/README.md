
# Terraform NeuVector Module

This Terraform module allows for the deployment and configuration of NeuVector in a Kubernetes cluster. NeuVector is an end-to-end container security solution that provides runtime visibility and multi-vector protection against known and unknown threats.

## Prerequisites

- Terraform 0.14+
- Kubernetes Cluster
- Helm 3+

## Features

- Installs NeuVector Helm chart.
- Automatically generates an admin password for NeuVector.
- Supports multiple container runtimes.
- Optional integration with Rancher SSO.

## Usage

```hcl
module "neuvector" {
  source  = "<Your-Module-Source>"
  
  // ... set your variables here
}
```

## Input Variables

| Variable                 | Type    | Default                   | Description                                          |
|--------------------------|---------|---------------------------|------------------------------------------------------|
| `neuvector_chart_version`| string  | `2.6.1`                   | NeuVector Helm chart version                         |
| `k3s_enabled`             | bool    | `false`                   | Enable or disable K3s runtime                        |
| `rancher_installed`       | bool    | `false`                   | Whether Rancher is installed                         |
| `cluster_name`            | string  | `neuvector`               | Kubernetes cluster name                              |
| `dns_domain`              | string  | `example.com`             | DNS domain                                           |
| `file_output_directory`   | string  | `/tmp`                    | Directory to output NeuVector admin password and URL |
| `tls_cluster_issuer_name` | string  | `letsencrypt-production`  | Cluster issuer name for TLS                          |
| `ingress_class_name`      | string  | `traefik`                 | Ingress class name                                   |
| `docker_enabled`          | bool    | `false`                   | Enable or disable Docker runtime                     |
| `containerd_enabled`      | bool    | `false`                   | Enable or disable containerd runtime                 |
| `crio_enabled`            | bool    | `false`                   | Enable or disable CRI-O runtime                      |
| `module_enabled`          | bool    | `true`                    | Enable or disable the deployment of this module      |

## Outputs

- `helm_repo_url`: Helm repository URL of the deployed NeuVector.
- `helm_repo_name`: Helm repository name of the deployed NeuVector.

## Example

```hcl
module "neuvector" {
  source = "<Your-Module-Source>"
  
  neuvector_chart_version = "2.6.1"
  rancher_installed       = true
  cluster_name            = "my-cluster"
  dns_domain              = "example.com"
  tls_cluster_issuer_name = "letsencrypt-production"
  ingress_class_name      = "traefik"
}
```

## How it Works

### Password Generation

The `random_password` resource generates a 16-character password for the NeuVector admin user. The password does not include special characters.

### Configuration File

The `local_file` resource creates a text file containing the NeuVector admin password and NeuVector URL. This allows for easy sharing and backup.

### Helm Deployment

The `helm_release` resource is responsible for deploying NeuVector. The configuration can vary depending on whether Rancher is installed, the container runtime in use, and other variables.

### Conditionals

Throughout the module, the `count` attribute is used to conditionally create resources based on the `module_enabled` variable. This makes it easy to enable or disable the module.

## Contributions

Contributions to this module are welcome. Please submit a PR with your changes and a description of what the changes accomplish.

