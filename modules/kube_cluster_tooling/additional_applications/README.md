# Kubernetes Applications Deployment Module

This Terraform module deploys various applications including Rancher, ArgoCD, Argo Workflows, and Argo Events on a Kubernetes cluster in the [Civo cloud](https://www.civo.com/), leveraging multiple providers including the Civo, Helm, and Kubernetes Terraform providers.

## Requirements

- Terraform 1.0 or newer.
- Civo API token
- A configured Kubernetes cluster

## Usage

Here is an example of how you might use this module in your own Terraform code:

```hcl
module "kube_apps" {
  source = "path/to/module"
  rancher_version = "2.7.5"
  dns_domain = "mydomain.com"
  ingress_class_name = "traefik"
  rancher_server_admin_password = "my_secure_password"
  argo_cd_version = "5.38.0"
  email = "myemail@domain.com"
  argo_workflows_version = "0.30.0"
  argo_events_version = "2.4.0"
  kube_config_file = "/path/to/kubeconfig"
}
```

Then, run `terraform init` and `terraform apply`.

## Variables

- `rancher_version`: (Required) The version of Rancher to be deployed.
- `dns_domain`: (Required) The DNS domain to be used for the setup.
- `ingress_class_name`: (Required) The Ingress Class Name.
- `rancher_server_admin_password`: (Required) The password for the Rancher server admin.
- `argo_cd_version`: (Required) The version of Argo CD to be deployed.
- `email`: (Required) The email for letsencrypt setup.
- `argo_workflows_version`: (Required) The version of Argo Workflows to be deployed.
- `argo_events_version`: (Required) The version of Argo Events to be deployed.
- `kube_config_file`: (Required) Path to kubeconfig file.

## Outputs

- No outputs.

## Notes

Make sure to replace `"path/to/module"` with the actual path to this module in your code.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[MIT](https://choosealicense.com/licenses/mit/)