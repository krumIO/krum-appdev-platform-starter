#!/bin/bash

# Function to run Terraform operations
run_terraform() {
    docker run -it --rm \
        -e TF_LOG=INFO \
        -v "$(pwd):/terraform" \
        -w /terraform \
        --entrypoint /bin/sh \
        hashicorp/terraform:1.8 \
        -c "$1"
}

# Check if an argument is provided
if [ $# -eq 0 ]; then
    echo "No arguments provided. Usage: $0 [-a|-d]"
    exit 1
fi

# Process the argument
case "$1" in
    -a)
        # Run Terraform apply
        run_terraform "terraform init && terraform plan -out=plan.tfout && terraform apply plan.tfout"

        # sleep 5

        # set -o allexport
        # source ./terraform/outputs/registration_command.env
        # set +o allexport

        # echo "$REGISTRATION_COMMAND"
        # echo "$MINION_ID"

        # # Run the registration command on the minion and apply the transaction to activate the new configuration
        # sudo salt --log-level=debug --module-executors='[direct_call]' "$MINION_ID" cmd.run "$REGISTRATION_COMMAND && transactional-update reboot" activate_transaction=True >> salt_command.log 2>&1
        ;;

    -d)
        # Run Terraform destroy
        run_terraform "terraform state rm module.civo-cloud-native.module.rancher.helm_release.rancher"
        run_terraform "terraform state rm module.civo-cloud-native.module.neuvector.helm_release.neuvector"
        run_terraform "terraform state rm module.civo-cloud-native.module.argo.helm_release.argo_cd"
        run_terraform "terraform state rm module.civo-cloud-native.module.argo.helm_release.argo_workflows"
        run_terraform "terraform state rm module.civo-cloud-native.module.argo.helm_release.argo_events"
        run_terraform "terraform state rm module.civo-cloud-native.module.kube_loadbalancer.helm_release.traefik_ingress_controller"
        run_terraform "terraform state rm module.civo-cloud-native.module.kube_loadbalancer.helm_release.cert-manager"
        run_terraform "terraform state rm module.civo-cloud-native.module.longhorn.helm_release.longhorn"
        run_terraform "terraform state rm module.civo-cloud-native.module.longhorn.kubernetes_namespace.longhorn"
        run_terraform "terraform destroy"
        ;;

    *)
        echo "Invalid option: $1. Use -a for apply or -d for destroy."
        exit 2
        ;;
esac