# Kubernetes Cluster Tooling - Load Balancer Module

This Terraform module sets up a load balancer with the [Traefik Ingress Controller](https://doc.traefik.io/traefik/providers/kubernetes-ingress/) and deploys [cert-manager](https://cert-manager.io/) for managing SSL/TLS certificates in a Kubernetes cluster, using the Civo, Helm, and Kubernetes providers.

## Requirements

- Terraform 1.0 or newer.
- Civo API token
- A configured Kubernetes cluster

## Usage

Here is an example of how you might use this module in your own Terraform code:

```hcl
module "kube_lb" {
  source = "path/to/module"
  email = "email@example.com"
  traefik_version = "2.5.3"
  traefik_dashboard_password = "securepassword"
  kube_config_file = "/path/to/kubeconfig"
}
```

Then, run `terraform init` and `terraform apply`.

## Variables

- `email`: (Required) The email address to be used for certificate issuers and certificate resolvers.
- `traefik_version`: (Required) The version of the Traefik Helm chart to be deployed.
- `traefik_dashboard_password`: (Required) The password for accessing the Traefik dashboard.
- `kube_config_file`: (Required) Path to the kubeconfig file.

## Outputs

- `load_balancer_ip`: The IP address of the load balancer.

## Notes

Make sure to replace `"path/to/module"` with the actual path to this module in your code.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[MIT](https://choosealicense.com/licenses/mit/)