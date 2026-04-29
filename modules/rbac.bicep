targetScope = 'resourceGroup'

@description('Array of objects containing principalId and roleDefinitionId')
param roleAssignments array = []

// Built-in Role Definition IDs
// Reader: acdd72a7-3385-48ef-bd42-f606fba81ae7
// Contributor: b24988ac-6180-42a0-ab88-20f7382dd24c
// Network Contributor: 4d97b98b-1d4f-4787-a291-c67834d212e7

// [SECURITY RATIONALE] Implementing Principle of Least Privilege (PoLP). 
// Instead of assigning Owner/Contributor at the Subscription level, we assign targeted roles 
// like Network Contributor or Reader at the Resource Group scope.
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in roleAssignments: {
  name: guid(resourceGroup().id, assignment.principalId, assignment.roleDefinitionId)
  properties: {
    principalId: assignment.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', assignment.roleDefinitionId)
    principalType: assignment.principalType // e.g., 'User', 'Group', 'ServicePrincipal'
  }
}]