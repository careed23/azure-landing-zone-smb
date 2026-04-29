# Implementation Guide

This guide provides step-by-step instructions for deploying the SMB Azure Landing Zone to your Azure Subscription.

## Prerequisites

1. **Azure CLI:** Ensure the [Azure CLI is installed](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli).
2. **Bicep CLI:** Ensure [Bicep is installed](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install) (`az bicep install`).
3. **Permissions:** You must have `Owner` or `Contributor` + `User Access Administrator` rights on the subscription to assign RBAC roles and deploy resources.

## 1. Authentication

Log in to Azure and set your target subscription:

```bash
az login
az account list --output table
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
```

## 2. Validation / Preflight Check

Before deploying, run a `what-if` analysis to see exactly what Bicep will create, modify, or delete.

```bash
az group create --name rg-smb-landingzone-dev-eastus --location eastus

az deployment group what-if \
  --resource-group rg-smb-landingzone-dev-eastus \
  --template-file main.bicep \
  --parameters @parameters/dev.parameters.json
```
*Review the output carefully to ensure it aligns with your expectations.*

## 3. Execution (Using Bash Scripts)

For convenience, we have provided a deployment shell script that handles resource group creation and deployment orchestration.

Make the script executable (Mac/Linux):
```bash
chmod +x scripts/deploy.sh
```

Execute the deployment for the `dev` environment:
```bash
./scripts/deploy.sh --env dev --location eastus
```

### Alternative: Manual Deployment

If you are on Windows or prefer not to use the script:
```bash
az deployment group create \
  --name "smb-landing-zone-deployment" \
  --resource-group rg-smb-landingzone-dev-eastus \
  --template-file main.bicep \
  --parameters @parameters/dev.parameters.json
```

## 4. Post-Deployment Validation

Once the deployment completes, verify the following in the Azure Portal:
1. **Azure Policy:** Navigate to *Policy > Compliance* to verify the `Audit Allowed Locations` and `Audit Required Tag` policies are active.
2. **Virtual Networks:** Navigate to the Hub VNet and select *Peerings*. You should see `Connected` status for the Spoke VNet.
3. **Log Analytics:** Navigate to the Log Analytics Workspace. Under *Logs*, run a query for `AzureActivity` or `AzureDiagnostics` to confirm telemetry is flowing.

## 5. Clean Up (Teardown)

To safely tear down the environment and prevent ongoing billing, use the cleanup script:

```bash
chmod +x scripts/cleanup.sh
./scripts/cleanup.sh --env dev --location eastus