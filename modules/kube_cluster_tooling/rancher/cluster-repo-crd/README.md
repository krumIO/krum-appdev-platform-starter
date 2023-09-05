
# Terraform Rancher Repository Module

This Terraform module enables the management of a repository manifest for Rancher within a Kubernetes cluster. This is especially useful for managing the lifecycle of Helm charts via the Rancher interface.

## Prerequisites

- Terraform 0.14+
- Kubernetes Cluster
- Kubectl

## Features

- Creates a Rancher repository manifest for managing Helm charts.
- Supports conditional deployment based on Rancher presence and module enablement.

## Usage

```hcl
module "rancher_repo" {
  source  = "<Your-Module-Source>"
  
  // ... set your variables here
}
```

## Input Variables

| Variable          | Type  | Default | Description                       |
|-------------------|-------|---------|-----------------------------------|
| `repo_name`       | string| `null`  | Name of the repository            |
| `repo_url`        | string| `null`  | URL of the repository             |
| `rancher_installed`| bool | `false` | Is Rancher installed on the cluster |
| `module_enabled`  | bool  | `false` | Enable or disable the deployment of this module |

> **Note**: `repo_name` and `repo_url` do not have default values and must be explicitly set.

## Example

```hcl
module "rancher_repo" {
  source = "<Your-Module-Source>"
  
  repo_name          = "my-helm-repo"
  repo_url           = "https://charts.example.com/"
  rancher_installed  = true
  module_enabled     = true
}
```

