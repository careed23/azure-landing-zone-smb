#!/bin/bash

# Default values
ENVIRONMENT="dev"
LOCATION="eastus"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -e|--env) ENVIRONMENT="$2"; shift ;;
        -l|--location) LOCATION="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

RG_NAME="rg-smb-landingzone-${ENVIRONMENT}-${LOCATION}"

echo "⚠️ WARNING: You are about to delete the Resource Group: $RG_NAME and ALL resources inside it."
read -p "Are you sure you want to proceed? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Preflight Check: Ensure user is logged into Azure CLI
    if ! az account show > /dev/null 2>&1; then
        echo "❌ Error: You are not logged into Azure CLI. Please run 'az login' first."
        exit 1
    fi

    echo "🗑️ Deleting Resource Group: $RG_NAME. This may take several minutes..."
    az group delete --name "$RG_NAME" --yes --no-wait
    echo "✅ Teardown initiated. Resources are being deleted in the background."
else
    echo "❌ Cleanup canceled."
fi