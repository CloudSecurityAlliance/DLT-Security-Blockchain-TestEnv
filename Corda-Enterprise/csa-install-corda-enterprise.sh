#!/usr/bin/env bash
#
# Copyright Kurt Seifried kseifried@cloudsecurityalliance.org CloudSecurityAlliance 2021
# License: Apache 2.0
#
# You can get this script via
# curl https://raw.githubusercontent.com/cloudsecurityalliance/DLT-Security-Blockchain-TestEnv/master/Corda-Enterprise/csa-install-corda-enterprise.sh > csa-install-corda-enterprise.sh
# chmod +x csa-install-corda-enterprise.sh
#
# Runs most stuff as root, it's for testing. I know it's a bad habit.
#
# Check for Ubuntu 18.04
#

PRETTY_NAME=`grep PRETTY_NAME /etc/os-release`

if [[ $PRETTY_NAME =~ "PRETTY_NAME=\"Ubuntu 18.04.6 LTS\"" ]]; then
    echo "Ubuntu detected 18.04, continuing"
else
    echo "This only works reliably on Ubuntu. You can manually edit this check to bypass it (for e.g. Debian)."
    exit
fi

#
# Check for free disk space
# /opt/corda/ (2 gigs)
#
echo "Making directory /opt/corda-enterprise"
sudo mkdir -P /opt/corda-enterprise/
#
DIR_CORDA=`df -m /opt/corda-enterprise/ --output=avail | grep "[0-9]"`

if [ $DIR_CORDA -lt 2048 ]; then
    echo "Not enough space found in  /opt/corda-enterprise/ and/or  /var/lib/docker/"
else
    echo "Found enough free space, continuing"
fi

#
# Update the system
#
sudo apt-get update
sudo apt-get -y --with-new-pkgs upgrade

# Java
# Suggest we use Azul systems as easiest to download:
# https://docs.azul.com/core/zulu-openjdk/install/debian
#
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9
curl -O https://cdn.azul.com/zulu/bin/zulu-repo_1.0.0-2_all.deb
sudo apt-get install ./zulu-repo_1.0.0-2_all.deb
sudo apt-get update
sudo apt-get upgrade

#
# Unpack CENM
#
sudo mkdir -p /opt/corda-enterprise/CENM/
tar -xvf CENM-1.5.1.tar.gz -C /opt/corda-enterprise/CENM/

#
# Unpack CENM PKI tools
#
cd /opt/corda-enterprise/CENM/
$FILE_PKITOOLS=./repository/com/r3/enm/tools/pki-tool/1.5.1/pki-tool-1.5.1.zip
unzip $FILE_PKITOOLS

#
# Create pki-generation.conf
#

cat << 'EOF' >> /opt/corda-enterprise/CENM/pki-generation.conf
certificates = {
    "::CORDA_TLS_CRL_SIGNER",
    "::CORDA_ROOT",
    "::CORDA_SUBORDINATE",
    "::CORDA_IDENTITY_MANAGER",
    "::CORDA_NETWORK_MAP"
}
EOF

#
# Run the tool, no CRL support
#
java -jar ./pkitool.jar --config-file pki-generation.conf --ignore-missing-crl

#
# Unpack CENM Identity manager
#

cd /opt/corda-enterprise/CENM/
$FILE_IDENTITYMANAGER=./repository/com/r3/enm/services/identitymanager/1.5.1/identitymanager-1.5.1.zip
unzip $FILE_IDENTITYMANAGER

#
# Create identity-manager.conf
#

cat << 'EOF' >> /opt/corda-enterprise/CENM/identity-manager.conf
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
EOF

#
# Run the identity manager
#
java -jar identitymanager.jar --config-file identity-manager.conf


