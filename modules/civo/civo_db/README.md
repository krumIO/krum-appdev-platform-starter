
# Civo Database Module

This module provisions a database in the [Civo Kubernetes service](https://www.civo.com/), including creating the database, a corresponding firewall, and outputs the generated database password. It uses the Civo Terraform provider.

## Requirements

- Terraform 1.0 or newer.
- Civo API token
- Civo Region

## Usage

Here is an example of how you might use this module in your own Terraform code:

```hcl
module "civo_db" {
  source = "path/to/module"

  db_name         = "mydatabase"
  node_count      = 2
  region          = "NYC1"
  db_network_id   = "network-id"
  firewall_ingress_cidr = ["0.0.0.0/0"]
}
```

Then, run `terraform init` and `terraform apply`.

## Variables

- `db_name`: (Required) Name of the database
- `node_count`: (Required) The number of nodes
- `region`: (Required) The region in which to deploy the database
- `firewall_name`: (Optional) Name of the firewall. Default is "db-firewall"
- `db_network_id`: (Optional) ID of the network. Default is "network-id"
- `db_port`: (Optional) Port of the database. Default is "5432"
- `firewall_ingress_cidr`: (Optional) CIDR for ingress rules. Default is ["0.0.0.0/0"]
- `egress_rules`: (Optional) List of egress rules. Default is an egress rule for all traffic on all ports

## Outputs

- `database_password`: The generated password for the database. This is marked as sensitive and will not be shown in the `terraform apply` output.

## Notes

Please note that you should not use `0.0.0.0/0` for `firewall_ingress_cidr` in production as this will allow access to your database from any IP address. 

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[MIT](https://choosealicense.com/licenses/mit/)

Remember to replace `"path/to/module"` with the actual path to this module in your code.