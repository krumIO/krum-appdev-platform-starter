
# Terraform Deployment on Civo Cloud

This repository includes Terraform code to deploy a Kubernetes cluster on Civo Cloud and install various Kubernetes resources on the cluster. 

The resources include the following:

- A Kubernetes cluster and network in Civo Cloud
- A Kubernetes config file
- A load balancer
- Rancher admin credentials
- Traefik dashboard credentials
- Various other Kubernetes resources, including a deployment of Traefik as an ingress controller

The deployment is divided into two phases:

1. Deploy the Civo Cloud resources, including the Kubernetes cluster, network, and a local kubeconfig file.
2. Deploy Kubernetes resources on the cluster, using the kubeconfig file from phase 1.

The reason for this two-phase deployment is that many of the Kubernetes resources rely on the Kubernetes cluster and kubeconfig file created in the first phase. We need to ensure that the Kubernetes cluster is fully provisioned and the kubeconfig file is created before we can start deploying the Kubernetes resources in phase 2.

## Prerequisites

You need to have Terraform installed and configured to use the Civo provider. See the Terraform and Civo provider documentation for details.

In addition, you need to provide the following variables:

- `civo_region`: The Civo region to deploy the resources, for example "PHX1".
- `civo_token`: Your Civo API token.
- `email`: Your email address, which is used for Let's Encrypt certificates.

If you're deploying a database module, you'll also need to provide:

- `db_name`: The name of your database.
- `db_node_count`: The number of nodes for your database.

## Usage

Clone this repository and navigate to the directory:

```bash
git clone https://github.com/krumIO/krum-appdev-platform-starter.git
cd ./krum-appdev-platform-starter
```

Initialize your Terraform workspace, which will download the provider plugins:

```bash
terraform init
```

There are two phases to the deployment:

1. Deploy the Civo Cloud resources, including the Kubernetes cluster, network, and a local kubeconfig file.
2. Deploy Kubernetes resources on the cluster, using the kubeconfig file from phase 1.

### Phase 1

Run the following command:

```bash
terraform apply -target=module.civo_sandbox_cluster -target=module.civo_sandbox_cluster_network
```

This will prompt you to confirm the changes. Type `yes` and press Enter to confirm.

### Phase 2

Before starting phase 2, ensure that the Kubernetes API server is accessible and the nodes are ready. You can check this by running `kubectl cluster-info` and `kubectl get nodes`. Once the API server is accessible and the nodes are ready, run the following command:

```bash
terraform apply
```

This will prompt you to confirm the changes. Type `yes` and press Enter to confirm.

## Clean Up

When you're done with the resources, you can destroy them by running `terraform destroy`. This will prompt you to confirm the changes. Type `yes` and press Enter to confirm.

---