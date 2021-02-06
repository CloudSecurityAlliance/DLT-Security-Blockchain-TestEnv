Docker Compose portion of the Readme
=====================================

sudo docker-compose -f network/docker/docker-compose-ca.yaml down --remove-orphans
sudo docker-compose -f network/docker/docker-compose.yaml down --remove-orphans

find ./ -type f -exec sed -i -e 's/info/error/g' {} \;

You then need to add to your bash the path and then source it. I use ZSH so this is how I do it. Copy this into your bash file
```bash
export PATH=$PATH:./fabric-samples/bin
export FABRIC_CFG_PATH=./
```

Then source your bash so they are available. Check the execs and make sure they work
```bash
source ~/.zshrc
```

This is what you should see
```bash
☁  k8s-hyperledger-fabric-2.2 [master] ⚡  configtxgen --version
configtxgen:
 Version: 2.2.1
 Commit SHA: 344fda602
 Go version: go1.14.4
 OS/Arch: linux/amd64
☁  k8s-hyperledger-fabric-2.2 [master] ⚡  
```

## Docker (Local)

Okay, lets generate the certs for the network
```bash
sudo docker-compose -f network/docker/docker-compose-ca.yaml up
```

After it's done close down the network. Now it's time to generate the network artifacts
```bash
sudo chmod -R 777 crypto-config
sudo chown -R $USER:$USER crypto-config

configtxgen -profile OrdererGenesis -channelID syschannel -outputBlock ./orderer/genesis.block
configtxgen -profile MainChannel -outputCreateChannelTx ./channels/mainchannel.tx -channelID mainchannel
configtxgen -profile MainChannel -outputAnchorPeersUpdate ./channels/regulator-anchors.tx -channelID mainchannel -asOrg regulator
configtxgen -profile MainChannel -outputAnchorPeersUpdate ./channels/carrier-anchors.tx -channelID mainchannel -asOrg carrier
configtxgen -profile MainChannel -outputAnchorPeersUpdate ./channels/importer-bank-anchors.tx -channelID mainchannel -asOrg importer-bank
configtxgen -profile MainChannel -outputAnchorPeersUpdate ./channels/exporter-bank-anchors.tx -channelID mainchannel -asOrg exporter-bank
configtxgen -profile MainChannel -outputAnchorPeersUpdate ./channels/importer-anchors.tx -channelID mainchannel -asOrg importer
configtxgen -profile MainChannel -outputAnchorPeersUpdate ./channels/exporter-anchors.tx -channelID mainchannel -asOrg exporter

```

Now it's time to start the network
- If OSX - need to jump to minikube for now. I can't find a way to make it work with Catalina. I'll keep playing around with it. It's a problem with the docker.sock file and not being able to mount it to the peer. It's needed to spin up containers for the chaincode.
```bash
sudo docker-compose -f network/docker/docker-compose.yaml up
```

