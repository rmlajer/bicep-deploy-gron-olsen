@description('Location for all resources.')
param location string = resourceGroup().location

param vnetname string = 'go-auctionhouse-vnet'
param subnetName string = 'goServicesSubnet'
param dnsRecordName string ='SERVICES'
param dnszonename string='go-auctionhouse.dk'
param storageAccountName string='storageAccount'

param mongoConnection string = 'mongodb://admin:1234@backend:27017/?authSource=admin'
param nginxPath string = 'http://localhost:4000'
param lokiEndpoint string = 'http://devops:3100'
param authServicePort int = 7000
param auctionServicePort int = 7010
param bidServicePort int = 7020
param legalServicePort int = 7030
param orderServicePort int = 7040
param productServicePort int = 7050
param userServicePort int = 7060
param biddbServicePort int = 7070
param vaultPath string = 'https://go-auctionhouse-kv.vault.azure.net/'

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
        name: 'authservice'
        properties: {
          image: 'caboe/auth-svc:latest-main'
          ports: [
            {
              port: authServicePort
            }
          ]
          environmentVariables: [
            {
              name: 'INFRA_CONN'
              value: nginxPath
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://localhost:${authServicePort}'
            }
            {
              name: 'LOKI_ENDPOINT'
              value: lokiEndpoint
            }
            {
              name: 'VAULT_PATH'
              value: vaultPath
            }
          ]
          resources: {
            requests: {
              memoryInGB: json('0.5')
              cpu: json('0.25')
            }
          }
        }
      }
      {
        name: 'auctionservice'
        properties: {
          image: 'caboe/auction-svc:latest-main'
          ports: [
            {
              port: auctionServicePort
            }
          ]
          environmentVariables: [
            {
              name: 'INFRA_CONN'
              value: nginxPath
            }
            {
              name: 'CONNECTION_STRING'
              value: mongoConnection
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://localhost:${auctionServicePort}'
            }
            {
              name: 'LOKI_ENDPOINT'
              value: lokiEndpoint
            }
            {
              name: 'VAULT_PATH'
              value: vaultPath
            }
          ]
          resources: {
            requests: {
              memoryInGB: json('0.5')
              cpu: json('0.25')
            }
          }
        }
      }
      {
        name: 'bidservice'
        properties: {
          image: 'caboe/bid-svc:latest-main'
          ports: [
            {
              port: bidServicePort
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
              value: nginxPath
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://localhost:${bidServicePort}'
            }
            {
              name: 'VAULT_PATH'
              value: vaultPath
            }
            {
              name: 'LOKI_ENDPOINT'
              value: lokiEndpoint
            }
          ]
          resources: {
            requests: {
              memoryInGB: json('0.5')
              cpu: json('0.25')
            }
          }
        }
      }
      {
        name: 'biddbservice'
        properties: {
          image: 'caboe/biddb-svc:latest-main'
          ports: [
            {
              port: biddbServicePort
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
              value: nginxPath
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://localhost:${biddbServicePort}'
            }
            {
              name: 'LOKI_ENDPOINT'
              value: lokiEndpoint
            }
            
          ]
          resources: {
            requests: {
              memoryInGB: json('0.5')
              cpu: json('0.25')
            }
          }
        }
      }
      {
        name: 'legalservice'
        properties: {
          image: 'caboe/legal-svc:latest-main'
          ports: [
            {
              port: legalServicePort
            }
          ]
          environmentVariables: [
            {
              name: 'INFRA_CONN'
              value: nginxPath
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://localhost:${legalServicePort}'
            }
            {
              name: 'LOKI_ENDPOINT'
              value: lokiEndpoint
            }
            {
              name: 'VAULT_PATH'
              value: vaultPath
            }
          ]
          resources: {
            requests: {
              memoryInGB: json('0.5')
              cpu: json('0.25')
            }
          }
        }
      }
      {
        name: 'orderservice'
        properties: {
          image: 'caboe/order-svc:latest-main'
          ports: [
            {
              port: orderServicePort
            }
          ]
          environmentVariables: [
            {
              name: 'INFRA_CONN'
              value: nginxPath
            }
            {
              name: 'CONNECTION_STRING'
              value: mongoConnection
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://localhost:${orderServicePort}'
            }
            {
              name: 'LOKI_ENDPOINT'
              value: lokiEndpoint
            }
            {
              name: 'VAULT_PATH'
              value: vaultPath
            }
          ]
          resources: {
            requests: {
              memoryInGB: json('0.5')
              cpu: json('0.25')
            }
          }
        }
      }
      {
        name: 'productservice'
        properties: {
          image: 'caboe/product-svc:latest-main'
          ports: [
            {
              port: productServicePort
            }
          ]
          environmentVariables: [
            {
              name: 'INFRA_CONN'
              value: nginxPath
            }
            {
              name: 'CONNECTION_STRING'
              value: mongoConnection
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://localhost:${productServicePort}'
            }
            {
              name: 'LOKI_ENDPOINT'
              value: lokiEndpoint
            }
            {
              name: 'VAULT_PATH'
              value: vaultPath
            }
          ]
          resources: {
            requests: {
              memoryInGB: json('0.5')
              cpu: json('0.25')
            }
          }
        }
      }
      {
        name: 'userservice'
        properties: {
          image: 'caboe/user-svc:latest-main'
          ports: [
            {
              port: userServicePort
            }
          ]
          environmentVariables: [
            {
              name: 'CONNECTION_STRING'
              value: mongoConnection
            }
            {
              name: 'INFRA_CONN'
              value: nginxPath
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://localhost:${userServicePort}'
            }
            {
              name: 'LOKI_ENDPOINT'
              value: lokiEndpoint
            }
            {
              name: 'VAULT_PATH'
              value: vaultPath
            }
          ]
          resources: {
            requests: {
              memoryInGB: json('0.5')
              cpu: json('0.25')
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
