#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

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

echo "Starting Deployment for Environment: $ENVIRONMENT in Location: $LOCATION"

# Preflight Check: Ensure user is logged into Azure CLI
if ! az account show > /dev/null 2>&1; then
    echo "❌ Error: You are not logged into Azure CLI. Please run 'az login' first."
    exit 1
fi

# Preflight Check: Ensure parameter file exists
PARAM_FILE="parameters/${ENVIRONMENT}.parameters.json"
if [ ! -f "$PARAM_FILE" ]; then
    echo "❌ Error: Parameter file $PARAM_FILE does not exist."
    exit 1
fi

RG_NAME="rg-smb-landingzone-${ENVIRONMENT}-${LOCATION}"

echo "1️⃣ Creating Resource Group: $RG_NAME..."
az group create --name "$RG_NAME" --location "$LOCATION" -o none
echo "✅ Resource Group created successfully."

echo "2️⃣ Starting Bicep Deployment (Resource Group)..."
DEPLOYMENT_OUTPUT=$(az deployment group create \
  --name "deployment-${ENVIRONMENT}-$(date +%s)" \
  --resource-group "$RG_NAME" \
  --template-file main.bicep \
  --parameters "@${PARAM_FILE}" \
  --output json)

echo "✅ Resource Group Deployment completed successfully."

echo "3️⃣ Configuring Subscription Activity Log Diagnostics..."
# Retrieve the Log Analytics Workspace ID dynamically from the previous deployment outputs
WORKSPACE_ID=$(echo $DEPLOYMENT_OUTPUT | jq -r '.properties.outputs.logAnalyticsWorkspaceId.value')

if [ "$WORKSPACE_ID" != "null" ] && [ -n "$WORKSPACE_ID" ]; then
    az deployment sub create \
      --name "activity-log-diag-$(date +%s)" \
      --location "$LOCATION" \
      --template-file modules/activity-log.bicep \
      --parameters logAnalyticsWorkspaceId="$WORKSPACE_ID" \
      --output none
    echo "✅ Activity Log diagnostic settings configured successfully."
else
    echo "⚠️ Warning: Could not retrieve Log Analytics Workspace ID. Skipping Activity Log diagnostics."
fi

echo "✅ Full deployment completed successfully!"
