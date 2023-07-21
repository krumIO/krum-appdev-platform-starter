# Civo Reserved IP Module

This module reserves an IP address in the [Civo cloud](https://www.civo.com/), which uses the Civo Terraform provider.

## Requirements

- Terraform 1.0 or newer.
- Civo API token

## Usage

Here is an example of how you might use this module in your own Terraform code:

```hcl
module "civo_reserved_ip" {
  source = "path/to/module"
  name   = "my_reserved_ip"
}
```

Then, run `terraform init` and `terraform apply`.

## Variables

- `name`: (Required) The name for the reserved IP.

## Outputs

- `ip`: The IP address of the reserved resource.

## Notes

Make sure to replace `"path/to/module"` with the actual path to this module in your code.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[MIT](https://choosealicense.com/licenses/mit/)