Lets setup the artifacts
```bash
sudo docker exec -it cli-peer0-regulator bash -c 'peer channel create -c mainchannel -f ./channels/mainchannel.tx -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem'

sudo docker exec -it cli-peer0-regulator bash -c 'cp mainchannel.block ./channels/'

sudo docker exec -it cli-peer0-regulator bash -c 'peer channel join -b channels/mainchannel.block'
sudo docker exec -it cli-peer1-regulator bash -c 'peer channel join -b channels/mainchannel.block'

sudo docker exec -it cli-peer0-carrier bash -c 'peer channel join -b channels/mainchannel.block'
sudo docker exec -it cli-peer1-carrier bash -c 'peer channel join -b channels/mainchannel.block'

sudo docker exec -it cli-peer0-importer-bank bash -c 'peer channel join -b channels/mainchannel.block'
sudo docker exec -it cli-peer1-importer-bank bash -c 'peer channel join -b channels/mainchannel.block'

sudo docker exec -it cli-peer0-exporter-bank bash -c 'peer channel join -b channels/mainchannel.block'
sudo docker exec -it cli-peer1-exporter-bank bash -c 'peer channel join -b channels/mainchannel.block'

sudo docker exec -it cli-peer0-importer bash -c 'peer channel join -b channels/mainchannel.block'
sudo docker exec -it cli-peer1-importer bash -c 'peer channel join -b channels/mainchannel.block'

sudo docker exec -it cli-peer0-exporter bash -c 'peer channel join -b channels/mainchannel.block'
sudo docker exec -it cli-peer1-exporter bash -c 'peer channel join -b channels/mainchannel.block'

sleep 5

sudo docker exec -it cli-peer0-regulator bash -c 'peer channel update -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem -c mainchannel -f channels/regulator-anchors.tx'
sudo docker exec -it cli-peer0-carrier bash -c 'peer channel update -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem -c mainchannel -f channels/carrier-anchors.tx'
sudo docker exec -it cli-peer0-importer-bank bash -c 'peer channel update -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem -c mainchannel -f channels/importer-bank-anchors.tx'

sudo docker exec -it cli-peer0-exporter-bank bash -c 'peer channel update -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem -c mainchannel -f channels/exporter-bank-anchors.tx'
sudo docker exec -it cli-peer0-importer bash -c 'peer channel update -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem -c mainchannel -f channels/importer-anchors.tx'
sudo docker exec -it cli-peer0-exporter bash -c 'peer channel update -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem -c mainchannel -f channels/exporter-anchors.tx'
```

Now we are going to install the chaincode
- Make sure you go mod vendor in each chaincode folder... might need to remove the go.sum depending
```bash
sudo docker exec -it cli-peer0-regulator bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1' &
sudo docker exec -it cli-peer1-regulator bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1' &

sudo docker exec -it cli-peer0-carrier bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1' &
sudo docker exec -it cli-peer1-carrier bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1' &

sudo docker exec -it cli-peer0-importer-bank bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1' &
sudo docker exec -it cli-peer1-importer-bank bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1' &

sudo docker exec -it cli-peer0-exporter-bank bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1' &
sudo docker exec -it cli-peer1-exporter-bank bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1' &

sudo docker exec -it cli-peer0-importer bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1' &
sudo docker exec -it cli-peer1-importer bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1' &

sudo docker exec -it cli-peer0-exporter bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1' &
sudo docker exec -it cli-peer1-exporter bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1'


sudo docker exec -it cli-peer0-regulator bash -c 'peer lifecycle chaincode install resource_types.tar.gz &> pkg.txt' &
sudo docker exec -it cli-peer1-regulator bash -c 'peer lifecycle chaincode install resource_types.tar.gz' &

sudo docker exec -it cli-peer0-carrier bash -c 'peer lifecycle chaincode install resource_types.tar.gz &> pkg.txt' &
sudo docker exec -it cli-peer1-carrier bash -c 'peer lifecycle chaincode install resource_types.tar.gz' &

sudo docker exec -it cli-peer0-importer-bank bash -c 'peer lifecycle chaincode install resource_types.tar.gz &> pkg.txt' &
sudo docker exec -it cli-peer1-importer-bank bash -c 'peer lifecycle chaincode install resource_types.tar.gz' &

sudo docker exec -it cli-peer0-exporter-bank bash -c 'peer lifecycle chaincode install resource_types.tar.gz &> pkg.txt' &
sudo docker exec -it cli-peer1-exporter-bank bash -c 'peer lifecycle chaincode install resource_types.tar.gz' &

sudo docker exec -it cli-peer0-importer bash -c 'peer lifecycle chaincode install resource_types.tar.gz &> pkg.txt' &
sudo docker exec -it cli-peer1-importer bash -c 'peer lifecycle chaincode install resource_types.tar.gz' &

sudo docker exec -it cli-peer0-exporter bash -c 'peer lifecycle chaincode install resource_types.tar.gz &> pkg.txt' &
sudo docker exec -it cli-peer1-exporter bash -c 'peer lifecycle chaincode install resource_types.tar.gz'

sudo docker exec -it cli-peer0-regulator bash -c 'peer lifecycle chaincode approveformyorg -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem --collections-config /opt/gopath/src/resource_types/collections-config.json --channelID mainchannel --name resource_types --version 1.0 --sequence 1 --package-id $(tail -n 1 pkg.txt | awk '\''NF>1{print $NF}'\'')' &
sudo docker exec -it cli-peer0-carrier bash -c 'peer lifecycle chaincode approveformyorg -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem --collections-config /opt/gopath/src/resource_types/collections-config.json --channelID mainchannel --name resource_types --version 1.0 --sequence 1 --package-id $(tail -n 1 pkg.txt | awk '\''NF>1{print $NF}'\'')' &
sudo docker exec -it cli-peer0-importer-bank bash -c 'peer lifecycle chaincode approveformyorg -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem --collections-config /opt/gopath/src/resource_types/collections-config.json --channelID mainchannel --name resource_types --version 1.0 --sequence 1 --package-id $(tail -n 1 pkg.txt | awk '\''NF>1{print $NF}'\'')' &
sudo docker exec -it cli-peer0-exporter-bank bash -c 'peer lifecycle chaincode approveformyorg -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem --collections-config /opt/gopath/src/resource_types/collections-config.json --channelID mainchannel --name resource_types --version 1.0 --sequence 1 --package-id $(tail -n 1 pkg.txt | awk '\''NF>1{print $NF}'\'')' &
sudo docker exec -it cli-peer0-importer bash -c 'peer lifecycle chaincode approveformyorg -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem --collections-config /opt/gopath/src/resource_types/collections-config.json --channelID mainchannel --name resource_types --version 1.0 --sequence 1 --package-id $(tail -n 1 pkg.txt | awk '\''NF>1{print $NF}'\'')' &
sudo docker exec -it cli-peer0-exporter bash -c 'peer lifecycle chaincode approveformyorg -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem --collections-config /opt/gopath/src/resource_types/collections-config.json --channelID mainchannel --name resource_types --version 1.0 --sequence 1 --package-id $(tail -n 1 pkg.txt | awk '\''NF>1{print $NF}'\'')'


sudo docker exec -it cli-peer0-regulator bash -c 'peer lifecycle chaincode commit -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem --collections-config /opt/gopath/src/resource_types/collections-config.json --channelID mainchannel --name resource_types --version 1.0 --sequence 1'
```

