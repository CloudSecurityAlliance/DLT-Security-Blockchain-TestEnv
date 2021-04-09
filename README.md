# DLT-Security-Blockchain-TestEnv

Please see https://csaurl.org/DLT-Security-Framework_sub_groups for more information on the subgroups. If you are interested in signing up please see https://csaurl.org/DLT-Security-Framework_Signup.

The structure and layout of this repo is simple: "VENDOR/PROJECT/directory with setup scripts for the blockchain/" and then any applications running on top this are also in the "VENDOR/PROJECT/directory with setup scripts for app/". Please note there may be multiple sets of install scripts for various scenarios (private, public, etc.) and also multiple sets of install scripts for the apps running on top of them. Where the app can run on multiple blockchains it will be placed in it's own "VENDOR/PROJECT/directory with setup scripts for app/" and not in the parent blockchain directory.

## Hyperledger Fabric - 6 Organization Test Network

Using a modified Hyperledger Fabric bootstrap.sh script and a custom repo for fabric-samples the CSA has produced a working set of scripts that stand up a 6 Organization network using Certificate Authorities on Ubuntu Linux using Docker, they also have a working "peer" and "discover" (aliased to "csa_discover") commands.

https://github.com/cloudsecurityalliance/DLT-Security-Blockchain-TestEnv/tree/master/Hyperledger/Fabric/fabric-samples-test-network

### Accord project Cicero - 6 Organization Test Network

Using a modified install.sh script the CSA has produced a working set of scripts that stand up a 6 Organization network using the hlf-cicero-contract example on Ubuntu Linux using Docker. Please note that this first requires you to install the above Hyperledger Fabric - 6 Organization Test Network.

https://github.com/cloudsecurityalliance/DLT-Security-Blockchain-TestEnv/tree/master/Hyperledger/Fabric/hlf-cicero-contract

## Hyperledger Besu

The CSA is working on scripts for Hyperledger Besu.

## Corda

The CSA is working on scripts for Corda.

## Enterprise Ethereum

The CSA is working on scripts for Enterprise Ethereum.

## Quorom

The CSA is working on scripts for Quorom.
