
# Civo DNS Domain Name Module

This module manages a domain name in the [Civo DNS service](https://www.civo.com/), which uses the Civo Terraform provider.

## Requirements

- Terraform 1.0 or newer.
- Civo API token

## Usage

Here is an example of how you might use this module in your own Terraform code:

```hcl
module "civo_dns_domain_name" {
  source = "path/to/module"

  domain_name = "example.com"
}
```

Then, run `terraform init` and `terraform apply`.

## Variables

- `domain_name`: (Required) The domain name you want to manage.

## Notes

Make sure to replace `"path/to/module"` with the actual path to this module in your code.

