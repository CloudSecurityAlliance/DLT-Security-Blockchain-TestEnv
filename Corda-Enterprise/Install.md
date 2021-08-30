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
repository/com/r3/enm/tools/pki-tool/1.5.1/

