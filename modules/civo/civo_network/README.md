# Civo Network Module

This module manages a custom network in the [Civo cloud](https://www.civo.com/), which uses the Civo Terraform provider.

## Requirements

- Terraform 1.0 or newer.
- Civo API token

## Usage

Here is an example of how you might use this module in your own Terraform code:

```hcl
module "civo_network" {
  source = "path/to/module"
  network_name = "my_network"
}
```

Then, run `terraform init` and `terraform apply`.

## Variables

- `network_name`: (Required) The base name for the network to be created. A random suffix will be appended to ensure uniqueness.

## Outputs

- `network_id`: The ID of the created network.

## Notes

Make sure to replace `"path/to/module"` with the actual path to this module in your code.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[MIT](https://choosealicense.com/licenses/mit/)