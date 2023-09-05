
# Terraform Rancher Proxy Ingress Module

This Terraform module facilitates the creation of a Kubernetes Ingress resource that proxies a sensitive application through Rancher's proxy service. This allows the application to be secured with Rancher's login.

## Prerequisites

- Terraform 0.14+
- Kubernetes Cluster
- Kubectl
- Helm
- Cert-manager

## Features

- Creates a secure Ingress resource
- Configurable through variables
- Enabled/Disabled with a toggle

## Usage

Include this module in your `main.tf` file:

```hcl
module "rancher_proxy_ingress" {
  source = "<Your-Module-Source>"

  // ... set your variables here
}
```

## Input Variables

| Variable             | Type    | Default      | Description                             |
|----------------------|---------|--------------|-----------------------------------------|
| `protocol`           | string  | `http`       | Protocol for the service                |
| `service_name`       | string  | `rancher`    | Kubernetes service name                 |
| `service_port`       | number  | `80`         | Port the service listens on             |
| `namespace`          | string  | `cattle-system`| Namespace where the ingress will be created  |
| `dns_domain`         | string  | `sslip.io`   | DNS domain for the ingress              |
| `ingress_class_name` | string  | `traefik`    | Ingress class to use                    |
| `ingress_display_name`| string | `rancher`   | Display name for the ingress            |
| `tls_secret_name`    | string  | `tls-rancher-cert` | TLS Secret Name for the Ingress     |
| `module_enabled`     | bool    | `true`       | Enable or disable this module           |

## Example

```hcl
module "rancher_proxy_ingress" {
  source = "<Your-Module-Source>"
  
  protocol            = "https"
  service_name        = "my-service"
  service_port        = 443
  namespace           = "my-namespace"
  dns_domain          = "example.com"
  ingress_class_name  = "nginx"
  ingress_display_name = "my-ingress"
  tls_secret_name     = "my-tls-secret"
  module_enabled      = true
}
```
