#!/bin/bash

# Source kubeconfig
SOURCE_KUBECONFIG="./artifacts/output_files/kubeconfig.yaml"
# Destination kubeconfig
DEST_KUBECONFIG="${HOME}/.kube/config"

# Check if the source file exists
if [ ! -f "${SOURCE_KUBECONFIG}" ]; then
    echo "Source kubeconfig ${SOURCE_KUBECONFIG} does not exist."
    exit 1
fi

# If the destination kubeconfig doesn't exist, simply copy the source to the destination
if [ ! -f "${DEST_KUBECONFIG}" ]; then
    cp "${SOURCE_KUBECONFIG}" "${DEST_KUBECONFIG}"
else
    # Backup the original destination kubeconfig
    cp "${DEST_KUBECONFIG}" "${DEST_KUBECONFIG}.backup.$(date +%Y%m%d%H%M%S)"
    
    # Use kubectl to merge the configs
    KUBECONFIG="${DEST_KUBECONFIG}:${SOURCE_KUBECONFIG}" kubectl config view --flatten > "${DEST_KUBECONFIG}.tmp"
    
    # Replace the old config with the merged one
    mv "${DEST_KUBECONFIG}.tmp" "${DEST_KUBECONFIG}"
fi

echo "Merged kubeconfig from ${SOURCE_KUBECONFIG} into ${DEST_KUBECONFIG}"
