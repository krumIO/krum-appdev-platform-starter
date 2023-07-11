# Civo Kubernetes Cluster Module

This module manages a Kubernetes cluster in the [Civo cloud](https://www.civo.com/), which uses the Civo Terraform provider.

## Requirements

- Terraform 1.0 or newer.
- Civo API token

## Usage

Here is an example of how you might use this module in your own Terraform code:

```hcl
module "civo_kubernetes_cluster" {
  source = "path/to/module"

  kube_config_output_path = "./kubeconfig.yaml"
  cluster_name = "my_cluster"
  cluster_type = "k3s"
  firewall_name = "my_cluster_firewall"
  node_count = 3
  node_size = "g4s.kube.medium"
  applications = ["linkerd", "monitoring"]
  node_pool_name = "my_node_pool"
  network_id = "my_network_id"
}
```

Then, run `terraform init` and `terraform apply`.

## Variables

- `kube_config_output_path`: (Required) Path where the generated kubeconfig file will be saved.
- `cluster_name`: (Required) Name of the Kubernetes cluster to create.
- `cluster_type`: (Required) Type of the Kubernetes cluster. Supported values: `k3s`.
- `firewall_name`: (Required) Name of the firewall associated with the cluster.
- `node_count`: (Required) Number of nodes in the cluster.
- `node_size`: (Required) Size of the nodes in the cluster. Supported values: `xsmall`, `large`.
- `applications`: (Required) List of applications to install on the cluster.
- `node_pool_name`: (Required) Name of the node pool.
- `network_id`: (Required) ID of the network to associate with the cluster.

## Outputs

- `cluster_id`: The ID of the created Kubernetes cluster.
- `firewall_id`: The ID of the created firewall.
- `kubeconfig`: The kubeconfig for the created cluster. This is marked as sensitive and will not be displayed in the console.

## Notes

Make sure to replace `"path/to/module"` with the actual path to this module in your code.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[MIT](https://choosealicense.com/licenses/mit/)