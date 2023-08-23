#!/bin/bash

# Prompt explaining the script's action
echo "This script will merge kubeconfig from a source file into your default kubeconfig file."
echo "If the default kubeconfig already exists, it will be backed up with a timestamp."
echo "Are you sure you want to proceed? (yes/no)"

# Read the user's input for confirmation
read confirmation

# Check if the user's input is "yes" to proceed
if [ "${confirmation}" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

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
