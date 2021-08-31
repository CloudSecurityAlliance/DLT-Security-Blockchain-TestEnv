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
```

Which gets us zulu8 - Azul Zulu 8.56.0.21 (8u302-b08) JDK which should be close enough to Azul Zulu Enterprise 8u252

# Components

## pkitool.jar pki-tool.jar

CENM-1.5.1.tar.gz

```
unzip ./CENM-1.5.1.tar.gz
unzip ./repository/com/r3/enm/tools/pki-tool/1.5.1/pki-tool-1.5.1.zip
```

The config file with no CRL:

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
java -jar repository/com/r3/enm/tools/pki-tool/1.5.1/pkitool.jar --config-file pki-generation.conf --ignore-missing-crl
```

## Identity Manager Service

CENM-1.5.1.tar.gz

```
unzip ./CENM-1.5.1.tar.gz
unzip ./repository/com/r3/enm/services/identitymanager/1.5.1/identitymanager-1.5.1.zip
```


```
./repository/com/r3/enm/services/identitymanager/1.5.1/identitymanager.jar
```

see custom identity-manager.conf:

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

# TODO:

Certificate revocation bits - requires host with public DNS/HTTP server
