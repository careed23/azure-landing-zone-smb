@description('Azure region for the deployment')
param location string

@description('Environment prefix (e.g., dev, prod)')
param environment string

@description('Mandatory tags to apply to all resources')
param requiredTags object

@description('Log Analytics Workspace ID for diagnostic settings')
param logAnalyticsWorkspaceId string

@description('Address space for the Hub VNet')
param hubVnetAddressSpace string = '10.0.0.0/16'

@description('Address prefix for the AzureFirewallSubnet')
param fwSubnetPrefix string = '10.0.1.0/26'

@description('Address prefix for the GatewaySubnet')
param gwSubnetPrefix string = '10.0.2.0/27'

@description('Address prefix for the AzureBastionSubnet')
param bastionSubnetPrefix string = '10.0.3.0/26'

@description('Toggle to deploy Azure Firewall')
param deployFirewall bool = true

@description('Toggle to deploy Virtual Network Gateway (VPN)')
param deployVpnGateway bool = false

@description('Toggle to deploy Azure Bastion')
param deployBastion bool = false

// Resource Names (CAF compliant)
var vnetName = 'vnet-hub-${environment}-${location}'
var fwPipName = 'pip-fw-${environment}-${location}'
var fwName = 'afw-hub-${environment}-${location}'
var vpnPipName = 'pip-vpn-${environment}-${location}'
var vpnGwName = 'vgw-hub-${environment}-${location}'
var bastionPipName = 'pip-bas-${environment}-${location}'
var bastionName = 'bas-hub-${environment}-${location}'

// [SECURITY RATIONALE] The Hub VNet acts as the central point of connectivity and security inspection.
// All inbound/outbound traffic from Spokes will be routed here.
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  tags: requiredTags
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVnetAddressSpace
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: fwSubnetPrefix
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: gwSubnetPrefix
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionSubnetPrefix
        }
      }
    ]
  }
}

// Diagnostics for Hub VNet
resource vnetDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${vnetName}'
  scope: hubVnet
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

// --- AZURE FIREWALL ---

// Public IP for Azure Firewall
resource fwPip 'Microsoft.Network/publicIPAddresses@2023-09-01' = if (deployFirewall) {
  name: fwPipName
  location: location
  tags: requiredTags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// [SECURITY RATIONALE] Azure Firewall deployed in the Hub to inspect all East-West (VNet-to-VNet) 
// and North-South (Internet-bound) traffic using Threat Intelligence-based rules.
resource azureFirewall 'Microsoft.Network/azureFirewalls@2023-09-01' = if (deployFirewall) {
  name: fwName
  location: location
  tags: requiredTags
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'configuration'
        properties: {
          subnet: {
            id: hubVnet.properties.subnets[0].id // AzureFirewallSubnet
          }
          publicIPAddress: {
            id: fwPip.id
          }
        }
      }
    ]
  }
}

// Diagnostics for Azure Firewall
resource fwDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployFirewall) {
  name: 'diag-${fwName}'
  scope: azureFirewall
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

// --- VPN GATEWAY ---

// Public IP for VPN Gateway
resource vpnPip 'Microsoft.Network/publicIPAddresses@2023-09-01' = if (deployVpnGateway) {
  name: vpnPipName
  location: location
  tags: requiredTags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// [COST RATIONALE] We use VpnGw1 as it provides a good balance of cost and performance (up to 650 Mbps) for SMBs.
resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-09-01' = if (deployVpnGateway) {
  name: vpnGwName
  location: location
  tags: requiredTags
  properties: {
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: hubVnet.properties.subnets[1].id // GatewaySubnet
          }
          publicIPAddress: {
            id: vpnPip.id
          }
        }
      }
    ]
  }
}

// --- AZURE BASTION ---

// Public IP for Bastion
resource bastionPip 'Microsoft.Network/publicIPAddresses@2023-09-01' = if (deployBastion) {
  name: bastionPipName
  location: location
  tags: requiredTags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// [SECURITY RATIONALE] Azure Bastion allows secure RDP/SSH to Spoke VMs without exposing them to the public internet.
resource bastionHost 'Microsoft.Network/bastionHosts@2023-09-01' = if (deployBastion) {
  name: bastionName
  location: location
  tags: requiredTags
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: hubVnet.properties.subnets[2].id // AzureBastionSubnet
          }
          publicIPAddress: {
            id: bastionPip.id
          }
        }
      }
    ]
  }
}

output hubVnetId string = hubVnet.id
output hubVnetName string = hubVnet.name
output firewallPrivateIp string = deployFirewall ? azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress : ''