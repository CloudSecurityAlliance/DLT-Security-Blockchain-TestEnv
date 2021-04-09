# Overview 

These are some scripts and hints on getting the Hyperledger Fabric fabric-samples test-network setup on an Ubuntu system.

This uses the repo: https://github.com/kurtseifried/fabric-samples for the scripts

This uses the repo: https://github.com/hyperledger/fabric-samples for the binaries

And a slight fork of the script: https://github.com/hyperledger/fabric/blob/master/scripts/bootstrap.sh (it uses my repo for the scripts).

# Steps to use

1. Download https://github.com/cloudsecurityalliance/DLT-Security-Blockchain-TestEnv/blob/master/Hyperledger/Fabric/fabric-samples-test-network/csa-install-fabric-test-network-system.sh, chmod +x the csa-install-fabric-test-network-system.sh and run it
2. Log out and back in for the updated PATH statements to take effect
3. Run /opt/hyperledger/6-node-chain-start.sh

The "peer" command will work, there is also an alias of the discover command with all the command line arguments called "csa_discover" to make life easier.

If you want to install the Accord project please see the README in 

