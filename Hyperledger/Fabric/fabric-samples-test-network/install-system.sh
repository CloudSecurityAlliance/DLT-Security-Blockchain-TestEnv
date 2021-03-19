#!/usr/bin/env bash
#
# Copyright Kurt Seifried kseifried@cloudsecurityalliance.org CloudSecurityAlliance 2021
# License: Apache 2.0
#
echo "THIS ONLY INSTALLS HYPERLEDGER FABRIC CURRENT (2.3.1 as of 2021-03-16)"
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



echo "Making directory /opt/hyperledger"
mkdir /opt/hyperledger
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
EOF

echo "Setting up /opt/hyperledger/3-node-chain-start.sh"
cat <<'EOF' >> /opt/hyperledger/3-node-chain-start.sh
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
./network.sh up createChannel -c mychannel
#
cd /opt/hyperledger/fabric-samples/test-network/addOrg3/
./addOrg3.sh up -c mychannel
#
cd /opt/hyperledger/fabric-samples/test-network/addOrg4/
./addOrg4.sh up -c mychannel
#
cd /opt/hyperledger/fabric-samples/test-network/addOrg5/
./addOrg5.sh up -c mychannel
#
cd /opt/hyperledger/fabric-samples/test-network/addOrg6/
./addOrg6.sh up -c mychannel
EOF
chmod +x /opt/hyperledger/3-node-chain-start.sh

echo "Setting up /opt/hyperledger/3-node-chain-stop.sh"
cat <<'EOF' >> /opt/hyperledger/3-node-chain-stop.sh
#!/bin/bash
#
# Stop it from the addOrg3 script
#
cd /opt/hyperledger/fabric-samples/test-network/addOrg3
./addOrg3.sh down
EOF
chmod +x /opt/hyperledger/3-node-chain-stop.sh

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
echo "Then run the cd /opt/hyperledger/; ./3-node-chain-start.sh to start it"
echo "And the cd /opt/hyperledger/; ./3-node-chain-stop.sh to stop it"
echo ""
echo "Also remember to log out and back in so that commands like \"peer\" work"
