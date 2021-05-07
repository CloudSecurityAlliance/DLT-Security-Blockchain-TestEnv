# Besu setup

https://besu.hyperledger.org/en/stable/HowTo/Get-Started/Installation-Options/Options/

Please note that many of the insctructions default to using Mainnet which means you'll 
need to spend gas to run transactions, make sure you use a testing network such as Rinkeby, 
Ropsten or Goerli.

## Setup on Ubuntu

Use Ubuntu 18.04

```
apt install openjdk-11-jre-headless unzip
wget a release from https://github.com/hyperledger/besu/releases
mkdir -p /opt/hyperledger/
cd /opt/hyperledger/
unzip ~/besu-21.*.zip
cd besu-VERSION/bin/
besu --help
```
