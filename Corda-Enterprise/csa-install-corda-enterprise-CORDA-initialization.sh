#!/usr/bin/env bash
#
# Copyright Kurt Seifried kseifried@cloudsecurityalliance.org CloudSecurityAlliance 2021
# License: Apache 2.0
#
# You can get this script via
# curl https://raw.githubusercontent.com/cloudsecurityalliance/DLT-Security-Blockchain-TestEnv/master/Corda-Enterprise/csa-install-corda-enterprise-CORDA-initialization.sh > csa-install-corda-enterprise-CORDA-initialization.sh
# chmod +x csa-install-corda-enterprise-CORDA.sh
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
# Disable IPv6 or else the java stuff just binds to it by default, no IPv4.
#
#/etc/sysctl.conf
#net.ipv6.conf.all.disable_ipv6=1
#net.ipv6.conf.default.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1

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
# Unpack CORDA
#
sudo mkdir -p /opt/corda-enterprise/CORDA/
tar -xvf corda-4.8-full-release.tar.gz -C /opt/corda-enterprise/CORDA/

#
# Create node.conf
#

cat << 'EOF' >> /opt/corda-enterprise/CORDA/node.conf
myLegalName="O=NotaryA,L=London,C=GB"
notary {
    validating=false
    serviceLegalName="O=HA Notary, C=GB, L=London"
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
EOF

#
# Copy trust-stores/network-root-truststore.jks
#
cp /opt/corda-enterprise/CENM/trust-stores/network-root-truststore.jks /opt/corda-enterprise/CORDA/network-root-truststore.jks

#
# Run the tool, no CRL support
#
# TODO: ! ATTENTION: The --initial-registration flag has been deprecated and will be removed in a future version. Use the initial-registration command instead. 
#
cd /opt/corda-enterprise/CORDA/
java -jar ./repository/com/r3/corda/corda/4.8/corda-4.8.jar --initial-registration --network-root-truststore-password trustpass --network-root-truststore network-root-truststore.jks

#
# Create network-parameters.conf for CENM
#
cd /opt/corda-enterprise/CENM/
unzip -o ./repository/com/r3/enm/services/networkmap/1.5.1/networkmap-1.5.1.zip
cp ./trust-stores/network-root-truststore.jks ./network-root-truststore.jks
cp ./key-stores/corda-network-map-keys.jks ./corda-network-map-keys.jks

#
# Create network-map.conf for CENM
#



cat << 'EOF' >> /opt/corda-enterprise/CENM/network-map.conf
address = "localhost:20000"

database {
    driverClassName = org.h2.Driver
    url = "jdbc:h2:file:./network-map-persistence;DB_CLOSE_ON_EXIT=FALSE;LOCK_TIMEOUT=10000;WRITE_DELAY=0;AUTO_SERVER_PORT=0"
    user = "example-db-user"
    password = "example-db-password"
    runMigration = true
}

shell {
    sshdPort = 20002
    user = "testuser"
    password = "password"
}

localSigner {
    keyStore {
        file = corda-network-map-keys.jks
        password = "password"
    }
    keyAlias = "cordanetworkmap"
    signInterval = 10000
}

pollingInterval = 10000
checkRevocation = false
EOF

#
# ERROR NOTES:
#
# Error while executing Network Map command.
# Network Map database configuration error: com.r3.cordacrossports.OutstandingDatabaseChangesException: Incompatible database schema version detected. Please run the service with database.runMigration=true. Reason: There are 35 outstanding database changes that need to be run.
# Please consult Network Map documentation.
#
# Add:
# database.runMigration = true
# to the database stanza

#
# Create network-parameters.conf for CENM
#

cat << 'EOF' >> /opt/corda-enterprise/CENM/network-parameters.conf
notaries : [
  {
    notaryNodeInfoFile: network-root-truststore.jks
    validating: false
  }
]
minimumPlatformVersion = 3
maxMessageSize = 10485760
maxTransactionSize = 10485760
eventHorizonDays = 30
EOF

#
#
#
java -jar networkmap.jar --config-file network-map.conf --set-network-parameters network-parameters.conf --network-truststore network-root-truststore.jks --truststore-password trustpass --root-alias cordarootca

