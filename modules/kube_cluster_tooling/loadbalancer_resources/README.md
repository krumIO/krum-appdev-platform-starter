# Traefik and Cert-Manager Terraform Module

This module provides Terraform scripts to setup [Traefik](https://traefik.io/) as an Ingress Controller and [cert-manager](https://cert-manager.io/) for automatic certificate management in a Kubernetes cluster. The Civo, Kubernetes, Helm, and Kubectl providers are leveraged to achieve this.

## Resources

The following resources are created by this module:

- cert-manager Helm chart
- ClusterIssuer for Let's Encrypt staging and production environments
- Traefik Helm chart
- Traefik's ClusterRole and ClusterRoleBinding
- Fetching Traefik's Load Balancer IP address

## Usage

```hcl
module "traefik_certmanager" {
  source = "../path/to/module"

  email                    = "admin@example.com"
  traefik_version          = "2.5.4"
  traefik_dashboard_password = "password123"
  kube_config_file         = "~/.kube/config"
}
```

## Variables

The following variables are used in this module:

- `email`: Email address used for certificate issuers and certificate resolvers.
- `traefik_version`: Version of Traefik Helm chart to be deployed.
- `traefik_dashboard_password`: Password for accessing Traefik dashboard.
- `kube_config_file`: Path to kubeconfig file.

## Providers

This module uses the following Terraform providers:

- `civo/civo` version 1.0.34
- `hashicorp/kubernetes` version 2.20.0
- `hashicorp/helm` version 2.9.0
- `gavinbunney/kubectl` version 1.13.0
- `hashicorp/local` version 1.4.0
- `hashicorp/random` version 3.5.1

## Outputs

The following outputs are exported:

- `load_balancer_ip`: The load balancer IP address. It can be used to access the Traefik Dashboard and other services exposed through Traefik.

## Dependencies

- A Kubernetes cluster is required. The cluster connection is configured using the `kube_config_file` variable.
- The Helm provider is used to deploy Traefik and cert-manager. Make sure Helm is configured correctly in your cluster.

## Authors

Module managed by [Krumware](https://github.com/krumIO).

## License

MIT License. See [LICENSE](./LICENSE) for full details.