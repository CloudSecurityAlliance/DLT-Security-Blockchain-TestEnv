#!/usr/bin/env bash
#
# Copyright Kurt Seifried kseifried@cloudsecurityalliance.org CloudSecurityAlliance 2021
# License: Apache 2.0
#
# You can get this script via
# https://raw.githubusercontent.com/cloudsecurityalliance/DLT-Security-Blockchain-TestEnv/Hyperledger/Fabric/fabric-samples-test-network/install-system.sh
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
./network.sh up
# defaults to "mychannel", this is mandatory as the addOrg3 scripts expects mychannel to exist
./network.sh createChannel
cd addOrg3/
./addOrg3.sh up
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
curl https://raw.githubusercontent.com/hyperledger/fabric/master/scripts/bootstrap.sh > bootstrap.sh
chmod +x bootstrap.sh

echo ""
echo "Please run /opt/hyperledger/bootstrap.sh [version]"
echo ""
echo "Such as: /opt/hyperledger/bootstrap.sh 2.2.0"
echo ""
echo "Then run the /opt/hyperledger/3-node-chain-start.sh to start it"
echo "And the /opt/hyperledger/3-node-chain-stop.sh to stop it"
echo ""
echo "Also remmeber to log out and back in so that commands like \"peer\" work"
