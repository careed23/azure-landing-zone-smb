@description('Azure region for the deployment')
param location string

@description('Environment prefix (e.g., dev, prod)')
param environment string

@description('Mandatory tags to apply to all resources')
param requiredTags object

@description('Retention period in days for the logs')
param retentionInDays int = 30

// CAF Naming Convention for Log Analytics Workspace: log-<app>-<env>-<region>
var logAnalyticsName = 'log-landingzone-${environment}-${location}'

// [COST RATIONALE] We use the PerGB2018 (Pay-As-You-Go) pricing tier, which is the standard 
// and most cost-effective tier for SMBs unless they ingest >100GB/day where capacity tiers apply.
// [SECURITY RATIONALE] Centralizing logs ensures a single pane of glass for security auditing.
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: requiredTags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Output the ID for other modules (NSGs, Firewall, VNets) to configure diagnostic settings
output workspaceId string = logAnalyticsWorkspace.id
output workspaceName string = logAnalyticsWorkspace.name