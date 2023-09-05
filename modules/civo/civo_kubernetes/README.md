# Terraform Civo Kubernetes Cluster Module

This Terraform module provisions a Kubernetes cluster on Civo Cloud, along with an associated firewall. The cluster type, node size, and other configurations are customizable.

## Dependencies

- Civo Terraform Provider v1.0.35 or newer

## Usage

Here's how to use this module in your Terraform project:

```hcl
module "civo_kubernetes_cluster" {
  source = "./path/to/this/module"

  cluster_name    = "my-cluster"
  cluster_type    = "k3s"
  firewall_name   = "my-firewall"
  node_count      = 3
  node_size       = "xsmall"
  applications    = ["Traefik", "metrics-server"]
  node_pool_name  = "default-pool"
  network_id      = "some-network-id"
  kube_config_output_path = "/path/to/kubeconfig"
}
```

## Variables

| Variable Name            | Description                            | Type          | Default Value  | Required |
|--------------------------|----------------------------------------|---------------|----------------|----------|
| `kube_config_output_path`| Path to write the kubeconfig file to   | `string`      |                | Yes      |
| `cluster_name`           |                                        | `string`      |                | Yes      |
| `cluster_type`           |                                        | `string`      |                | Yes      |
| `firewall_name`          |                                        | `string`      |                | Yes      |
| `node_count`             |                                        | `number`      |                | Yes      |
| `node_size`              | Node size for the cluster. xsmall, large| `string`      |                | Yes      |
| `applications`           |                                        | `list(string)`|                | Yes      |
| `node_pool_name`         |                                        | `string`      |                | Yes      |
| `network_id`             |                                        | `string`      |                | Yes      |
| `module_enabled`         | Is module enabled                      | `bool`        | `true`         | No       |

## Outputs

- `cluster_id`: The ID of the created Kubernetes cluster.
- `firewall_id`: The ID of the created firewall.
- `kubeconfig`: The kubeconfig for the created cluster. (Sensitive)
- `api_endpoint`: The API endpoint for the created cluster.
- `cluster_name`: The name of the created cluster.

## Important Note on Firewall Configuration

By default, the firewall ingress rule for the Kubernetes API server is set to allow traffic from `0.0.0.0/0`. This is not recommended for production environments. You may need to update this to suit your specific needs:

- Limit to your local network.
- Restrict to the IP address of specific instances or set of instances.
- Use a VPN or private network CIDR.

Adjust the ingress rules to match your security requirements.

