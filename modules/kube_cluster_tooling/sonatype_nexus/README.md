# Sonatype Nexus Terraform Module

This module deploys a Sonatype Nexus Repository Manager and Sonatype Nexus IQ Server into a Kubernetes cluster using Helm. The module supports both development and production environments and can use both in-cluster and external PostgreSQL databases.

## Prerequisites

- Terraform v0.14 or later
- Kubernetes Cluster (v1.18+ recommended)
- Helm v3
- kubectl
- Terraform Providers:
  - Kubernetes Provider v2.22.0
  - Helm Provider v2.10.1
  - Kubectl Provider v1.14.0
  - Local Provider v2.4.0
  - Random Provider v3.5.1

## Providers

- `kubernetes`: Configuration for the Kubernetes cluster where Sonatype Nexus will be deployed.
- `helm`: Helm provider configuration.
- `kubectl`: Configuration for kubectl, to be used for Kubernetes operations not supported by the Kubernetes or Helm providers.
- `local`: Provider used to generate sensitive local files.
- `random`: Provider used to generate random strings for secure credentials.

## Module Input Variables

- `environment`: The deployment environment (development or production).
- `nxrm_chart_version`: The version of the Sonatype Nexus to be deployed.
- `nexus_license_file`: The path to the Sonatype Nexus license file.
- `db_name`: The name of the database to be created.
- `postgresql_version`: The version of the PostgreSQL to be deployed.
- `postgresql_username`: The username for the PostgreSQL.
- `outputs_path`: The path to the outputs folder.
- `dns_domain`: The DNS domain to be used for the setup.
- `ingress_class_name`: The Ingress Class Name.
- `prod_db_host`: The host of the external database for the production environment. (Optional, default: "")
- `prod_db_username`: The username for the external database for the production environment. (Optional, default: "")
- `prod_db_password`: The password for the external database for the production environment. (Sensitive, Optional, default: "")
- `prod_db_name`: The name of the external database for the production environment. (Optional, default: "")
- `iq_server_chart_version`: The version of the Sonatype Nexus IQ Server Chart to be deployed.
- `module_enabled`: Enable Nexus Repository Manager deployment
- `iq_server_enabled`: Enable IQ Server deployment
- `nxrm_docker_registry_enabled`: Enable a self hosted docker registry inside of Nexus Repository Manager

## Module Outputs

- `postgresql_service_name`: Name of the PostgreSQL service.

## Usage

```hcl
module "nexus" {
  source             = "git::https://github.com/example/nexus.git"
  module_enabled    = true// if true, nexus helm chart is installed
  iq_server_enabled = true // if true, iq server helm chart is installed
  nxrm_docker_registroy_enabled = true // creates docker registry in nxrm deployment
  environment        = "production"
  nxrm_chart_version       = "3.38.0"
  nexus_license_file = "./license.lic" // set null if no license
  db_name            = "nexusdb"
  postgresql_version = "12.6.5"
  postgresql_username = "admin"
  outputs_path       = "./output"
  dns_domain         = "example.com"
  ingress_class_name = "traefik"
  prod_db_host       = "prod-db.example.com"
  prod_db_username   = "prod_db_user"
  prod_db_password   = "prod_db_password"
  prod_db_name       = "prod_db_name"
  iq_server_chart_version  = "165.0.0"
}
```

## Note

This module creates a random password for PostgreSQL and the Nexus IQ admin account. These passwords are stored in sensitive local files in the specified outputs path. Please ensure this path is secure.
