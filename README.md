
# Civo Kubernetes Deployment with Terraform

## Overview

This repository contains Terraform modules for deploying and managing a Kubernetes cluster on Civo Cloud, along with optional cloud-native tooling such as Rancher, Argo Suite, Sonatype Nexus, and more. The repository is structured with various sub-modules, each serving a distinct purpose.

## Directory Structure

- `./common/civo-cloud-native/`: The primary Terraform module that orchestrates the Kubernetes cluster creation, firewall configuration, VPC setup, and optional tool installations. For detailed configuration options, refer to its [README](./common/civo-cloud-native/README.md).

- `./modules/`: Holds smaller, more focused Terraform modules that the primary module calls. These manage the deployments of individual components like databases, ingress controllers, etc.

- `./artifacts/input_files/`: This directory is for placing any special files required by modules, such as a `.lic` file for software licenses.

- `./artifacts/output_files/`: Post-deployment, this directory will contain key outputs like Rancher's URL, kubeconfig, and any randomly generated passwords.

## Requirements

- Terraform v1.x
- Civo API Token
- `kubectl` installed (if interacting with Kubernetes)

## Configuration

### Using `terraform.tfvars.example`

An example `terraform.tfvars.example` file is provided in the main directory for your reference. This file includes example configurations for required variables:

```hcl
// Civo resources
civo_region = "LON1" //required
civo_token  = ""     //required

// For Cert Manager SSL Certificates via LetsEncrypt
# must be a valid email address
email = "email@example.com" //required
```

Copy this file to `terraform.tfvars` and fill in your specific values before running `terraform apply`.

### Special Input Files

If any module requires special files like a `.lic` license file, place these in the `./artifacts/input_files/` directory.

### Outputs

Upon successful Terraform apply, key outputs such as the Rancher URL, kubeconfig, and any randomly generated passwords will be stored in `./artifacts/output_files/`.

## Quick Start

1. **Clone the Repository**
    ```sh
    git clone https://github.com/krumIO/krum-appdev-platform-starter.git
    ```

2. **Navigate to Main Directory**
    ```sh
    cd krum-appdev-platform-starter
    ```

3. **Initialize Terraform**
    ```sh
    terraform init
    ```

4. **Apply Configuration**
    ```sh
    terraform apply
    ```

## Documentation

For more details, please consult the README files within each sub-directory:

- [Civo Cloud Native Module](./common/civo-cloud-native/README.md)
- [Individual Component Modules](./modules/README.md)

## Advanced Usage: Merging kubeconfig Files

### About the Script

The included bash script, let's call it `merge-kubeconfig.sh`, allows you to merge the kubeconfig file generated by the Kubernetes cluster deployment into your existing kubeconfig file located at `${HOME}/.kube/config`.

This is particularly useful when:

- You are managing multiple Kubernetes clusters and would like a single point of configuration for `kubectl`.
- You are switching between different clusters often and need a quick way to update your kubeconfig.

### What Does The Script Do?

Here's a step-by-step explanation of what the script does:

1. **Prompt for Confirmation**: The script starts by explaining what it is about to do and asks for your confirmation to proceed.

2. **Check User Confirmation**: If you do not confirm with "yes," the script will abort.

3. **Check Source File**: The script checks if the source kubeconfig file, usually located in `./artifacts/output_files/kubeconfig.yaml`, exists. If not, it aborts.

4. **Check Destination File**: It checks if a kubeconfig file already exists in your home directory under `~/.kube/config`.

    - **If Not**: It simply copies the source kubeconfig to this location.
    
    - **If Yes**: It performs the following steps:
    
        a. **Backup Existing kubeconfig**: It backs up your existing kubeconfig file, appending a timestamp to the backup filename.
        
        b. **Merge Configurations**: It uses `kubectl` to merge the source and destination kubeconfig files.
        
        c. **Replace Old Config**: It then replaces the existing kubeconfig file with the newly merged one.

5. **Completion Message**: Finally, a message is displayed indicating that the kubeconfig files have been merged.

### How to Use The Script

1. Make the script executable:

    ```bash
    chmod +x merge-kubeconfig.sh
    ```

2. Run the script:

    ```bash
    ./merge-kubeconfig.sh
    ```

Please proceed with caution and ensure you understand the implications of running this script, as it will modify your existing kubeconfig file.



## Contributing

Contributions to improve or extend this project are welcome. Please open an issue or submit a pull request for any contributions.




