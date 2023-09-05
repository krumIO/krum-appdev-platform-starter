# Terraform Kubernetes Module for Traefik and Cert-Manager

This Terraform module provides an easy way to deploy Traefik as an Ingress controller along with Cert-Manager for SSL certificate management on a Kubernetes cluster.

## Features

- Deployment of Cert-Manager using Helm.
- Configuration of Let's Encrypt Staging and Production Issuers.
- Deployment of Traefik as an Ingress controller using Helm.
- Output of Load Balancer IP and Helm repository details.

## Requirements

The following Terraform providers are required:

- Kubernetes: 2.22.0
- Helm: 2.10.1
- Kubectl: 1.14.0 (gavinbunney/kubectl)
- Local: 2.4.0
- Random: 3.5.1

## Usage

Include this repository as a module in your existing Terraform code:

```hcl
module "traefik_cert_manager" {
  source = "./path/to/this/module"

  email                      = "example@example.com"
  traefik_chart_version      = "x.y.z"
  cert_manager_chart_version = "a.b.c"
  kube_config_file           = "./kubeconfig.yaml"
}
```

Run `terraform init` and `terraform apply` to deploy.

## Variables

- `email`: Email address used for Let's Encrypt certificate issuers and certificate resolvers.
- `traefik_chart_version`: Version of Traefik Helm chart to be deployed.
- `traefik_dashboard_password`: Password for accessing the Traefik dashboard. (Sensitive)
- `kube_config_file`: Path to kubeconfig file.
- `ingress_class_name`: The Ingress Class Name. (Default: "traefik")
- `cert_manager_chart_version`: Version of Cert-Manager Helm chart to be deployed.
- `module_enabled`: Flag to enable or disable the module. (Default: true)

## Outputs

- `load_balancer_ip`: IP address of the load balancer for Traefik.
- `helm_repo_url_traefik`: Helm repository URL for Traefik.
- `helm_repo_name_traefik`: Helm repository name for Traefik.
- `helm_repo_url_cert_manager`: Helm repository URL for Cert-Manager.
- `helm_repo_name_cert_manager`: Helm repository name for Cert-Manager.
- `module_enabled`: Status of the module, whether it is enabled or not.

## Dependencies

- A running Kubernetes cluster and a configured kubectl.
- Helm installed and configured to manage deployments in Kubernetes.

## Contributing

Feel free to open issues or pull requests to improve the module, making sure to follow the established code conventions and best practices.
