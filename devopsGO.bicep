@description('Location for all resources.')
param location string = resourceGroup().location

param vnetname string = 'go-auctionhouse-vnet'
param subnetName string = 'goDevopsSubnet'
param dnsRecordName string ='DEVOPS'
param dnszonename string='go-auctionhouse.dk'
param storageAccountName string='nostorage'

resource VNET 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  name: vnetname
  resource subnet 'subnets@2022-01-01' existing = {
    name: subnetName
  }
}

// Get a reference to the existing storage
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountName
}

@description('auktionsHuset DevOps Container Group')
resource auktionsHusetDevOpsGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {

  name: 'auktionsHusetDevOpsGroup'
  location: location

  properties: {
    sku: 'Standard'

    containers: [
      {
        name: 'loki'
        properties: {
          image: 'grafana/loki:main'
          ports: [
            {
              port: 3100
            }
          ]
          environmentVariables: []
          resources: {
            requests: {
              memoryInGB: json('1.0')
              cpu: json('0.5')
            }
          }
        }
      }
      {
        name: 'grafana'
        properties: {
          image: 'grafana/grafana:latest'
          ports: [
            {
              port: 3000
            }
          ]
          environmentVariables: []
          resources: {
            requests: {
              memoryInGB: json('1.0')
              cpu: json('0.5')
            }
          }
          volumeMounts: [
            {
              name: 'grafana-storage'
              mountPath: '/var/lib/grafana'
            }
          ]
        }
      }
    ]
    initContainers: []
    restartPolicy: 'Always'
    ipAddress: {
      ports: [
        {
          port: 3100
        }
        {
          port: 3000
        }
      ]
      ip: '10.0.2.4'
      type: 'Private'
    }
    osType: 'Linux'
    volumes: [
      {
        name: 'grafana-storage'
        azureFile: {
          shareName: 'storagegrafana'
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
        ipv4Address: auktionsHusetDevOpsGroup.properties.ipAddress.ip
      }
    ]
  }
}

output containerIPAddressFqdn string = auktionsHusetDevOpsGroup.properties.ipAddress.ip
