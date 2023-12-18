@description('Specifies the location in which the Azure Networking resources shall be deployed.')
param location string = resourceGroup().location
param virtualNetworkName string = 'theVNet'
param publicIPAddressName string = 'thePublicIPAdressName'
param publicDomainName string = 'publicDomainName'
param dnszonename string ='thednszone.dk'

var virtualNetworkPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var backendSubnetPrefix = '10.0.1.0/24'
var devopsSubnetPrefix = '10.0.2.0/24'
var servicesSubnetPrefix = '10.0.3.0/24'

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2021-05-01' =  {
  name: publicIPAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: publicDomainName
    }
  }
  /* TODO: Add DNS Name*/
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkPrefix
      ]
    }
    subnets: [
      {
        name: 'applicationGatewaySubnet'
        properties: {
          addressPrefix: subnetPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'goBackendSubnet'
        properties: {
          addressPrefix: backendSubnetPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          delegations: [
            {
              name: 'containerGroup'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
      {
        name: 'goDevopsSubnet'
        properties: {
          addressPrefix: devopsSubnetPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          delegations: [
            {
              name: 'containerGroup'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
      {
        name: 'goServicesSubnet'
        properties: {
          addressPrefix: servicesSubnetPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          delegations: [
            {
              name: 'containerGroup'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
    ]
    enableDdosProtection: false
  }
}

resource privateDns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: dnszonename
  location: 'global'
  dependsOn: [
    virtualNetwork
  ]
}

resource vnLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDns
  name: '${dnszonename}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}
