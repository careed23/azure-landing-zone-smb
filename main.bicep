targetScope = 'resourceGroup'

@description('Azure region for the deployment')
param location string = resourceGroup().location

@description('Environment prefix (e.g., dev, prod)')
@allowed([
  'dev'
  'prod'
])
param environment string

@description('Cost Center for tagging')
param costCenter string

@description('Project Name for tagging')
param project string

@description('Toggles the deployment of Azure Firewall (Expensive!)')
param deployFirewall bool = false

@description('Toggles the deployment of Azure Bastion')
param deployBastion bool = false

@description('Toggles the deployment of VPN Gateway')
param deployVpnGateway bool = false

// Common Tags
var requiredTags = {
  Environment: environment
  Owner: 'IT Admin' // Or can be passed as a param
  CostCenter: costCenter
  Project: project
  ManagedBy: 'Bicep'
}

// 1. Governance / Policy
module policy 'modules/policy.bicep' = {
  name: 'deploy-policy'
  params: {
    location: location
  }
}

// 2. Log Analytics
module logAnalytics 'modules/log-analytics.bicep' = {
  name: 'deploy-log-analytics'
  params: {
    location: location
    environment: environment
    requiredTags: requiredTags
    retentionInDays: 30
  }
}

// 3. Hub VNet & Firewall
module hubVnet 'modules/hub-vnet.bicep' = {
  name: 'deploy-hub-vnet'
  params: {
    location: location
    environment: environment
    requiredTags: requiredTags
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    deployFirewall: deployFirewall
    deployBastion: deployBastion
    deployVpnGateway: deployVpnGateway
  }
}

// 4. NSGs for Spokes
module nsgApp 'modules/nsg.bicep' = {
  name: 'deploy-nsg-app'
  params: {
    location: location
    environment: environment
    tierName: 'app'
    requiredTags: requiredTags
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    customSecurityRules: [
      {
        name: 'Allow-Http-Inbound'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
      {
        name: 'Allow-Https-Inbound'
        properties: {
          priority: 110
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
    ]
  }
}

module nsgDb 'modules/nsg.bicep' = {
  name: 'deploy-nsg-db'
  params: {
    location: location
    environment: environment
    tierName: 'db'
    requiredTags: requiredTags
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    customSecurityRules: [
      {
        name: 'Allow-Sql-From-App'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: '10.1.1.0/24' // App Subnet
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '1433'
        }
      }
    ]
  }
}

// 5. Spoke VNet (e.g., Production or Dev workload Spoke)
module spokeVnet 'modules/spoke-vnet.bicep' = {
  name: 'deploy-spoke-vnet'
  dependsOn: [
    hubVnet
  ]
  params: {
    location: location
    environment: environment
    spokeName: environment // Just using the environment name as the spoke name for simplicity
    spokeVnetAddressSpace: environment == 'prod' ? '10.1.0.0/16' : '10.2.0.0/16'
    hubVnetId: hubVnet.outputs.hubVnetId
    hubVnetName: hubVnet.outputs.hubVnetName
    firewallPrivateIp: deployFirewall ? hubVnet.outputs.firewallPrivateIp : '10.0.1.4'
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    requiredTags: requiredTags
    subnets: [
      {
        name: 'snet-app'
        addressPrefix: environment == 'prod' ? '10.1.1.0/24' : '10.2.1.0/24'
        nsgId: nsgApp.outputs.nsgId
      }
      {
        name: 'snet-db'
        addressPrefix: environment == 'prod' ? '10.1.2.0/24' : '10.2.2.0/24'
        nsgId: nsgDb.outputs.nsgId
      }
    ]
  }
}

// 6. RBAC Assignments (Placeholder for demonstration)
module rbac 'modules/rbac.bicep' = {
  name: 'deploy-rbac'
  params: {
    roleAssignments: [] // Array of assignments would go here based on Entra ID Object IDs
  }
}

// 7. Key Vault (Placeholder) & Diagnostics
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
    accessPolicies: []
    enableSoftDelete: true
  }
}

resource kvDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-kv'
  scope: keyVault
  properties: {
    workspaceId: logAnalytics.outputs.workspaceId
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

output hubVnetName string = hubVnet.outputs.hubVnetName
output spokeVnetName string = spokeVnet.outputs.spokeVnetName
output logAnalyticsWorkspaceId string = logAnalytics.outputs.workspaceId
