#!/bin/bash

echo "Select the operation to perform:"
echo "1. Manage Terraform infrastructure"
echo "2. Merge kubeconfig files"
echo "Enter your choice (1 or 2):"

read operation

case $operation in
    1)
        # Check if Terraform is installed
        if ! [ -x "$(command -v terraform)" ]; then
            echo "Error: Terraform is not installed. Please install Terraform before running this script."
            echo "Installation instructions: https://learn.hashicorp.com/tutorials/terraform/install-cli"
            exit 1
        fi

        echo "This script will prompt you to either initialize the Terraform working directory, create a Terraform plan, apply the Terraform plan, or destroy the Terraform-managed infrastructure."
        echo "Please select an option: (i = initialize, p = plan, a = apply, d = destroy, c = exit)"

        read option

        if [ "${option}" == "c" ]; then
            echo "Exiting..."
            exit 0
        fi

        case $option in
            d)
                echo "This script will immediately destroy the Terraform-managed infrastructure."
                echo "This is not reversable. Are you sure you want to proceed? (yes/no)"
                read confirmation
                if [ "${confirmation}" != "yes" ]; then
                    echo "Aborted."
                    exit 1
                fi
                echo "Destroying the Terraform-managed infrastructure..."
                # Remove the Helm releases from the Terraform state to avoid errors during destroy of clusters
                terraform state rm module.civo-cloud-native.module.rancher.helm_release.rancher
                terraform state rm module.civo-cloud-native.module.neuvector.helm_release.neuvector
                terraform state rm module.civo-cloud-native.module.argo.helm_release.argo_cd
                terraform state rm module.civo-cloud-native.module.argo.helm_release.argo_workflows
                terraform state rm module.civo-cloud-native.module.argo.helm_release.argo_events
                terraform state rm module.civo-cloud-native.module.kube_loadbalancer.helm_release.traefik_ingress_controller
                terraform state rm module.civo-cloud-native.module.kube_loadbalancer.helm_release.cert-manager
                terraform state rm module.civo-cloud-native.module.longhorn.helm_release.longhorn
                terraform state rm module.civo-cloud-native.module.longhorn.kubernetes_namespace.longhorn
                terraform destroy
                ;;
            i)
                echo "Initializing the Terraform working directory..."
                terraform init
                if [ $? -eq 0 ]; then
                    echo "Initialization successful. Do you want to create a Terraform plan? (yes/no)"
                    read create_plan
                    if [ "${create_plan}" == "yes" ]; then
                        echo "Creating a Terraform plan..."
                        terraform plan -out=plan.out
                        echo "Do you want to apply the plan? (yes/no)"
                        read apply_plan
                        if [ "${apply_plan}" == "yes" ]; then
                            echo "Applying the Terraform plan..."
                            terraform apply plan.out
                            rm plan.out
                        else
                            echo "Plan created but not applied."
                        fi
                    fi
                else
                    echo "Initialization failed. Please check the error message above."
                fi
                ;;
            p)
                echo "Creating a Terraform plan..."
                terraform plan -out=plan.out
                echo "Do you want to apply the plan? (yes/no)"
                read apply_plan
                if [ "${apply_plan}" == "yes" ]; then
                    echo "Applying the Terraform plan..."
                    terraform apply plan.out
                    rm plan.out
                else
                    echo "Plan created but not applied."
                fi
                ;;
            a)
                echo "Applying the Terraform plan..."
                terraform apply plan.out
                rm plan.out
                ;;
            *)
                echo "Invalid option."
                exit 1
                ;;
        esac
        ;;
    2)
        echo "This script will merge kubeconfig from a source file into your default kubeconfig file."
        echo "This operation requires a kubeconfig file in the following location: ./artifacts/output_files/kubeconfig.yaml"
        echo "Are you sure you want to proceed? (yes/no)"

        read confirmation

        if [ "${confirmation}" != "yes" ]; then
            echo "Aborted."
            exit 1
        fi

        SOURCE_KUBECONFIG="./artifacts/output_files/kubeconfig.yaml"
        DEST_KUBECONFIG="${HOME}/.kube/config"

        if [ ! -f "${SOURCE_KUBECONFIG}" ]; then
            echo "Source kubeconfig ${SOURCE_KUBECONFIG} does not exist."
            exit 1
        fi

        if [ ! -f "${DEST_KUBECONFIG}" ]; then
            cp "${SOURCE_KUBECONFIG}" "${DEST_KUBECONFIG}"
        else
            cp "${DEST_KUBECONFIG}" "${DEST_KUBECONFIG}.backup.$(date +%Y%m%d%H%M%S)"
            KUBECONFIG="${DEST_KUBECONFIG}:${SOURCE_KUBECONFIG}" kubectl config view --flatten > "${DEST_KUBECONFIG}.tmp"
            mv "${DEST_KUBECONFIG}.tmp" "${DEST_KUBECONFIG}"
        fi

        echo "Merged kubeconfig from ${SOURCE_KUBECONFIG} into ${DEST_KUBECONFIG}"
        ;;
    *)
        echo "Invalid selection."
        exit 1
        ;;
esac
