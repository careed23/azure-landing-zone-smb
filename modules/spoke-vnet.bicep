@description('Azure region for the deployment')
param location string

@description('Environment prefix (e.g., dev, prod)')
param environment string

@description('Name of the Spoke (e.g., prod, dev, mgmt)')
param spokeName string

@description('Address space for the Spoke VNet')
param spokeVnetAddressSpace string

@description('Array of subnet configurations for the Spoke')
param subnets array

@description('Mandatory tags to apply to all resources')
param requiredTags object

@description('Log Analytics Workspace ID for diagnostic settings')
param logAnalyticsWorkspaceId string

@description('ID of the Hub VNet for Peering')
param hubVnetId string

@description('Name of the Hub VNet for Peering')
param hubVnetName string

@description('Private IP of the Azure Firewall in the Hub for routing')
param firewallPrivateIp string

// CAF Naming
var vnetName = 'vnet-spoke-${spokeName}-${environment}-${location}'
var routeTableName = 'rt-spoke-${spokeName}-${environment}-${location}'

// [SECURITY RATIONALE] We force all Outbound (0.0.0.0/0) traffic from the Spoke to go through 
// the Hub's Azure Firewall for deep packet inspection and logging (Zero Trust architecture).
resource routeTable 'Microsoft.Network/routeTables@2023-09-01' = if (!empty(firewallPrivateIp)) {
  name: routeTableName
  location: location
  tags: requiredTags
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'RouteToFirewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

// Map the provided subnets to include the route table and NSG
var mappedSubnets = [for subnet in subnets: {
  name: subnet.name
  properties: {
    addressPrefix: subnet.addressPrefix
    networkSecurityGroup: {
      id: subnet.nsgId
    }
    routeTable: if (!empty(firewallPrivateIp)) {
      id: routeTable.id
    }
  }
}]

resource spokeVnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  tags: requiredTags
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokeVnetAddressSpace
      ]
    }
    subnets: mappedSubnets
  }
}

// Diagnostics for Spoke VNet
resource vnetDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${vnetName}'
  scope: spokeVnet
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

// --- VNET PEERING ---

// Spoke to Hub Peering
resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  parent: spokeVnet
  name: 'peering-${spokeName}-to-hub'
  properties: {
    remoteVirtualNetwork: {
      id: hubVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

// Hub to Spoke Peering
// Reference the existing Hub VNet to configure the peering back to this spoke
resource existingHubVnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: hubVnetName
}

resource hubToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  parent: existingHubVnet
  name: 'peering-hub-to-${spokeName}'
  properties: {
    remoteVirtualNetwork: {
      id: spokeVnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true // Allow spoke to use hub's gateway if present
    useRemoteGateways: false
  }
}

output spokeVnetId string = spokeVnet.id
output spokeVnetName string = spokeVnet.name