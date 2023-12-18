
@description('Generated from /subscriptions/69871a8a-fe89-416a-aa8e-e2bd525fd3ce/resourceGroups/AuktionsHusetRG/providers/Microsoft.Network/publicIPAddresses/goauctions-public_ip')
resource goauctionspublicip 'Microsoft.Network/publicIPAddresses@2022-11-01' = {
  name: 'goauctions-public_ip'
  location: 'eastus'
  properties: {
    ipAddress: '20.119.63.165'
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: 'auktionshustgo'
      fqdn: 'auktionshustgo.eastus.cloudapp.azure.com'
    }
    ipTags: []
    ddosSettings: {
      protectionMode: 'VirtualNetworkInherited'
    }
  }
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
}
