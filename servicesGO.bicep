@description('Location for all resources.')
param location string = resourceGroup().location

param vnetname string = 'go-auctionhouse-vnet'
param subnetName string = 'goServicesSubnet'
param dnsRecordName string ='SERVICES'
param dnszonename string='go-auctionhouse.dk'
param storageAccountName string='storageAccount'

param mongoConnection string = 'mongodb://root:rootpassword@localhost:27017/?authSource=admin'
param auctionServicePath string = 'http://localhost:7040'

resource VNET 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: vnetname
  resource subnet 'subnets@2022-01-01' existing = {
    name: subnetName
  }
}

//Get a reference to the existing storage
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
 name: storageAccountName
}

@description('auktionsHuset Services Container Group')
resource auktionsHusetServicesGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {

  name: 'auktionsHusetServicesGroup'
  location: location

  properties: {
    sku: 'Standard'

    containers: [
      {
        name: 'nginx'
        properties: {
          image: 'nginx:latest'
          ports: [
            {
              port: 4000
            }
          ]
          environmentVariables: []
          resources: {
            requests: {
              memoryInGB: json('0.5')
              cpu: json('0.25')
            }
          }
          volumeMounts: [
	        {
              name: 'nginx-config'
              mountPath: '/etc/nginx/'
            }
          ]
        }
      }
      {
        name: 'biddbservice'
        properties: {
          image: 'caboe/biddb-svc:latest-main'
          ports: [
            {
              port: 7010
            }
          ]
          environmentVariables: [
            {
              name: 'CONNECTION_STRING'
              value: mongoConnection
            }
            {
              name: 'RABBITMQ_HOSTNAME'
              value: 'backend'
            }
            {
              name: 'INFRA_CONN'
              value: auctionServicePath
            }
          ]
          resources: {
            requests: {
              memoryInGB: json('1.0')
              cpu: json('0.5')
            }
          }
        }
      }
      {
        name: 'bidservice'
        properties: {
          image: 'rmlajer/bid-svc:latest'
          ports: [
            {
              port: 7020
            }
          ]
          environmentVariables: [
            {
              name: 'CONNECTION_STRING'
              value: mongoConnection
            }
            {
              name: 'RABBITMQ_HOSTNAME'
              value: 'backend'
            }
            {
              name: 'INFRA_CONN'
              value: auctionServicePath
            }
          ]
          resources: {
            requests: {
              memoryInGB: json('1.0')
              cpu: json('0.5')
            }
          }
        }
      }
      
    ]
    initContainers: []
    restartPolicy: 'Always'
    ipAddress: {
      ports: [
        {
          port: 4000
        }
      ]
      ip: '10.0.3.4'
      type: 'Private'
    }
    osType: 'Linux'
    volumes: [
      {
        name: 'nginx-config'
        azureFile: {
          shareName: 'storageconfig'
          storageAccountName: storageAccount.name
          storageAccountKey: storageAccount.listKeys().keys[0].value
        }
      }
    ]
    subnetIds: [
      {
        id: VNET::subnet.id
      }
    ]
    dnsConfig: {
      nameServers: [
        '10.0.0.10'
        '10.0.0.11'
      ]
      searchDomains: dnszonename
    }
  }
}

resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: dnszonename
}

resource dnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: dnsRecordName
  parent: dnsZone
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: auktionsHusetServicesGroup.properties.ipAddress.ip
      }
    ]
  }
}

output containerIPAddressFqdn string = auktionsHusetServicesGroup.properties.ipAddress.ip
