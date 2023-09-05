
# Terraform Module for Deploying Coder on Kubernetes

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Providers](#providers)
4. [Inputs](#inputs)
5. [Outputs](#outputs)
6. [Usage](#usage)
7. [Example](#example)
8. [Contributing](#contributing)
9. [License](#license)

## Overview

This Terraform module is designed to deploy a Coder development environment within a Kubernetes cluster. This includes setting up the necessary services, roles, and permissions for a fully functioning Coder service.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Kubernetes cluster](https://kubernetes.io/docs/setup/)
- [Helm](https://helm.sh/docs/intro/install/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

## Providers

- **Kubernetes**: Manages native Kubernetes resources.
- **Helm**: Deploys Helm charts to manage complex Kubernetes applications.
- **kubectl**: Allows execution of raw Kubernetes YAML manifests.

## Inputs

| Name                    | Description                                          | Type         | Default       | Required |
| ----------------------- | ---------------------------------------------------- | ------------ | ------------- | -------- |
| `dns_domain`            | Domain name for the Coder service                    | `string`     | n/a           | yes      |
| `coder_chart_version`   | Version of the Coder Helm chart                      | `string`     | `"latest"`    | no       |
| `postgresql_version`    | Version of the PostgreSQL Helm chart                 | `string`     | `"latest"`    | no       |
| `environment`           | Deployment environment (e.g., "development")         | `string`     | `"default"`   | no       |
| `file_output_directory` | Local directory for storing generated files          | `string`     | `"./output"`  | no       |
| `coder_enabled`         | Flag to enable or disable Coder provisioning        | `bool`       | `true`        | no       |

## Outputs

| Name                        | Description                                   |
| --------------------------- | --------------------------------------------- |
| `coder_access_url`          | The URL to access the deployed Coder service  |
| `postgres_connection_info`  | Connection details for the PostgreSQL database|

## Usage

To use this module in your own Terraform configuration, include it like so:

```hcl
module "coder" {
  source = "git::https://github.com/yourusername/terraform-coder-module.git"

  dns_domain          = "example.com"
  coder_chart_version = "1.0.0"
  postgresql_version  = "1.0.0"
  environment         = "development"
  file_output_directory = "./output"
}
```

