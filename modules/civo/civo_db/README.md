# Terraform Civo Database Module

This Terraform module creates a PostgreSQL database and its associated firewall on Civo Cloud. The database engine, size, and other configurations are customizable.

## Dependencies

- Civo Terraform Provider v1.0.35 or newer

## Usage

Here's how to invoke this module in your project:

```hcl
module "civo_database" {
  source = "./path/to/this/module"

  db_name       = "example-db"
  node_count    = 3
  region        = "lon1"
  module_enabled = true

  // Other variables can also be set here
}
```

## Variables

| Variable Name          | Description           | Type          | Default Value  | Required |
|------------------------|-----------------------|---------------|----------------|----------|
| `db_name`              |                       | `string`      |                | Yes      |
| `node_count`           |                       | `number`      |                | Yes      |
| `region`               |                       | `string`      |                | Yes      |
| `firewall_name`        | Name of the firewall  | `string`      | "db-firewall"  | No       |
| `db_network_id`        | ID of the network     | `string`      | "network-id"   | No       |
| `db_port`              | Port of the database  | `string`      | "5432"         | No       |
| `firewall_ingress_cidr`| CIDR for ingress rules| `list(string)`| ["0.0.0.0/0"]  | No       |
| `egress_rules`         | List of egress rules  | `list(object)`| (See below)    | No       |
| `module_enabled`       | Is module enabled     | `bool`        | `false`        | No       |

**Default for `egress_rules`:**

```hcl
[
  {
    label      = "all"
    protocol   = "tcp"
    port_range = "1-65535"
    cidr       = ["0.0.0.0/0"]
    action     = "allow"
  },
]
```

### Important Note on `firewall_ingress_cidr`

By default, the `firewall_ingress_cidr` variable is set to `["0.0.0.0/0"]`, which allows any IP to connect. For security reasons, you might want to limit the IP range that can connect to your database.

Options include:
- Setting it to your local network only.
- Setting it to the public IP of a specific instance or set of instances.
- Using a VPN or private network CIDR.

Adjust this variable to suit your specific security requirements.

## Outputs

- `database_password`: The password for the created database. (Sensitive)
- `dns_endpoint`: The DNS endpoint for the created database.
- `module_enabled`: Indicates if the module is enabled or not.

