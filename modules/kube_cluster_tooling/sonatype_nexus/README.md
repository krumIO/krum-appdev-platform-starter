# Sonatype Nexus Terraform Module

This Terraform module deploys Sonatype Nexus into a Kubernetes cluster with optional support for PostgreSQL Database, conditional on the environment. It uses the Sonatype Nexus Repository Manager Helm chart and optionally the Bitnami PostgreSQL Helm chart for development environments.

## Prerequisites

- Kubernetes cluster
- Helm
- Terraform 0.13+

## Providers

- kubernetes
- helm
- kubectl
- local
- random

## Inputs

- `environment`: The deployment environment (development or production).
- `nxrm_version`: The version of the Sonatype Nexus to be deployed.
- `nexus_license_file`: The path to the Sonatype Nexus license file.
- `db_name`: The name of the database to be created.
- `postgresql_version`: The version of the PostgreSQL to be deployed.
- `postgresql_username`: The username for the PostgreSQL.
- `outputs_path`: The path to the outputs folder.
- `dns_domain`: The DNS domain to be used for the setup.
- `ingress_class_name`: The Ingress Class Name.
- `prod_db_host`: The host of the external database for the production environment.
- `prod_db_username`: The username for the external database for the production environment.
- `prod_db_password`: The password for the external database for the production environment.
- `prod_db_name`: The name of the external database for the production environment.

## Outputs

- `postgresql_service_name`: The name of the PostgreSQL service for the development environment.

## Usage

In the development environment, the PostgreSQL is automatically deployed. In the production environment, database information needs to be supplied as variables.

## Additional Information

The secret for Nexus is automatically created and mounted into the correct path. Nexus then picks up the license file from the secret. The module automatically encodes the Nexus license file as base64.

## Contributing

For any changes, please raise a pull request.

## License

Apache 2.0

## Disclaimer

This module is not developed or supported by Sonatype or Bitnami. Use it at your own risk.