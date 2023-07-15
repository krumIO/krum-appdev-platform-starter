# Rancher Terraform Module

This module provides Terraform scripts to setup [Rancher](https://rancher.com/) in a Kubernetes cluster. It leverages the Helm provider to deploy Rancher.

## Resources

The following resources are created by this module:

- Rancher

## Usage

```hcl
module "rancher" {
  source = "../path/to/module"

  rancher_version             = "2.6.0"
  dns_domain                  = "example.com"
  ingress_class_name          = "nginx"
  rancher_server_admin_password = "password123"
  email                       = "admin@example.com"
  kube_config_file            = "~/.kube/config"
}
```

## Variables

The following variables are used in this module:

- `rancher_version`: The version of the Rancher to be deployed.
- `dns_domain`: The DNS domain to be used for the setup.
- `ingress_class_name`: The Ingress Class Name.
- `rancher_server_admin_password`: The password for the Rancher server admin.
- `email`: The email for letsencrypt setup.
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
- The Helm provider is used to deploy Rancher. Make sure Helm is configured correctly in your cluster.
- The `dns_domain` variable must be a valid and accessible domain. 

## Authors

Module managed by [Krumware](https://github.com/krumIO).

## License

MIT License. See [LICENSE](./LICENSE) for full details.