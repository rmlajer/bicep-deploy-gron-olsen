@description('Location for all resources.')
param location string = resourceGroup().location

// --- Konfigurerbare parametre ---

@description('Name of virtual network')
var virtualNetworkName = 'go-auctionhouse-vnet'

@description('Name of public ip address')
var publicIPAddressName = 'go-auctionhouse-public_ip'

@description('Name of the application Gateway')
var applicationGateWayName = 'go-auctionhouse-appgateway'

@description('Name of the DNS zone')
var dnszonename = 'go-auctionhouse.dk'

@description('Public Domain name used when accessing gateway from internet')
var publicDomainName = 'go-auctionhouse'

@description('List of file shares to create')
var shareNames = [
  'config'
  'data'
  'queue'
  'grafana'
  'vault'
]

// ---------------------------------

module network 'networkGO.bicep' = {
  name: 'networkModule'
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    publicIPAddressName: publicIPAddressName
    publicDomainName: publicDomainName
    dnszonename: dnszonename
  }  
}

module storage 'storageGO.bicep' = {
  name: 'storageModule'
  params: {
    location: location
    sharePrefix: 'storage'
    shareNames: shareNames
  }  
}

module devops 'devopsGO.bicep' = {
  name: 'devopsModule'
  params: {
    location: location
    vnetname: virtualNetworkName
    subnetName: 'goDevopsSubnet'
    dnsRecordName: 'DEVOPS'
    dnszonename: dnszonename
    storageAccountName: storage.outputs.storageAccountName
  }
}

module backend 'backendGO.bicep' = {
  name: 'backendModule'
  params: {
    location: location
    vnetname: virtualNetworkName
    subnetName: 'goBackendSubnet'
    dnsRecordName: 'BACKEND'
    dnszonename: dnszonename
    storageAccountName: storage.outputs.storageAccountName
  }
}

module services 'servicesGO.bicep' = {
  name: 'servicesModule'
  params: {
    location: location
    vnetname: virtualNetworkName
    subnetName: 'goServicesSubnet'
    dnsRecordName: 'SERVICES'
    dnszonename: dnszonename
    storageAccountName: storage.outputs.storageAccountName
  }
}

resource applicationGateWay 'Microsoft.Network/applicationGateways@2022-11-01' = {
  name: applicationGateWayName
  location: location
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'applicationGatewaySubnet')
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', publicIPAddressName)
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'GrafanaFrontPort'
        properties: {
          port: 3000
        }
      }
      {
        name: 'rabbitmqPort'
        properties: {
          port: 15672
        }
      }
      {
        name: 'nginxPort'
        properties: {
          port: 4000
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'goAuctionsBackendPool'
        properties: {
          backendAddresses: [
            {
              ipAddress: backend.outputs.containerIPAddressFqdn
            }
          ]
        }
      }
      {
        name: 'goAuctionsDevopsPool'
        properties: {
          backendAddresses: [
            {
              ipAddress: devops.outputs.containerIPAddressFqdn
            }
          ]
        }
      }
      {
        name: 'goAuctionsServicesPool'
        properties: {
          backendAddresses: [
            {
              ipAddress: services.outputs.containerIPAddressFqdn
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'GrafanaHttpSettings'
        properties: {
          port: 3000
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          connectionDraining: {
            enabled: false
            drainTimeoutInSec: 1
          }
          pickHostNameFromBackendAddress: false
          requestTimeout: 30
        }
      }
      {
        name: 'rabbitMQHttpSettings'
        properties: {
          port: 15672
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          connectionDraining: {
            enabled: false
            drainTimeoutInSec: 1
          }
          pickHostNameFromBackendAddress: false
          requestTimeout: 30
        }
      }
      {
        name: 'nginxHttpSettings'
        properties: {
          port: 4000
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          connectionDraining: {
            enabled: false
            drainTimeoutInSec: 1
        }
        pickHostNameFromBackendAddress: false
        requestTimeout: 30
      }
      }
    ]
    httpListeners: [
      {
        name: 'GrafanaHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateWayName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateWayName, 'GrafanaFrontPort')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
      {
        name: 'RabbitMQHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateWayName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateWayName, 'rabbitmqPort')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
      {
        name: 'nginxHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateWayName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
          id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateWayName, 'nginxPort')
          }
          protocol: 'Http'
          requireServerNameIndication: false
      }
      }
    ]
    requestRoutingRules: [
      {
        name: 'GrafanaRule'
        properties: {
          ruleType: 'Basic'
          priority: 12000
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateWayName, 'GrafanaHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGateWayName, 'goAuctionsDevopsPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateWayName, 'GrafanaHttpSettings')
          }
        }
      }
      {
        name: 'RabbitMqRule'
        properties: {
          ruleType: 'Basic'
          priority: 11000
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateWayName, 'RabbitMQHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGateWayName, 'goAuctionsBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateWayName, 'rabbitMQHttpSettings')
          }
        }
      }
      {
        name: 'nginxRule'
        properties: {
          ruleType: 'Basic'
          priority: 10000
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateWayName, 'nginxHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGateWayName, 'goAuctionsServicesPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateWayName, 'nginxHttpSettings')
          }
        }
      }
    ]
    enableHttp2: false
    autoscaleConfiguration: {
      minCapacity: 0
      maxCapacity: 10
    }
  }
  dependsOn: [
    network
  ]
}



