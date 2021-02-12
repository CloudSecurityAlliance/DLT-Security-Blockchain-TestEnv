Minikube Portion of the Readme
=====================================

## Kubernetes - Minikube (Local)
[Install Kubernetes and Minikube](https://kubernetes.io/docs/tasks/tools/)
[If OSX here is virtual box](https://www.virtualbox.org/wiki/Mac%20OS%20X%20build%20instructions)
[Kubernetes book](hhttps://www.amazon.com/Devops-2-3-Toolkit-Viktor-Farcic/dp/1789135508/ref=tmm_pap_swatch_0?_encoding=UTF8&sr=8-2)
[K8s Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

sudo kubectl delete -f network/minikube/storage/pvc.yaml
sudo kubectl delete -f network/minikube/storage/setup
sudo minikube delete --all --purge
sudo make full-clean

Okay, now that we've successfully ran the network locally, let's do this on a local kubernetes installation.
```bash
sudo  minikube start --vm-driver=none
sleep 5
sudo kubectl apply -f network/minikube/storage/pvc.yaml
sleep 10
sudo kubectl apply -f network/minikube/storage/setup
```

Now we have storage and we're going to test it. You can do a kubectl get pods to see what pods are up. Here's how I can connect to my containers. You should split your terminal and connect to both.
```bash
☁  k8s-hyperledger-fabric-2.2 [master] ⚡  kubectl get pods
NAME                        READY   STATUS    RESTARTS   AGE
storage-setup-6858b4f776-5pgls   1/1     Running   0          17s
☁  k8s-hyperledger-fabric-2.2 [master] ⚡ 
```

We'll use one of these to setup the files for the network
```bash
storagePod=$(sudo kubectl get pods -o=name | grep storage-setup | sed "s/^.\{4\}//")
echo $storagePod
sudo kubectl exec -it $storagePod -- mkdir -p /host/files/scripts
sudo kubectl exec -it $storagePod -- mkdir -p /host/files/chaincode

sudo kubectl cp ./scripts $storagePod:/host/files
sudo kubectl cp ./network/minikube/configtx.yaml $storagePod:/host/files
sudo kubectl cp ./network/minikube/config.yaml $storagePod:/host/files
sudo kubectl cp ./chaincode/resources $storagePod:/host/files/chaincode
sudo kubectl cp ./chaincode/resource_types $storagePod:/host/files/chaincode
sudo kubectl cp ./fabric-samples/bin $storagePod:/host/files
```

Let's bash into the container and make sure everything copied over properly
```bash
sudo kubectl exec -it $storagePod -- bash
```

Finally ready to start the ca containers
```bash
sudo kubectl apply -f network/minikube/cas
```

Your containers should be up and running. You can check the logs like so and it should l this.
```bash
☁  k8s-hyperledger-fabric-2.2 [master] ⚡  kubectl logs -f orderers-ca-d69cbc664-dzk4f
2020/12/11 04:12:37 [INFO] Created default configuration file at /etc/hyperledger/fabric-ca-server/fabric-ca-server-config.yaml
2020/12/11 04:12:37 [INFO] Starting server in home directory: /etc/hyperledger/fabric-ca-server
...
2020/12/11 04:12:38 [INFO] generating key: &{A:ecdsa S:256}
2020/12/11 04:12:38 [INFO] encoded CSR
2020/12/11 04:12:38 [INFO] signed certificate with serial number 307836600921505839273746385963411812465330101584
2020/12/11 04:12:38 [INFO] Listening on https://0.0.0.0:7054
```

This should generate the crypto-config files necessary for the network. You can check on those files in any of the containers.
```bash
root@storage-setup-6858b4f776-wmlth:/host# cd files
root@storage-setup-6858b4f776-wmlth:/host/files# ls
bin  chaincode	config.yaml  configtx.yaml  crypto-config  scripts
root@storage-setup-6858b4f776-wmlth:/host/files# cd crypto-config/
root@storage-setup-6858b4f776-wmlth:/host/files/crypto-config# ls
ordererOrganizations  peerOrganizations
root@storage-setup-6858b4f776-wmlth:/host/files/crypto-config# cd peerOrganizations/
root@storage-setup-6858b4f776-wmlth:/host/files/crypto-config/peerOrganizations# ls
regulator  carrier
root@storage-setup-6858b4f776-wmlth:/host/files/crypto-config/peerOrganizations# cd regulator/
root@storage-setup-6858b4f776-wmlth:/host/files/crypto-config/peerOrganizations/regulator# ls
msp  peers  users
root@storage-setup-6858b4f776-wmlth:/host/files/crypto-config/peerOrganizations/regulator# cd msp/
root@storage-setup-6858b4f776-wmlth:/host/files/crypto-config/peerOrganizations/regulator/msp# ls
IssuerPublicKey  IssuerRevocationPublicKey  admincerts	cacerts  keystore  signcerts  tlscacerts  user
root@storage-setup-6858b4f776-wmlth:/host/files/crypto-config/peerOrganizations/regulator/msp# cd tlscacerts/

cd /host/files/crypto-config/peerOrganizations/
cd /host/files/crypto-config/peerOrganizations/regulator/msp/tlscacerts
cd /host/files/crypto-config/peerOrganizations/carrier/msp/tlscacerts
cd /host/files/crypto-config/peerOrganizations/importer-bank/msp/tlscacerts
cd /host/files/crypto-config/peerOrganizations/exporter-bank/msp/tlscacerts
cd /host/files/crypto-config/peerOrganizations/importer/msp/tlscacerts
cd /host/files/crypto-config/peerOrganizations/exporter/msp/tlscacerts

```

Time to generate the artifacts inside one of the containers and in the files folder - NOTE: if you are on OSX you might have to load the proper libs `curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.2.2 1.4.7`
```bash
sudo kubectl exec -it $storagePod -- bash
...
cd /host/files
apt-get update; apt-get install curl

rm -rf orderer channels
mkdir -p orderer channels
bin/configtxgen -profile OrdererGenesis -channelID syschannel -outputBlock ./orderer/genesis.block
bin/configtxgen -profile MainChannel -outputCreateChannelTx ./channels/mainchannel.tx -channelID mainchannel
bin/configtxgen -profile MainChannel -outputAnchorPeersUpdate ./channels/regulator-anchors.tx -channelID mainchannel -asOrg regulator
bin/configtxgen -profile MainChannel -outputAnchorPeersUpdate ./channels/carrier-anchors.tx -channelID mainchannel -asOrg carrier
bin/configtxgen -profile MainChannel -outputAnchorPeersUpdate ./channels/importer-bank-anchors.tx -channelID mainchannel -asOrg importer-bank
bin/configtxgen -profile MainChannel -outputAnchorPeersUpdate ./channels/exporter-bank-anchors.tx -channelID mainchannel -asOrg exporter-bank
bin/configtxgen -profile MainChannel -outputAnchorPeersUpdate ./channels/importer-anchors.tx -channelID mainchannel -asOrg importer
bin/configtxgen -profile MainChannel -outputAnchorPeersUpdate ./channels/exporter-anchors.tx -channelID mainchannel -asOrg exporter
```

Let's try to start up the orderers
```bash
sudo kubectl apply -f network/minikube/orderers
```

Go ahead and check the logs and see that the orderers have selected a leader like so
```bash
 1 became follower at term 2 channel=syschannel node=1
2020-12-11 05:20:15.616 UTC [orderer.consensus.etcdraft] Step -> INFO 029 1 [logterm: 1, index: 3, vote: 0] cast MsgVote for 2 [logterm: 1, index: 3] at term 2 channel=syschannel node=1
2020-12-11 05:20:15.634 UTC [orderer.consensus.etcdraft] run -> INFO 02a raft.node: 1 elected leader 2 at term 2 channel=syschannel node=1
2020-12-11 05:20:15.639 UTC [orderer.consensus.etcdraft] run -> INFO 02b Raft leader changed: 0 -> 2 channel=syschannel node=1
```

We should be able to start the peers now
```bash
sudo kubectl apply -f network/minikube/orgs/regulator/couchdb
sudo kubectl apply -f network/minikube/orgs/carrier/couchdb
sudo kubectl apply -f network/minikube/orgs/importer-bank/couchdb
sudo kubectl apply -f network/minikube/orgs/exporter-bank/couchdb
sudo kubectl apply -f network/minikube/orgs/importer/couchdb
sudo kubectl apply -f network/minikube/orgs/exporter/couchdb

sudo kubectl get pods

sudo kubectl apply -f network/minikube/orgs/regulator/
sudo kubectl apply -f network/minikube/orgs/carrier/
sudo kubectl apply -f network/minikube/orgs/importer-bank/
sudo kubectl apply -f network/minikube/orgs/importer/
sudo kubectl apply -f network/minikube/orgs/exporter-bank/
sudo kubectl apply -f network/minikube/orgs/exporter/

sudo kubectl get pods

sudo kubectl apply -f network/minikube/orgs/regulator/cli
sudo kubectl apply -f network/minikube/orgs/carrier/cli
sudo kubectl apply -f network/minikube/orgs/importer-bank/cli
sudo kubectl apply -f network/minikube/orgs/importer/cli
sudo kubectl apply -f network/minikube/orgs/exporter-bank/cli
sudo kubectl apply -f network/minikube/orgs/exporter/cli

sudo kubectl get pods
```


Time to actually test the network
```bash
export regulatorPeer0Pod=$(sudo kubectl get pods -o=name | grep cli-peer0-regulator-deployment | sed "s/^.\{4\}//")
export regulatorPeer1Pod=$(sudo kubectl get pods -o=name | grep cli-peer1-regulator-deployment | sed "s/^.\{4\}//")
export carrierPeer0Pod=$(sudo kubectl get pods -o=name | grep cli-peer0-carrier-deployment | sed "s/^.\{4\}//")
export carrierPeer1Pod=$(sudo kubectl get pods -o=name | grep cli-peer1-carrier-deployment | sed "s/^.\{4\}//")
export importerBankPeer0Pod=$(sudo kubectl get pods -o=name | grep cli-peer0-importer-bank-deployment | sed "s/^.\{4\}//")
export importerBankPeer1Pod=$(sudo kubectl get pods -o=name | grep cli-peer1-importer-bank-deployment | sed "s/^.\{4\}//")
export importerPeer0Pod=$(sudo kubectl get pods -o=name | grep cli-peer0-importer-deployment | sed "s/^.\{4\}//")
export importerPeer1Pod=$(sudo kubectl get pods -o=name | grep cli-peer1-importer-deployment | sed "s/^.\{4\}//")
export exporterBankPeer0Pod=$(sudo kubectl get pods -o=name | grep cli-peer0-exporter-bank-deployment | sed "s/^.\{4\}//")
export exporterBankPeer1Pod=$(sudo kubectl get pods -o=name | grep cli-peer1-exporter-bank-deployment | sed "s/^.\{4\}//")
export exporterPeer0Pod=$(sudo kubectl get pods -o=name | grep cli-peer0-exporter-deployment | sed "s/^.\{4\}//")
export exporterPeer1Pod=$(sudo kubectl get pods -o=name | grep cli-peer1-exporter-deployment | sed "s/^.\{4\}//")

sudo kubectl exec -it $regulatorPeer0Pod -- bash -c 'peer channel create -c mainchannel -f ./channels/mainchannel.tx -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem'

sudo kubectl exec -it $regulatorPeer0Pod -- bash -c 'cp mainchannel.block ./channels/'
sudo kubectl exec -it $regulatorPeer0Pod -- bash -c 'peer channel join -b channels/mainchannel.block'
sudo kubectl exec -it $regulatorPeer1Pod -- bash -c 'peer channel join -b channels/mainchannel.block'
sudo kubectl exec -it $carrierPeer0Pod -- bash -c 'peer channel join -b channels/mainchannel.block'
sudo kubectl exec -it $carrierPeer1Pod -- bash -c 'peer channel join -b channels/mainchannel.block'
sudo kubectl exec -it $importerBankPeer0Pod -- bash -c 'peer channel join -b channels/mainchannel.block'
sudo kubectl exec -it $importerBankPeer1Pod -- bash -c 'peer channel join -b channels/mainchannel.block'
sudo kubectl exec -it $importerPeer0Pod -- bash -c 'peer channel join -b channels/mainchannel.block'
sudo kubectl exec -it $importerPeer1Pod -- bash -c 'peer channel join -b channels/mainchannel.block'
sudo kubectl exec -it $exporterBankPeer0Pod -- bash -c 'peer channel join -b channels/mainchannel.block'
sudo kubectl exec -it $exporterBankPeer1Pod -- bash -c 'peer channel join -b channels/mainchannel.block'
sudo kubectl exec -it $exporterPeer0Pod -- bash -c 'peer channel join -b channels/mainchannel.block'
sudo kubectl exec -it $exporterPeer1Pod -- bash -c 'peer channel join -b channels/mainchannel.block'

sleep 5

sudo kubectl exec -it $regulatorPeer0Pod -- bash -c 'peer channel update -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem -c mainchannel -f channels/regulator-anchors.tx'
sudo kubectl exec -it $carrierPeer0Pod -- bash -c 'peer channel update -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem -c mainchannel -f channels/carrier-anchors.tx'
sudo kubectl exec -it $importerBankPeer0Pod -- bash -c 'peer channel update -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem -c mainchannel -f channels/importer-bank-anchors.tx'
sudo kubectl exec -it $importerPeer0Pod -- bash -c 'peer channel update -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem -c mainchannel -f channels/importer-anchors.tx'
sudo kubectl exec -it $exporterBankPeer0Pod -- bash -c 'peer channel update -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem -c mainchannel -f channels/exporter-bank-anchors.tx'
sudo kubectl exec -it $exporterPeer0Pod -- bash -c 'peer channel update -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem -c mainchannel -f channels/exporter-anchors.tx'

```

Now we are going to install the chaincode - NOTE: Make sure you go mod vendor in each chaincode folder... might need to remove the go.sum depending
```bash
export chaincodePackage='peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1'
sudo kubectl exec -it $regulatorPeer0Pod -- bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1'
sudo kubectl exec -it $regulatorPeer1Pod -- bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1'
sudo kubectl exec -it $carrierPeer0Pod -- bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1'
sudo kubectl exec -it $carrierPeer1Pod -- bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1'
sudo kubectl exec -it $importerBankPeer0Pod -- bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1'
sudo kubectl exec -it $importerBankPeer1Pod -- bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1'
sudo kubectl exec -it $importerPeer0Pod -- bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1'
sudo kubectl exec -it $importerPeer1Pod -- bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1'
sudo kubectl exec -it $exporterBankPeer0Pod -- bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1'
sudo kubectl exec -it $exporterBankPeer1Pod -- bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1'
sudo kubectl exec -it $exporterPeer0Pod -- bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1'
sudo kubectl exec -it $exporterPeer1Pod -- bash -c 'peer lifecycle chaincode package resource_types.tar.gz --path /opt/gopath/src/resource_types --lang golang --label resource_types_1'



sudo kubectl exec -it $regulatorPeer0Pod -- bash -c 'peer lifecycle chaincode install resource_types.tar.gz &> pkg.txt'
sudo kubectl exec -it $regulatorPeer1Pod -- bash -c 'peer lifecycle chaincode install resource_types.tar.gz'
sudo kubectl exec -it $carrierPeer0Pod -- bash -c 'peer lifecycle chaincode install resource_types.tar.gz &> pkg.txt'
sudo kubectl exec -it $carrierPeer1Pod -- bash -c 'peer lifecycle chaincode install resource_types.tar.gz'
sudo kubectl exec -it $importerBankPeer0Pod -- bash -c 'peer lifecycle chaincode install resource_types.tar.gz &> pkg.txt'
sudo kubectl exec -it $importerBankPeer1Pod -- bash -c 'peer lifecycle chaincode install resource_types.tar.gz'
sudo kubectl exec -it $importerPeer0Pod -- bash -c 'peer lifecycle chaincode install resource_types.tar.gz &> pkg.txt'
sudo kubectl exec -it $importerPeer1Pod -- bash -c 'peer lifecycle chaincode install resource_types.tar.gz'
sudo kubectl exec -it $exporterBankPeer0Pod -- bash -c 'peer lifecycle chaincode install resource_types.tar.gz &> pkg.txt'
sudo kubectl exec -it $exporterBankPeer1Pod -- bash -c 'peer lifecycle chaincode install resource_types.tar.gz'
sudo kubectl exec -it $exporterPeer0Pod -- bash -c 'peer lifecycle chaincode install resource_types.tar.gz &> pkg.txt'
sudo kubectl exec -it $exporterPeer1Pod -- bash -c 'peer lifecycle chaincode install resource_types.tar.gz'




sudo kubectl exec -it $regulatorPeer0Pod -- bash -c 'peer lifecycle chaincode approveformyorg -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem --channelID mainchannel --collections-config /opt/gopath/src/resource_types/collections-config.json --name resource_types --version 1.0 --sequence 1 --package-id $(tail -n 1 pkg.txt | awk '\''NF>1{print $NF}'\'')'
sudo kubectl exec -it $carrierPeer0Pod -- bash -c 'peer lifecycle chaincode approveformyorg -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem --collections-config /opt/gopath/src/resource_types/collections-config.json --channelID mainchannel --name resource_types --version 1.0 --sequence 1 --package-id $(tail -n 1 pkg.txt | awk '\''NF>1{print $NF}'\'')'
sudo kubectl exec -it $importerBankPeer0Pod -- bash -c 'peer lifecycle chaincode approveformyorg -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem --collections-config /opt/gopath/src/resource_types/collections-config.json --channelID mainchannel --name resource_types --version 1.0 --sequence 1 --package-id $(tail -n 1 pkg.txt | awk '\''NF>1{print $NF}'\'')'
sudo kubectl exec -it $importerPeer0Pod -- bash -c 'peer lifecycle chaincode approveformyorg -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem --collections-config /opt/gopath/src/resource_types/collections-config.json --channelID mainchannel --name resource_types --version 1.0 --sequence 1 --package-id $(tail -n 1 pkg.txt | awk '\''NF>1{print $NF}'\'')'
sudo kubectl exec -it $exporterBankPeer0Pod -- bash -c 'peer lifecycle chaincode approveformyorg -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem --collections-config /opt/gopath/src/resource_types/collections-config.json --channelID mainchannel --name resource_types --version 1.0 --sequence 1 --package-id $(tail -n 1 pkg.txt | awk '\''NF>1{print $NF}'\'')'
sudo kubectl exec -it $exporterPeer0Pod -- bash -c 'peer lifecycle chaincode approveformyorg -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem --collections-config /opt/gopath/src/resource_types/collections-config.json --channelID mainchannel --name resource_types --version 1.0 --sequence 1 --package-id $(tail -n 1 pkg.txt | awk '\''NF>1{print $NF}'\'')'


sudo kubectl exec -it $regulatorPeer0Pod -- bash -c 'peer lifecycle chaincode commit -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem --channelID mainchannel --collections-config /opt/gopath/src/resource_types/collections-config.json --name resource_types --version 1.0 --sequence 1'
```

Lets go ahead and test this chaincode
```bash
sudo kubectl exec -it $regulatorPeer0Pod -- bash -c 'peer chaincode invoke -C mainchannel -n resource_types -c '\''{"Args":["Create", "1","Parts"]}'\'' -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem'
sleep 5
sudo kubectl exec -it $regulatorPeer0Pod -- bash -c 'peer chaincode query -C mainchannel -n resource_types -c '\''{"Args":["Index"]}'\'' -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem'
```

Lets try the other chaincode
```bash
kubectl exec -it $regulatorPeer0Pod -- bash -c 'peer lifecycle chaincode package resources.tar.gz --path /opt/gopath/src/resources --lang golang --label resources_1'
kubectl exec -it $regulatorPeer1Pod -- bash -c 'peer lifecycle chaincode package resources.tar.gz --path /opt/gopath/src/resources --lang golang --label resources_1'
kubectl exec -it $carrierPeer0Pod -- bash -c 'peer lifecycle chaincode package resources.tar.gz --path /opt/gopath/src/resources --lang golang --label resources_1'
kubectl exec -it $carrierPeer1Pod -- bash -c 'peer lifecycle chaincode package resources.tar.gz --path /opt/gopath/src/resources --lang golang --label resources_1'
kubectl exec -it $importerBankPeer0Pod -- bash -c 'peer lifecycle chaincode package resources.tar.gz --path /opt/gopath/src/resources --lang golang --label resources_1'
kubectl exec -it $importerBankPeer1Pod -- bash -c 'peer lifecycle chaincode package resources.tar.gz --path /opt/gopath/src/resources --lang golang --label resources_1'
kubectl exec -it $importerPeer0Pod -- bash -c 'peer lifecycle chaincode package resources.tar.gz --path /opt/gopath/src/resources --lang golang --label resources_1'
kubectl exec -it $importerPeer1Pod -- bash -c 'peer lifecycle chaincode package resources.tar.gz --path /opt/gopath/src/resources --lang golang --label resources_1'
kubectl exec -it $exporterBankPeer0Pod -- bash -c 'peer lifecycle chaincode package resources.tar.gz --path /opt/gopath/src/resources --lang golang --label resources_1'
kubectl exec -it $exporterBankPeer1Pod -- bash -c 'peer lifecycle chaincode package resources.tar.gz --path /opt/gopath/src/resources --lang golang --label resources_1'
kubectl exec -it $exporterPeer0Pod -- bash -c 'peer lifecycle chaincode package resources.tar.gz --path /opt/gopath/src/resources --lang golang --label resources_1'
kubectl exec -it $exporterPeer1Pod -- bash -c 'peer lifecycle chaincode package resources.tar.gz --path /opt/gopath/src/resources --lang golang --label resources_1'



kubectl exec -it $regulatorPeer0Pod -- bash -c 'peer lifecycle chaincode install resources.tar.gz &> pkg.txt'
kubectl exec -it $regulatorPeer1Pod -- bash -c 'peer lifecycle chaincode install resources.tar.gz'
kubectl exec -it $carrierPeer0Pod -- bash -c 'peer lifecycle chaincode install resources.tar.gz &> pkg.txt'
kubectl exec -it $carrierPeer1Pod -- bash -c 'peer lifecycle chaincode install resources.tar.gz'
kubectl exec -it $importerBankPeer0Pod -- bash -c 'peer lifecycle chaincode install resources.tar.gz &> pkg.txt'
kubectl exec -it $importerBankPeer1Pod -- bash -c 'peer lifecycle chaincode install resources.tar.gz'
kubectl exec -it $importerPeer0Pod -- bash -c 'peer lifecycle chaincode install resources.tar.gz &> pkg.txt'
kubectl exec -it $importerPeer1Pod -- bash -c 'peer lifecycle chaincode install resources.tar.gz'
kubectl exec -it $exporterBankPeer0Pod -- bash -c 'peer lifecycle chaincode install resources.tar.gz &> pkg.txt'
kubectl exec -it $exporterBankPeer1Pod -- bash -c 'peer lifecycle chaincode install resources.tar.gz'
kubectl exec -it $exporterPeer0Pod -- bash -c 'peer lifecycle chaincode install resources.tar.gz &> pkg.txt'
kubectl exec -it $exporterPeer1Pod -- bash -c 'peer lifecycle chaincode install resources.tar.gz'



kubectl exec -it $regulatorPeer0Pod -- bash -c 'peer lifecycle chaincode approveformyorg -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem --channelID mainchannel --collections-config /opt/gopath/src/resources/collections-config.json --name resources --version 1.0 --sequence 1 --package-id $(tail -n 1 pkg.txt | awk '\''NF>1{print $NF}'\'')'
kubectl exec -it $carrierPeer0Pod -- bash -c 'peer lifecycle chaincode approveformyorg -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem --channelID mainchannel --collections-config /opt/gopath/src/resources/collections-config.json --name resources --version 1.0 --sequence 1 --package-id $(tail -n 1 pkg.txt | awk '\''NF>1{print $NF}'\'')'
kubectl exec -it $importerBankPeer0Pod -- bash -c 'peer lifecycle chaincode approveformyorg -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem --channelID mainchannel --collections-config /opt/gopath/src/resources/collections-config.json --name resources --version 1.0 --sequence 1 --package-id $(tail -n 1 pkg.txt | awk '\''NF>1{print $NF}'\'')'
kubectl exec -it $importerPeer0Pod -- bash -c 'peer lifecycle chaincode approveformyorg -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem --channelID mainchannel --collections-config /opt/gopath/src/resources/collections-config.json --name resources --version 1.0 --sequence 1 --package-id $(tail -n 1 pkg.txt | awk '\''NF>1{print $NF}'\'')'
kubectl exec -it $exporterBankPeer0Pod -- bash -c 'peer lifecycle chaincode approveformyorg -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem --channelID mainchannel --collections-config /opt/gopath/src/resources/collections-config.json --name resources --version 1.0 --sequence 1 --package-id $(tail -n 1 pkg.txt | awk '\''NF>1{print $NF}'\'')'
kubectl exec -it $exporterPeer0Pod -- bash -c 'peer lifecycle chaincode approveformyorg -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem --channelID mainchannel --collections-config /opt/gopath/src/resources/collections-config.json --name resources --version 1.0 --sequence 1 --package-id $(tail -n 1 pkg.txt | awk '\''NF>1{print $NF}'\'')'



kubectl exec -it $regulatorPeer0Pod -- bash -c 'peer lifecycle chaincode commit -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem --channelID mainchannel --collections-config /opt/gopath/src/resources/collections-config.json --name resources --version 1.0 --sequence 1'

sleep 5

kubectl exec -it $regulatorPeer0Pod -- bash -c 'peer chaincode invoke -C mainchannel -n resources -c '\''{"Args":["Create","CPUs","1"]}'\'' -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem'
kubectl exec -it $regulatorPeer0Pod -- bash -c 'peer chaincode invoke -C mainchannel -n resources -c '\''{"Args":["Create","Database Servers","1"]}'\'' -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem'
kubectl exec -it $carrierPeer0Pod -- bash -c 'peer chaincode invoke -C mainchannel -n resources -c '\''{"Args":["Create","Mainframe Boards","1"]}'\'' -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem'
sleep 5
kubectl exec -it $regulatorPeer0Pod -- bash -c 'peer chaincode query -C mainchannel -n resources -c '\''{"Args":["Index"]}'\'' -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem'
kubectl exec -it $regulatorPeer1Pod -- bash -c 'peer chaincode query -C mainchannel -n resources -c '\''{"Args":["Index"]}'\'' -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem'
kubectl exec -it $carrierPeer0Pod -- bash -c 'peer chaincode query -C mainchannel -n resources -c '\''{"Args":["Index"]}'\'' -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem'
kubectl exec -it $carrierPeer1Pod -- bash -c 'peer chaincode query -C mainchannel -n resources -c '\''{"Args":["Index"]}'\'' -o orderer0-service:7050 --tls --cafile=/etc/hyperledger/orderers/msp/tlscacerts/orderers-ca-service-7054.pem'
```

Start the API
```bash
kubectl apply -f network/minikube/backend
```

Get the address for the nodeport
```bash
minikube service api-service-nodeport --url
```
