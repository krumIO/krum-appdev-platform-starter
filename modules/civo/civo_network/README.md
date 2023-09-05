# Terraform Civo Network Module

This Terraform module allows you to create a custom network in Civo Cloud. You can enable or disable the creation of the network using the `module_enabled` variable.

## Dependencies

- Civo Terraform Provider v1.0.35 or newer

## Usage

Here's an example of how to use this module in your Terraform project:

```hcl
module "civo_custom_network" {
  source = "./path/to/this/module"

  network_name    = "my-custom-network"
}
```

## Variables

| Variable Name    | Description                | Type   | Default Value | Required |
|------------------|----------------------------|--------|---------------|----------|
| `network_name`   | Name of the custom network | string |               | Yes      |
| `module_enabled` | Is module enabled          | bool   | `true`        | No       |

## Outputs

- `network_id`: The ID of the created custom network.

