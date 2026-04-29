targetScope = 'resourceGroup'

@description('Azure region for the deployment')
param location string

@description('Array of allowed locations')
param allowedLocations array = [
  'eastus'
  'eastus2'
  'centralus'
]

// Built-in Policy Definition IDs
// Allowed Locations: e56962a6-4747-49cd-b67b-bf8b01975c4c
var allowedLocationsPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c'

// Require a tag on resources: 871b6d14-10aa-478d-b590-94f262ecfa99
var requireTagPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99'

// [GOVERNANCE RATIONALE] Restrict deployments to approved regions to ensure data sovereignty,
// compliance, and predictable network latency for the SMB.
resource allowedLocationsAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'audit-allowed-locations'
  location: location
  properties: {
    displayName: 'Audit Allowed Locations'
    description: 'Audits if resources are deployed outside of the allowed regions.'
    policyDefinitionId: allowedLocationsPolicyId
    enforcementMode: 'Default'
    parameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
  }
}

// [GOVERNANCE RATIONALE] Mandatory tagging (e.g., Environment, Owner, CostCenter, Project)
// is critical for cost attribution and operational tracking. We audit these tags.
resource requireEnvironmentTagAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'audit-tag-environment'
  location: location
  properties: {
    displayName: 'Audit Required Tag: Environment'
    description: 'Audits if the Environment tag is missing on resources.'
    policyDefinitionId: requireTagPolicyId
    enforcementMode: 'Default'
    parameters: {
      tagName: {
        value: 'Environment'
      }
    }
  }
}

resource requireCostCenterTagAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'audit-tag-costcenter'
  location: location
  properties: {
    displayName: 'Audit Required Tag: CostCenter'
    description: 'Audits if the CostCenter tag is missing on resources.'
    policyDefinitionId: requireTagPolicyId
    enforcementMode: 'Default'
    parameters: {
      tagName: {
        value: 'CostCenter'
      }
    }
}
}