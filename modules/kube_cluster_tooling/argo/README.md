# Terraform ArgoCD, Argo Workflows, and Argo Events Module

This Terraform module is designed to set up ArgoCD, Argo Workflows, and Argo Events on a Kubernetes cluster. It leverages the Helm provider for deploying Helm charts for each of the Argo components and uses the Kubernetes provider to interact directly with the cluster. The module also offers the option to enable or disable the setup with the `module_enabled` variable.

## Dependencies

- Kubernetes Terraform Provider v2.22.0 or newer
- Helm Terraform Provider v2.10.1 or newer
- Kubectl Terraform Provider v1.14.0 or newer
- Local Terraform Provider v2.4.0 or newer
- Random Terraform Provider v3.5.1 or newer

## Usage

To use this module, include the following in your Terraform code:

```hcl
module "argo_setup" {
  source = "./path/to/this/module"
  
  dns_domain                   = "example.com"
  ingress_class_name            = "nginx"
  argo_cd_chart_version        = "v1.0.0"
  email                        = "example@example.com"
  argo_workflows_chart_version = "v1.0.0"
  argo_events_chart_version    = "v1.0.0"
  kube_config_file             = "/path/to/kubeconfig"
  argo_workflows_ingress_enabled = false
}
```

## Variables

| Variable Name                | Description                                         | Type   | Default Value | Required |
|------------------------------|-----------------------------------------------------|--------|---------------|----------|
| `dns_domain`                 | The DNS domain to be used for the setup             | string |               | Yes      |
| `ingress_class_name`         | The Ingress Class Name                              | string |               | Yes      |
| `argo_cd_chart_version`      | Version of the Argo CD chart to be deployed         | string |               | Yes      |
| `email`                      | Email for Let's Encrypt                             | string |               | Yes      |
| `argo_workflows_chart_version`| Version of the Argo Workflows chart to be deployed  | string |               | Yes      |
| `argo_workflows_ingress_enabled` | Whether ingress for Argo Workflows is enabled    | bool   | false         | No       |
| `argo_events_chart_version`  | Version of the Argo Events chart to be deployed     | string |               | Yes      |
| `kube_config_file`           | Path to the kubeconfig file                         | string |               | Yes      |
| `module_enabled`             | Whether to enable this module                       | bool   | true          | No       |

## Outputs

- `helm_repo_url`: The URL of the Helm repository used for the Argo CD deployment.
- `helm_repo_name`: The name of the Helm chart used for the Argo CD deployment.

