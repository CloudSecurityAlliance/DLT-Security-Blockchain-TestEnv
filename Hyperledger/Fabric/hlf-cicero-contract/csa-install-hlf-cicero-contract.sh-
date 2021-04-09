#!/bin/bash
#
# https://github.com/accordproject/hlf-cicero-contract
#
# Added in our install-system.sh script
#
#export HLF_INSTALL_DIR=/opt/hyperledger/fabric-samples
#
# install jq
#
apt-get install -y jq
#
# peer command already works and PATH is set
#
#
# Install the repo
#
cd /opt/hyperledger
git clone https://github.com/accordproject/hlf-cicero-contract
#
# Copy our modified install.sh script for 6 orgs
#
curl https://raw.githubusercontent.com/cloudsecurityalliance/DLT-Security-Blockchain-TestEnv/master/Hyperledger/Fabric/hlf-cicero-contract/install.sh > /opt/hyperledger/hlf-cicero-contract/install.sh
#
# Start the network
#
###################
#
# Run the Cicero install.sh:
#
cd /opt/hyperledger/hlf-cicero-contract
./install.sh
#
# Run the Cicero initialize.sh
#
cd /opt/hyperledger/hlf-cicero-contract
./initialize.sh
