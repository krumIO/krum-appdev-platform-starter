# Terraform Script Readme

This script helps set up a Kubernetes cluster using the Civo provider, as well as deploy various tools on the cluster like Traefik Ingress Controller, Cert Manager, Rancher, Argo suite, Sonatype Nexus and IQ Server with PostgreSQL database. The script also handles the creation of required network and database resources.

## Prerequisites

- Terraform v0.13+ installed.
- Civo API token.
- Kubernetes CLI and Helm CLI installed.
- Access to an active Civo region.
- Active email for letsencrypt.

## Providers and Modules

This script uses the following Terraform providers:

- Civo
- Kubernetes
- Helm
- Kubectl
- Local
- Random

## Variables

You should create a `terraform.tfvars` file in the same directory as your `.tf` files. Here's an example:

```hcl
civo_token                 = "your_civo_api_token"
civo_region                = "NYC1"
email                      = "your_email_for_letsencrypt"
nexus_license_file_path    = null // "path_to_your_nexus_license_file_or_null"
db_name                    = "nxrmdb"
db_node_count              = 1
```

## Steps

1. **Clone the repository**

    Clone the repository to your local system with the following command:

    ```bash
    git clone https://github.com/krumIO/krum-appdev-platform-starter.git
    ```

2. **Navigate to the project directory**

    Change your directory to the project directory:

    ```bash
    cd ./krum-appdev-platform-starter
    ```


3. **Initialize Terraform**

    Initialize your Terraform workspace, which will download the provider plugins for Civo, Kubernetes, Helm, Kubectl, Local, and Random.

    ```bash
    terraform init
    ```

4. **Plan and apply**

    In order to see any changes that are required for your infrastructure, use:

    ```bash
    terraform plan
    ```

    To apply changes to the infrastructure, use:

    ```bash
    terraform apply
    ```

    Terraform will show the plan and prompt for approval. If everything looks good, approve the plan and Terraform will make the necessary changes.

## Cleanup

When you're done with the infrastructure created by this script, you can remove all resources by using the `destroy` command. This will delete all resources that Terraform has created.

```bash
terraform destroy
```

Terraform will show the plan for destruction and prompt for approval. If you agree with the plan, approve it and Terraform will destroy all the resources.

After running `terraform destroy`, you may want to delete the `.terraform` directory and `terraform.tfstate` files to fully clean up your local workspace.

```bash
rm -rf .terraform terraform.tfstate terraform.tfstate.backup
```

## Important Note

This script uses sensitive data. Never expose your `terraform.tfvars` file, as it contains sensitive information like your Civo API token, email, and potentially other secrets. Always add your `*.tfvars` file to your `.gitignore` to prevent committing it to version control.

The `terraform.tfstate` and `terraform.tfstate.backup` files contain sensitive data. It's recommended to store the state file in a secure and backed-up location or to use a remote state backend. Always add your `*.tfstate*` files to your `.gitignore` to prevent committing it to version control.
