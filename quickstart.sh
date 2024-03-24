#!/bin/bash

# Check if Terraform is installed and echo link to installation instructions if not
if ! [ -x "$(command -v terraform)" ]; then
    echo "Error: Terraform is not installed. Please install Terraform before running this script."
    echo "Installation instructions: https://learn.hashicorp.com/tutorials/terraform/install-cli"
    exit 1
fi

# Prompt explaining the script's action
echo "This script will prompt you to either initialize the Terraform working directory, create a Terraform plan, apply the Terraform plan, or destroy the Terraform-managed infrastructure."
echo "Please select an option: (i = initialize, p = plan, a = apply, d = destroy, c = exit)"

# Read the user's input for the selected option
read option

# Check if the user wants to exit
if [ "${option}" == "c" ]; then
    echo "Exiting..."
    exit 0
fi

# Check if the user wants to destroy the infrastructure
if [ "${option}" == "d" ]; then
    echo "This script will immediately destroy the Terraform-managed infrastructure."
    echo "This is not reversable. Are you sure you want to proceed? (yes/no)"
    read confirmation
    if [ "${confirmation}" != "yes" ]; then
        echo "Aborted."
        exit 1
    fi
    echo "Destroying the Terraform-managed infrastructure..."
    terraform destroy
    exit 0
fi

# Check the user's input and run the corresponding script
if [ "${option}" == "i" ]; then
    # Initialize the Terraform working directory
    echo "Initializing the Terraform working directory..."
    terraform init
    # Check if the initialization was successful
    if [ $? -eq 0 ]; then
        echo "Initialization successful."
    else
        echo "Initialization failed. Please check the error message above."
    fi
    # If initialization was successful, ask if they want to create a plan
    if [ $? -eq 0 ]; then
        echo "Do you want to create a Terraform plan? (yes/no)"
        read create_plan
        if [ "${create_plan}" == "yes" ]; then
            echo "Creating a Terraform plan..."
            terraform plan -out=plan.out
            # ask if they want to apply the plan
            echo "Do you want to apply the plan? This will immediately apply the plan."
            echo "Ensure you have reviewed the plan before applying. (yes/no)"
            read apply_plan
            if [ "${apply_plan}" == "yes" ]; then
                echo "Applying the Terraform plan..."
                terraform apply plan.out
                # Clean up the plan file
                rm plan.out
            else
                echo "Plan created but not applied. To apply the plan, run this script again and select 'a'."
            fi
        fi
    fi
elif [ "${option}" == "p" ]; then
    # Create a Terraform plan
    echo "Creating a Terraform plan..."
    terraform plan -out=plan.out
    # Ask if they want to apply the plan
    echo "Do you want to apply the plan? This will immediately apply the plan."
    echo "Ensure you have reviewed the plan before applying. (yes/no)"
    read apply_plan
    if [ "${apply_plan}" == "yes" ]; then
        echo "Applying the Terraform plan..."
        terraform apply plan.out
        # Clean up the plan file
        rm plan.out
    else
        echo "Plan created but not applied. To apply the plan, run this script again and select 'a'."
    fi
elif [ "${option}" == "a" ]; then
    # Apply the Terraform plan but prompt the user to confirm
    echo "This script will immediately apply the Terraform plan produced by the tfplan.sh script. If you have made any changes since running tfplan.sh, you should run tfplan.sh again before running this script."
    echo "Are you sure you want to proceed? (yes/no)"
    read confirmation
    if [ "${confirmation}" != "yes" ]; then
        echo "Aborted."
        exit 1
    fi
    echo "Applying the Terraform plan..."
    terraform apply plan.out
    # Clean up the plan file
    rm plan.out
else
    # Invalid input
    echo "Invalid option. Please select 'i' to initialize, 'p' to plan, or 'a' to apply."
    exit 1
fi

