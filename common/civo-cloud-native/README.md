# Terraform Module for Kubernetes Deployment on Civo Cloud

This Terraform module is designed to provision a Kubernetes cluster on Civo Cloud. It sets up Virtual Private Cloud (VPC) and Firewall configurations specifically for the cluster. Additionally, the module offers optional installations for various DevOps and cloud-native tools like Rancher, the Argo Suite, Sonatype Nexus Repository Manager, Sonatype IQ Server, and more.

## Prerequisites

- Terraform version 1.x

## Features

- Provisions a Kubernetes cluster on Civo Cloud
- Configures a Virtual Private Cloud (VPC) and firewall rules for the Kubernetes cluster
- Provides optional Rancher setup for Kubernetes management
- Offers optional installation for ArgoCD, Argo Workflows, and Argo Events
- Enables optional setup for Sonatype Nexus Repository Manager and IQ Server
- Allows for optional Managed Civo Database integration
- Supports optional NeuVector installation for container security
- Facilitates optional Coder installation for development environments
- More features can be enabled as needed

## Usage

Include this module in your existing Terraform configuration files:

```hcl
module "civo-cloud-native" {
  source = "./common/civo-cloud-native"

  // Civo resources
  civo_region = var.civo_region
  civo_token  = var.civo_token

  // For Cert Manager SSL Certificates via LetsEncrypt
  email = var.email

  // Database configuration (optional)
  db_name                  = "nxrmdb"
  db_node_count            = 1
  db_firewall_ingress_cidr = ["0.0.0.0/0"]

  // Sonatype License (optional)
  nexus_license_file_path = null

  // Core Dependency
  enable_kube_loadbalancer = true

  // Optional Modules
  enable_rancher                     = true
  enable_argo_suite                  = true
  proxy_argo_workflows_via_rancher   = true
  enable_nexus_rm                    = false
  enable_nexus_docker_registry       = false
  enable_nexus_iq                    = false
  proxy_nexus_iq_via_rancher         = false
  enable_managed_civo_db             = false
  enable_neuvector                   = false
  enable_coder                       = false
}
```

Then execute the following commands:

```bash
terraform init
terraform apply
```

### Example Input Variables

An example file named `terraform.tfvars.example` is provided in the main directory. Rename this file to `terraform.tfvars` and populate it with the required variables:

```hcl
# terraform.tfvars
civo_token  = "your_civo_api_token"
civo_region = "NYC1"
email       = "your_email@example.com"
```

For more advanced configurations, you can set optional variables such as `db_name`, `enable_rancher`, among others.

### Inputs

| Variable                           | Description                                        | Type     | Default           | Dependencies                                          |
| ---------------------------------- | -------------------------------------------------- | -------- | ----------------- | ----------------------------------------------------- |
| `civo_token`                       | Civo API Token                                     | `string` | -                 | None                                                  |
| `civo_region`                      | Civo region for the deployment                     | `string` | "NYC1"            | None                                                  |
| `email`                            | Email address for LetsEncrypt certificate requests | `string` | -                 | None                                                  |
| `cert_manager_version`             | cert-manager version                               | `string` | "1.12.2"          | None                                                  |
| `rancher_version`                  | rancher version                                    | `string` | "2.7.5"           | None                                                  |
| `traefik_version`                  | traefik version                                    | `string` | "23.1.0"          | None                                                  |
| `ingress_class_name`               | ingress class name                                 | `string` | "traefik"         | None                                                  |
| `ignore_rancher_metadata`          | ignore rancher metadata                            | `bool`   | `false`           | None                                                  |
| `db_name`                          | Name of the database                               | `string` | "nxrmdb"          | None                                                  |
| `db_node_count`                    | Number of nodes for the database                   | `int`    | 1                 | None                                                  |
| `db_firewall_ingress_cidr`         | CIDR for ingress rules                             | `list`   | ["0.0.0.0/0"]     | None                                                  |
| `kube_config_file`                 | Path to kubeconfig file                            | `string` | "./artifacts..."  | None                                                  |
| `nexus_license_file_path`          | Path to Sonatype Nexus license file                | `string` | `null`            | `enable_nexus_rm` must be `true`                      |
| `enable_nexus_iq`                  | Enable Nexus IQ Server                             | `bool`   | `false`           | `enable_nexus_rm` must be `true`                      |
| `proxy_nexus_iq_admin_via_rancher` | Proxy Nexus IQ Admin Tools via Rancher             | `bool`   | `false`           | `enable_rancher` and `enable_nexus_iq` must be `true` |
| `rancher_installed`                | Rancher installed                                  | `bool`   | `true`            | None                                                  |
| `artifact_output_directory`        | Directory for output files                         | `string` | "./artifacts/..." | None                                                  |
| `enable_kube_loadbalancer`         | Enables the Kubernetes load balancer               | `bool`   | `false`           | Core Dependency for many modules                      |
| `enable_rancher`                   | Enables Rancher                                    | `bool`   | `false`           | Requires `enable_kube_loadbalancer` to be `true`      |
| `enable_argo_suite`                | Enables the Argo Suite                             | `bool`   | `false`           | Requires `enable_kube_loadbalancer` to be `true`      |

**Note**: More dependent variables are available for optional modules. Please refer to the `variables.tf` file for full details and descriptions.

### Outputs

- `cluster_endpoint`: The endpoint URL of the provisioned Kubernetes cluster.
