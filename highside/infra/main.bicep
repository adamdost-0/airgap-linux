targetScope = 'resourceGroup'

@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string

@allowed([
  'usgovernment'
  'usgovernmentsecret'
  'usgovernmenttopsecret'
])
param azureGovernmentEnvironment string = 'usgovernment'

param location string = resourceGroup().location
param owner string

@allowed([
  'CUI'
  'Secret'
  'TopSecret'
])
param classification string = 'CUI'

@allowed([
  'IL4'
  'IL5'
  'IL6'
])
param compliance string = 'IL5'

param aptlyVmSize string = 'Standard_D4s_v5'
param aptlyAdminUsername string = 'aptlyadmin'
@secure()
param adminSshPublicKey string
param vnetAddressPrefix string = '10.1.0.0/16'
param aptlySubnetPrefix string = '10.1.1.0/24'
param privateLinkSubnetPrefix string = '10.1.2.0/24'
param internalDnsSuffix string = 'apt.internal.local'
param allowedClientSubnets array = []
param aptlyDataDiskSizeGb int = 1024

var endpointSuffixes = {
  usgovernment: 'usgovcloudapi.net'
  usgovernmentsecret: 'microsoftazure.us'
  usgovernmenttopsecret: 'microsoftazure.eaglex.ic.gov'
}
var currentEndpointSuffix = endpointSuffixes[azureGovernmentEnvironment]
var namePrefix = 'aptly-gov-${environment}'
var vmName = '${namePrefix}-vm'
var keyVaultName = 'kv-${take(environment, 4)}-${uniqueString(resourceGroup().id)}'
var aptlyIdentityName = '${namePrefix}-aptly-id'
var tags = {
  Environment: environment
  Project: 'airgap-linux'
  Owner: owner
  Classification: classification
  Compliance: compliance
  ManagedBy: 'bicep'
  Component: 'highside-air-gapped'
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: '${namePrefix}-vnet'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: '${namePrefix}-aptly-subnet'
        properties: {
          addressPrefix: aptlySubnetPrefix
          networkSecurityGroup: {
            id: aptlyNsg.id
          }
        }
      }
      {
        name: '${namePrefix}-privatelink-subnet'
        properties: {
          addressPrefix: privateLinkSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

resource aptlyNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: '${namePrefix}-aptly-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: concat(
      length(allowedClientSubnets) > 0 ? [
        {
          name: 'AllowHTTPSFromClients'
          properties: {
            priority: 100
            direction: 'Inbound'
            access: 'Allow'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '443'
            sourceAddressPrefixes: allowedClientSubnets
            destinationAddressPrefix: '*'
          }
        }
      ] : [],
      [
        {
          name: 'AllowVNetOutbound'
          properties: {
            priority: 100
            direction: 'Outbound'
            access: 'Allow'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRange: '*'
            sourceAddressPrefix: 'VirtualNetwork'
            destinationAddressPrefix: 'VirtualNetwork'
          }
        }
        {
          name: 'DenyInternetOutbound'
          properties: {
            priority: 4095
            direction: 'Outbound'
            access: 'Deny'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRange: '*'
            sourceAddressPrefix: '*'
            destinationAddressPrefix: 'Internet'
          }
        }
        {
          name: 'DenyAllInbound'
          properties: {
            priority: 4096
            direction: 'Inbound'
            access: 'Deny'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRange: '*'
            sourceAddressPrefix: '*'
            destinationAddressPrefix: '*'
          }
        }
      ])
  }
}

resource aptlyIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: aptlyIdentityName
  location: location
  tags: tags
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    tenantId: tenant().tenantId
    sku: {
      family: 'A'
      name: 'premium'
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
  }
}

resource keyVaultSecretsRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, aptlyIdentity.id, 'Key Vault Secrets User')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: aptlyIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource keyVaultPrivateDns 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.vaultcore.${currentEndpointSuffix}'
  location: 'global'
  tags: tags
}

resource keyVaultPrivateDnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: '${namePrefix}-kv-dns-link'
  parent: keyVaultPrivateDns
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${keyVaultName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, '${namePrefix}-privatelink-subnet')
    }
    privateLinkServiceConnections: [
      {
        name: '${keyVaultName}-psc'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

resource keyVaultPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  name: 'default'
  parent: keyVaultPrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'vault'
        properties: {
          privateDnsZoneId: keyVaultPrivateDns.id
        }
      }
    ]
  }
  dependsOn: [
    keyVaultPrivateDnsLink
  ]
}

resource internalDns 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: internalDnsSuffix
  location: 'global'
  tags: tags
}

resource internalDnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: '${namePrefix}-internal-dns-link'
  parent: internalDns
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource aptlyNic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: '${vmName}-nic'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'internal'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, '${namePrefix}-aptly-subnet')
          }
        }
      }
    ]
  }
}

resource repoDnsRecord 'Microsoft.Network/privateDnsZones/A@2024-06-01' = {
  name: 'repo'
  parent: internalDns
  properties: {
    ttl: 300
    aRecords: [
      {
        ipv4Address: aptlyNic.properties.ipConfigurations[0].properties.privateIPAddress
      }
    ]
  }
  dependsOn: [
    internalDnsLink
  ]
}

resource aptlyVm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: vmName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${aptlyIdentity.id}': {}
    }
  }
  properties: {
    hardwareProfile: {
      vmSize: aptlyVmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: aptlyAdminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${aptlyAdminUsername}/.ssh/authorized_keys'
              keyData: adminSshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: 128
      }
      dataDisks: [
        {
          lun: 0
          createOption: 'Empty'
          diskSizeGB: aptlyDataDiskSizeGb
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: aptlyNic.id
        }
      ]
    }
  }
}

output aptlyVmId string = aptlyVm.id
output aptlyVmPrivateIp string = aptlyNic.properties.ipConfigurations[0].properties.privateIPAddress
output aptlyRepoFqdn string = 'repo.${internalDns.name}'
output aptlyIdentityPrincipalId string = aptlyIdentity.properties.principalId
output keyVaultUri string = keyVault.properties.vaultUri
