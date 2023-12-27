#!/bin/bash

set -e

# Function to ensure a command exists
ensure_command() {
    if ! command -v $1 &> /dev/null
    then
        echo "Error: $1 is not installed. Exiting."
        exit 1
    fi
}

# Ensure necessary commands are available
ensure_command curl
ensure_command gpg
ensure_command lsb_release
ensure_command apt-get

add_microsoft_repo() {
    echo "Adding Microsoft package repository..."

    # Add the Microsoft package signing key
    curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null

    # Add the Azure CLI software repository
    AZ_REPO=$(lsb_release -cs)
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list

    # Update package lists
    sudo apt-get update
}

install_azure_cli() {
    echo "Installing Azure CLI..."
    sudo apt-get install -y azure-cli
}

verify_installation() {
    echo "Verifying Azure CLI installation..."
    az --version
}

# Main execution
if [ "$EUID" -ne 0 ]
    then echo "Please run as root or use sudo"
    exit
fi

add_microsoft_repo
install_azure_cli
verify_installation

echo "Azure CLI installation completed successfully."