Lets go ahead and test this chaincode
- If OSX
1. eval $(docker-machine env)
```bash
sudo docker exec -it cli-peer0-regulator bash -c 'peer chaincode invoke -C mainchannel -n resource_types -c '\''{"Args":["Create", "1","Parts"]}'\'' -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem'
sleep 5
sudo docker exec -it cli-peer0-regulator bash -c 'peer chaincode query -C mainchannel -n resource_types -c '\''{"Args":["Index"]}'\'' -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem'
sudo docker exec -it cli-peer0-regulator bash -c 'peer chaincode invoke -C mainchannel -n resource_types -c '\''{"Args":["Update", "1", "Parts 2"]}'\'' -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem'
sudo docker exec -it cli-peer0-regulator bash -c 'peer chaincode invoke -C mainchannel -n resource_types -c '\''{"Args":["Update", "1", "Parts"]}'\'' -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem'
sudo docker exec -it cli-peer0-regulator bash -c 'peer chaincode query -C mainchannel -n resource_types -c '\''{"Args":["Transactions","1"]}'\'' -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem'

```

Lets try the other chaincode
- If OSX
1. eval $(docker-machine env)
```bash
docker exec -it cli-peer0-regulator bash -c 'peer lifecycle chaincode package resources.tar.gz --path /opt/gopath/src/resources --lang golang --label resources_1' &
docker exec -it cli-peer1-regulator bash -c 'peer lifecycle chaincode package resources.tar.gz --path /opt/gopath/src/resources --lang golang --label resources_1' &
docker exec -it cli-peer0-carrier bash -c 'peer lifecycle chaincode package resources.tar.gz --path /opt/gopath/src/resources --lang golang --label resources_1' &
docker exec -it cli-peer1-carrier bash -c 'peer lifecycle chaincode package resources.tar.gz --path /opt/gopath/src/resources --lang golang --label resources_1'


docker exec -it cli-peer0-regulator bash -c 'peer lifecycle chaincode install resources.tar.gz &> pkg.txt' &
docker exec -it cli-peer1-regulator bash -c 'peer lifecycle chaincode install resources.tar.gz' &
docker exec -it cli-peer0-carrier bash -c 'peer lifecycle chaincode install resources.tar.gz &> pkg.txt' &
docker exec -it cli-peer1-carrier bash -c 'peer lifecycle chaincode install resources.tar.gz'

docker exec -it cli-peer0-regulator bash -c 'peer lifecycle chaincode approveformyorg -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem --collections-config /opt/gopath/src/resources/collections-config.json --channelID mainchannel --name resources --version 1.0 --sequence 1 --package-id $(tail -n 1 pkg.txt | awk '\''NF>1{print $NF}'\'')' &
docker exec -it cli-peer0-carrier bash -c 'peer lifecycle chaincode approveformyorg -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem --collections-config /opt/gopath/src/resources/collections-config.json --channelID mainchannel --name resources --version 1.0 --sequence 1 --package-id $(tail -n 1 pkg.txt | awk '\''NF>1{print $NF}'\'')'

docker exec -it cli-peer0-regulator bash -c 'peer lifecycle chaincode commit -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem --collections-config /opt/gopath/src/resources/collections-config.json --channelID mainchannel --name resources --version 1.0 --sequence 1'

sleep 5

docker exec -it cli-peer0-regulator bash -c 'peer chaincode invoke -C mainchannel -n resources -c '\''{"Args":["Create","CPUs","1"]}'\'' -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem'
docker exec -it cli-peer0-carrier bash -c 'peer chaincode invoke -C mainchannel -n resources -c '\''{"Args":["Create","Database Servers","1"]}'\'' -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem'
sleep 5
docker exec -it cli-peer0-regulator bash -c 'peer chaincode query -C mainchannel -n resources -c '\''{"Args":["Index"]}'\'' -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem'
docker exec -it cli-peer1-regulator bash -c 'peer chaincode query -C mainchannel -n resources -c '\''{"Args":["Index"]}'\'' -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem'
docker exec -it cli-peer0-carrier bash -c 'peer chaincode query -C mainchannel -n resources -c '\''{"Args":["Index"]}'\'' -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem'
docker exec -it cli-peer1-carrier bash -c 'peer chaincode query -C mainchannel -n resources -c '\''{"Args":["Index"]}'\'' -o orderer0:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-7054.pem'
```

Okay, now everything should be working as normal. Lets test the apis and make sure they are connected properly.
```bash
cd node-api
node index.js
```

Start the GO api in a different terminal
```bash
cd go-api
go run main.go
``` 

In a third terminal test the apis
```bash
curl localhost:3000/v1/resources
curl localhost:4001/resources
```

You should see this
```bash
☁  k8s-hyperledger-fabric-2.2 [master] ⚡  curl localhost:3000/v1/resources
[{"id":"1","name":"CPUs","resource_type_id":"1","active":true},{"id":"2","name":"Database Servers","resource_type_id":"1","active":true}]%                                                                                           ☁  k8s-hyperledger-fabric-2.2 [master] ⚡  curl localhost:4001/resources
[{"id":"1","name":"CPUs","resource_type_id":"1","active":true},{"id":"2","name":"Database Servers","resource_type_id":"1","active":true}]%                                                                                           ☁  k8s-hyperledger-fabric-2.2 [master] ⚡  
```

Lets run the front end and test it
```bash
cd frontend
npm run serve
```

Everything should work!

