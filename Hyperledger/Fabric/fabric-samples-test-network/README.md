These are some scripts and hints on getting the Hyperledger Fabric fabric-samples test-network setup on an Ubuntu system.

This uses the repo: https://github.com/kurtseifried/fabric-samples for the scripts

This uses the repo: https://github.com/hyperledger/fabric-samples for the binaries

And a slight fork of the script: https://github.com/hyperledger/fabric/blob/master/scripts/bootstrap.sh (it uses my repo for the scripts).

Download, chmod +x the install-system.sh and run it to get started.

Then run the /opt/hyperledger/6-node-chain-start.sh to setup the system.

The "peer" command will work, there is also an alias of the discover command with all the command line arguments called "csa_discover" to make life easier.


