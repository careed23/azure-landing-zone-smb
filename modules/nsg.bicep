@description('Azure region for the deployment')
param location string

@description('Environment prefix (e.g., dev, prod)')
param environment string

@description('Name of the Subnet or Tier (e.g., app, db, mgmt)')
param tierName string

@description('Mandatory tags to apply to all resources')
param requiredTags object

@description('ID of the Log Analytics Workspace for Diagnostic Settings')
param logAnalyticsWorkspaceId string

@description('Array of custom security rules to apply to the NSG')
param customSecurityRules array = []

// CAF Naming Convention: nsg-<tier>-<env>-<region>
var nsgName = 'nsg-${tierName}-${environment}-${location}'

// [SECURITY RATIONALE] We construct the NSG with explicit rules first, followed by a Catch-All Deny.
// By default, Azure NSGs allow VNet-inbound. For a zero-trust model, we explicitly deny all inbound 
// traffic at priority 4096. All required traffic must be explicitly allowed via customSecurityRules.
var denyAllInboundRule = {
  name: 'DenyAllInbound'
  properties: {
    priority: 4096
    access: 'Deny'
    direction: 'Inbound'
    protocol: '*'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '*'
  }
}

// Concatenate custom rules with our mandatory explicit deny rule
var finalSecurityRules = concat(customSecurityRules, [denyAllInboundRule])

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: nsgName
  location: location
  tags: requiredTags
  properties: {
    securityRules: finalSecurityRules
  }
}

// [SECURITY RATIONALE] Send all NSG flow logs and diagnostic events to Log Analytics
// to enable anomaly detection and auditing of denied network flows.
resource nsgDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${nsgName}'
  scope: nsg
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

output nsgId string = nsg.id
output nsgName string = nsg.name