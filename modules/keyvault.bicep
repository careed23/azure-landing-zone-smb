@description('Azure region for the deployment')
param location string

@description('Environment prefix (e.g., dev, prod)')
param environment string

@description('Mandatory tags to apply to all resources')
param requiredTags object

@description('Log Analytics Workspace ID for diagnostic settings')
param logAnalyticsWorkspaceId string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${environment}-${substring(uniqueString(resourceGroup().id), 0, 5)}'
  location: location
  tags: requiredTags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
  }
}

resource kvDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-kv'
  scope: keyVault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
