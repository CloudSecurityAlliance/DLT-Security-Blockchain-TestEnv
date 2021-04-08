#!/usr/bin/env bash
#
# Copyright Kurt Seifried kseifried@cloudsecurityalliance.org CloudSecurityAlliance 2021
# License: Apache 2.0
#
echo "THIS ONLY INSTALLS HYPERLEDGER FABRIC CURRENT (2.3.1 as of 2021-03-16) on Ubuntu"
#
# Check for Ubuntu
#
RELEASE=`lsb_release -i`
if [[ $RELEASE =~ .*Ubuntu$ ]]; then
    echo "Ubuntu detected, continuing"
else
    echo "This only works reliably on Ubuntu. You can manually edit this check to bypass it (for e.g. Debian)."
    exit
fi
#
# Check for free disk space
# /opt/hyperledger (1 gig) and /var/lib/docker/ (2 gigs)
#
echo "Making directory /opt/hyperledger"
mkdir /opt/hyperledger
echo "Making directory /var/lib/docker/"
mkdir /var/lib/docker/
#
DIR_HYPER=`df -m /opt/hyperledger/ --output=avail | grep "[0-9]"`
DIR_DOCKER=`df -m /var/lib/docker/ --output=avail | grep "[0-9]"`

if [ $DIR_HYPER -lt 1024 ] && [ $DIR_DOCKER -lt 2048 ]; then
    echo "Not enough space found in  /opt/hyperledger/ and/or  /var/lib/docker/"
else
    echo "Found enough free space, continuing"
fi
#
#
# Getting 2.2.0 and older to work means making a lot of changes. You're welcome to do so (submit a PR to the branch 2.2.0).
#
# You can get this script via
# curl https://raw.githubusercontent.com/cloudsecurityalliance/DLT-Security-Blockchain-TestEnv/master/Hyperledger/Fabric/fabric-samples-test-network/install-system.sh > install-system.sh
# chmod +x install-system.sh
#
# This script uses a forked version of bootstrap.sh and fabric-samples
#
#
# Update the system
#
echo "Original URL: https://raw.githubusercontent.com/cloudsecurityalliance/DLT-Security-Blockchain-TestEnv/master/Hyperledger/Fabric/fabric-samples-test-network/install-system.sh"
echo "Copyright CloudSecurityAlliance 2021"
echo "Written by Kurt Seifried kseifried@cloudsecurityalliance.org"
sleep 5
echo "Updating system"
apt-get update
apt-get -y upgrade

#
# Fix DNS so AWS services/etc work
#
echo "Updating resolv.conf"
rm /etc/resolv.conf
ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

#
# Install dependancies
#
echo "Adding dependancies"
apt-get -y install curl git docker.io docker-compose nodejs npm python golang

#
# Docker compose is 1.25 which is to old, we need 1.28 or later:
#
echo "Updating docker-compose to 1.28.5:"
curl -L https://github.com/docker/compose/releases/download/1.28.5/docker-compose-`uname -s`-`uname -m` -o /usr/bin/docker-compose

cd /opt/hyperledger

echo "Setting up root paths for Hyperledger commands (log out and back in for it to work)"
cat <<'EOF' >> /root/.profile

#
# Stuff for Hyperledger
#
export PATH=$PATH:/opt/hyperledger/fabric-samples/bin
export FABRIC_CFG_PATH=/opt/hyperledger/fabric-samples/config
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/hyperledger/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/hyperledger/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
#
# BINARY: peer
#
export ORDERER_CA="/opt/hyperledger/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
EOF

echo "Setting up /opt/hyperledger/6-node-chain-start.sh"
cat <<'EOF' >> /opt/hyperledger/6-node-chain-start.sh
#!/bin/bash
#
# This has to run from the directory due to local file paths
#
cd /opt/hyperledger/fabric-samples/test-network
#
# Funny story: Blockchain networks vote on things to allow them (or not). So with 2 Orgs voting you can add a third and fourth Org to a channel (2:0, 2:1, so a majority)
# But you can't add a fifth Org (2 for, 2 not for, no majority). So for now just chuck them into mychannel2 while we figure out 
# https://hyperledger-fabric.readthedocs.io/en/release-2.3/channel_update_tutorial.html
#
# defaults to "mychannel", this is mandatory as the addOrg3 scripts expects mychannel to exist
#
./network.sh up createChannel -c mychannel -ca
#
cd /opt/hyperledger/fabric-samples/test-network/addOrg3/
./addOrg3.sh up -c mychannel -ca
#
cd /opt/hyperledger/fabric-samples/test-network/addOrg4/
./addOrg4.sh up -c mychannel -ca
#
cd /opt/hyperledger/fabric-samples/test-network/addOrg5/
./addOrg5.sh up -c mychannel -ca
#
cd /opt/hyperledger/fabric-samples/test-network/addOrg6/
./addOrg6.sh up -c mychannel -ca

#
# BINARY: discover
#
# Create conf.yaml for discover:
#
# This is currently broken due to use of CA. Need to extract the certs for discover to work.
# 
#discover --configFile /opt/hyperledger/fabric-samples/config/conf.yaml --peerTLSCA /opt/hyperledger/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/tls/ca.crt --userKey /opt/hyperledger/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/keystore/priv_sk --userCert /opt/hyperledger/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/signcerts/User1@org1.example.com-cert.pem  --MSP Org1MSP saveConfig
#
# How to run the discover command:
# discover --configFile /opt/hyperledger/fabric-samples/config/conf.yaml peers --channel mychannel  --server localhost:7051
#

EOF
chmod +x /opt/hyperledger/6-node-chain-start.sh

echo "Setting up /opt/hyperledger/6-node-chain-stop.sh"
cat <<'EOF' >> /opt/hyperledger/6-node-chain-stop.sh
#!/bin/bash
#
# Stop it from the addOrg6 script
#
cd /opt/hyperledger/fabric-samples/test-network/addOrg6
./addOrg6.sh down
EOF
chmod +x /opt/hyperledger/6-node-chain-stop.sh

echo "getting bootstrap.sh script"
# Original:
#curl https://raw.githubusercontent.com/hyperledger/fabric/master/scripts/bootstrap.sh > bootstrap.sh
# This version pulls KurtSeifried's fork:
cd /opt/hyperledger
curl https://raw.githubusercontent.com/cloudsecurityalliance/DLT-Security-Blockchain-TestEnv/master/Hyperledger/Fabric/fabric-samples-test-network/bootstrap.sh > bootstrap.sh
chmod +x bootstrap.sh

echo "Running bootstrap.sh /opt/hyperledger/ directory"

cd /opt/hyperledger/
./bootstrap.sh

echo ""
echo "Then run the cd /opt/hyperledger/; ./6-node-chain-start.sh to start it"
echo "And the cd /opt/hyperledger/; ./6-node-chain-stop.sh to stop it"
echo ""
echo "Also remember to log out and back in so that commands like \"peer\" work"
