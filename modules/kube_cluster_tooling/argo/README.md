# ArgoCD Terraform Module

This module provides Terraform scripts to setup [ArgoCD](https://argoproj.github.io/argo-cd/), [Argo Workflows](https://argoproj.github.io/argo-workflows/) and [Argo Events](https://argoproj.github.io/argo-events/) in a Kubernetes cluster. It leverages the Helm provider to deploy these tools.

## Resources

The following resources are created by this module:

- ArgoCD
- Argo Workflows
- Argo Events

## Usage

```hcl
module "argocd" {
  source = "../path/to/module"

  dns_domain                 = "example.com"
  ingress_class_name         = "nginx"
  argo_cd_version            = "1.8.7"
  email                      = "admin@example.com"
  argo_workflows_version     = "3.1.1"
  argo_workflows_ingress_enabled = true
  argo_events_version        = "1.2.1"
  kube_config_file           = "~/.kube/config"
}
```

## Variables

The following variables are used in this module:

- `dns_domain`: The DNS domain to be used for the setup.
- `ingress_class_name`: The Ingress Class Name.
- `argo_cd_version`: The version of the Argo CD to be deployed.
- `email`: The email for letsencrypt setup.
- `argo_workflows_version`: The version of the Argo Workflows to be deployed.
- `argo_workflows_ingress_enabled`: Flag to enable ingress for Argo Workflows. Default is false.
- `argo_events_version`: The version of the Argo Events to be deployed.
- `kube_config_file`: Path to kubeconfig file.

## Providers

This module uses the following Terraform providers:

- `hashicorp/kubernetes` version 2.20.0
- `hashicorp/helm` version 2.9.0
- `gavinbunney/kubectl` version 1.13.0
- `hashicorp/local` version 1.4.0
- `hashicorp/random` version 3.5.1

## Dependencies

- A Kubernetes cluster is required. The cluster connection is configured using the `kube_config_file` variable.
- The Argo Workflows and Argo Events resources have a dependency on the ArgoCD resource. They will be deployed only after the ArgoCD resource has been successfully deployed.
- The Helm provider is used to deploy ArgoCD, Argo Workflows and Argo Events. Make sure Helm is configured correctly in your cluster.
- The `dns_domain` variable must be a valid and accessible domain. 

## Authors

Module managed by [Krumware](https://github.com/krumIO)

## License

MIT License. See [LICENSE](./LICENSE) for full details.