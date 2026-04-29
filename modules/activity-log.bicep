targetScope = 'subscription'

@description('The Log Analytics Workspace ID to send Activity Logs to')
param logAnalyticsWorkspaceId string

// [SECURITY RATIONALE] Sending Subscription Activity Logs to Log Analytics 
// ensures all administrative actions (who created/deleted/modified resources) 
// are audited and retained for security forensics.
resource activityLogDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-subscription-activity-logs'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'Administrative'
        enabled: true
      }
      {
        category: 'Security'
        enabled: true
      }
      {
        category: 'ServiceHealth'
        enabled: true
      }
      {
        category: 'Alert'
        enabled: true
      }
      {
        category: 'Recommendation'
        enabled: true
      }
      {
        category: 'Policy'
        enabled: true
      }
      {
        category: 'Autoscale'
        enabled: true
      }
      {
        category: 'ResourceHealth'
        enabled: true
      }
    ]
  }
}