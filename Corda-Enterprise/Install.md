# Corda 4.8 Enterprise install

First decide what/how to install, 

# CRL Host

crl-files.csatestdomain.com

as per https://docs.corda.net/docs/cenm/1.5/quick-start.html

NO REDIRECT OF HTTP TO HTTPS. INSECURE ONLY as per the documentatione examples.

# Requirements

https://docs.corda.net/docs/corda-enterprise/4.8/platform-support-matrix.html

## Production platform:
Suggest Ubuntu 18.04 as easiest to get and supported by vendor

## Node databases:
Suggest postgresql, Ubuntu 18.04  has 10

## JDK:
https://docs.corda.net/docs/corda-enterprise/4.8/platform-support-matrix.html
Corda Enterprise 4.8 has been tested and verified to work with Oracle JDK 8 JVM 8u251 and Azul Zulu Enterprise 8u252, for Azure deployment downloadable from Azul Systems.

Other distributions of the OpenJDK are not officially supported but should be compatible with Corda Enterprise 4.8.

Suggest we use Azul systems as easiest to download:

https://docs.azul.com/core/zulu-openjdk/install/debian

```
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9
curl -O https://cdn.azul.com/zulu/bin/zulu-repo_1.0.0-2_all.deb
sudo apt-get install ./zulu-repo_1.0.0-2_all.deb
sudo apt-get update
sudo apt-get upgrade
```

Which gets us zulu8 - Azul Zulu 8.56.0.21 (8u302-b08) JDK which should be close enough to Azul Zulu Enterprise 8u252

# CENM setup

## pkitool.jar pki-tool.jar

CENM-1.5.1.tar.gz

```
tar -xf ./CENM-1.5.1.tar.gz
unzip ./repository/com/r3/enm/tools/pki-tool/1.5.1/pki-tool-1.5.1.zip
```

The config file with no CRL "pki-generation.conf":

```
certificates = {
    "::CORDA_TLS_CRL_SIGNER",
    "::CORDA_ROOT",
    "::CORDA_SUBORDINATE",
    "::CORDA_IDENTITY_MANAGER",
    "::CORDA_NETWORK_MAP"
}
```
run the tool:

```
java -jar ./pkitool.jar --config-file pki-generation.conf --ignore-missing-crl
```

## Identity Manager Service

CENM-1.5.1.tar.gz

```
tar -xf ./CENM-1.5.1.tar.gz
unzip ./repository/com/r3/enm/services/identitymanager/1.5.1/identitymanager-1.5.1.zip
```

Create custom identity-manager.conf:

```
address = "localhost:10000" 
database { 
    driverClassName = org.h2.Driver 
    url = "jdbc:h2:file:./identity-manager-persistence;DB_CLOSE_ON_EXIT=FALSE;LOCK_TIMEOUT=10000;WRITE_DELAY=0;AUTO_SERVER_PORT=0" 
    user = "example-db-user" 
    password = "example-db-password" 
    # Database migration is probably needed
    runMigration = true
} 

shell { 
    sshdPort = 10002 
    user = "testuser" 
    password = "password" 
} 

localSigner { 
    keyStore { 
        file = key-stores/corda-identity-manager-keys.jks 
        password = "password" 
    } 
    keyAlias = "cordaidentitymanagerca" 
    signInterval = 10000 
    # This CRL parameter is not strictly needed. However if it is omitted, then revocation cannot be used in the future so it makes sense to leave it in. 
    #crlDistributionUrl = "http://"${address}"/certificate-revocation-list/doorman" 
} 

workflows { 
    "issuance" { 
        type = ISSUANCE 
        # add enmListener port to avoid error
        enmListener { 
            port = 10001 
            reconnect = true 
        } 
        updateInterval = 10000 
        plugin { 
            pluginClass = "com.r3.enmplugins.approveall.ApproveAll" 
        } 
    } 
} 

```

Run it

```
java -jar identitymanager.jar --config-file identity-manager.conf
```

This gets us the trust-stores/network-root-truststore.jks

# CORDA

```
tar -xf corda-4.8-full-release.tar.gz
```

## node.conf

So https://medium.com/@TIS_BC_Prom/corda-notary-cluster%E3%81%AE%E6%A7%8B%E7%AF%89%E6%96%B9%E6%B3%95%E3%81%A8%E3%81%9D%E3%81%AE%E9%AB%98%E5%8F%AF%E7%94%A8%E6%80%A7-ha-%E3%81%AE%E6%A4%9C%E8%A8%BC-3c049cffd92b had a hint

```
[ERROR] 16:27:47+0000 [main] internal.NodeStartupLogging. - Exception during node registration: The notary service legal name must be provided via the 'notary.serviceLegalName' configuration parameter                [ERROR] 16:27:47+0000 [main] internal.NodeStartupLogging. - Exception during node startup: The notary service legal name must be provided via the 'notary.serviceLegalName' configuration parameter 
```

so add "serviceLegalName" to the notary stanza

```
myLegalName="O=NotaryA,L=London,C=GB"
notary {
    validating=false
    serviceLegalName: "O=HA Notary, C=GB, L=London"
}

networkServices {
  doormanURL="http://localhost:10000"
  networkMapURL="http://localhost:81"
}

devMode = false

sshd {
  port = 2222
}

p2pAddress="localhost:30000"
rpcUsers=[
  {
    user=testuser
    password=password
    permissions=[
        ALL
    ]
  }
]

rpcSettings {
  address = "localhost:30001"
  adminAddress = "localhost:30002"
}
```

## trust-stores/network-root-truststore.jks

Copy this to the local directory

## Running Corda:

then try running it:

```
java -jar ./repository/com/r3/corda/corda/4.8/corda-4.8.jar --initial-registration --network-root-truststore-password trustpass --network-root-truststore network-root-truststore.jks
```


# TODO:

Certificate revocation bits - requires host with public DNS/HTTP server
