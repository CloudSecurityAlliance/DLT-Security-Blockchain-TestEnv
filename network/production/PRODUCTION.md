Kubernetes Production portion of the Readme
===============================================

## Kubernetes - Minikube (Production)

- [AWS Install - depends on your OS](https://linuxhint.com/install_aws_cli_ubuntu/)
- Now, need to configure AWS. Need to get API keys for aws.
- login to AWS and create a user under IAM. You need to click the box for API access
- you will get an Access Key ID and a Secret Access Key
- run the aws configure command and enter those credentials. I also use us-west-1 and json for the other two options

```bash
☁  k8s-hyperledger-fabric-2.2 [master] ⚡  aws configure
AWS Access Key ID [None]: <ID>
AWS Secret Access Key [None]: <secret>
Default region name [None]: us-west-1
Default output format [None]: json
☁  k8s-hyperledger-fabric-2.2 [master] ⚡
```

[Installing KOPS](https://kops.sigs.k8s.io/getting_started/install/)
[READ THIS!!!](https://github.com/kubernetes/kops/blob/master/docs/getting_started/aws.md#setup-iam-user)

- You need to setup an s3 bucket in the same zone as your AWS config and set the appropriate kops bash config
```bash
export KOPS_CLUSTER_NAME=hyperledger.k8s.local
export KOPS_STATE_STORE=s3://<name of your bucket>
export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
```

Time to create the cluster
```bash
ssh-keygen
(No passphrase)

kops create cluster \
    --zones us-west-1b,us-west-1c \
    --node-count 3 \
    --master-zones us-west-1b,us-west-1c \
    --master-count 3 \
    --authorization AlwaysAllow --yes \
    --master-volume-size 40 \
    --node-volume-size 20
```

To delete the cluster
```bash
kops delete cluster --yes
```

You can edit the nodes
```bash
kops edit ig nodes
```

Or the masters
```bash
kops edit ig masters
```

After the cluster is created, need to add some secrets to the network
```bash
sudo kubectl create secret generic couchdb --from-literal username=appbootup --from-literal password=1234

kubectl create secret docker-registry regcred \
    --docker-server=https://index.docker.io/v1/ \
    --docker-username=sachinsr \
    --docker-password=<password> \
    --docker-email=<email>
```

Adding nginx to our network
```bash
sudo kubectl apply -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/ingress-nginx/v1.6.0.yaml

sudo kubectl create secret tls csa-hyperledger.com --key ~/csa-hyperledger.com/privkey.pem --cert ~/csa-hyperledger.com/cert.pem

sudo kubectl apply -f network/production/ingress-nginx.yaml
```

Now, lets add the NFS file system. Go ahead and login to your AWS account and go to EFS. Create a NFS file system in the same REGION as the cluster and make sure to SET THE VPC the same as the network. VERY IMPORTANT!!!! Also, create mount points and set them to include ALL of the permissions for the network (should be for of them). Now, we can create the storage by using the PV and PVC yaml files. We're going to use multiple PVC's just to show how to do that.
```bash
sudo kubectl apply -f network/production/storage/pv.yaml 
sudo kubectl apply -f network/production/storage/pvc.yaml
sudo kubectl apply -f network/minikube/storage/setup 
```

Bash into the containers, create a file and make sure it's available in the other containers. Make sure you do it in the /host folder because that's the folder that's mounted.
```bash
☁  k8s-hyperledger-fabric-2.2 [master] ⚡  kubectl get pods
NAME                        READY   STATUS              RESTARTS   AGE
storage-setup-657d584cc7-qdgzx   0/1     ContainerCreating   0          24s
☁  k8s-hyperledger-fabric-2.2 [master] ⚡  kubectl exec -it storage-setup-657d584cc7-qdgzx bash
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
root@storage-setup-657d584cc7-qdgzx:/# cd host/file
bash: cd: host/file: No such file or directory
root@storage-setup-657d584cc7-qdgzx:/# cd host/files
bash: cd: host/files: No such file or directory
root@storage-setup-657d584cc7-qdgzx:/# cd host
root@storage-setup-657d584cc7-qdgzx:/host# mkdir files
root@storage-setup-657d584cc7-qdgzx:/host# ls
files
root@storage-setup-657d584cc7-qdgzx:/host# echo "Hello World" >> test.txt
root@storage-setup-657d584cc7-qdgzx:/host#
```

Other terminal
```bash
☁  k8s-hyperledger-fabric-2.2 [master] ⚡  kubectl get pods
NAME                        READY   STATUS    RESTARTS   AGE
storage-setup-657d584cc7-qdgzx   1/1     Running   0          40s
☁  k8s-hyperledger-fabric-2.2 [master] ⚡  kubectl exec -it storage-setup-fdcd6dfc5-v7p28 -- bash
root@storage-setup-fdcd6dfc5-v7p28:/# cd host
root@storage-setup-fdcd6dfc5-v7p28:/host# cat test.txt
Hello World
root@storage-setup-fdcd6dfc5-v7p28:/host#
```

Okay, now we can just create the network the same as we would in minikube.
```bash
☁  k8s-hyperledger-fabric-2.2 [master] ⚡  kubectl get pods
NAME                        READY   STATUS    RESTARTS   AGE
storage-setup-6858b4f776-5pgls   1/1     Running   0          17s
storage-setup-6858b4f776-q92vv   1/1     Running   0          17s
☁  k8s-hyperledger-fabric-2.2 [master] ⚡ 
```

We'll use one of these to setup the files for the network
```bash
kubectl exec -it $(kubectl get pods -o=name | grep storage-setup | sed "s/^.\{4\}//") -- mkdir -p /host/files/scripts
kubectl exec -it $(kubectl get pods -o=name | grep storage-setup | sed "s/^.\{4\}//") -- mkdir -p /host/files/chaincode

kubectl cp ./scripts $(kubectl get pods -o=name | grep storage-setup | sed "s/^.\{4\}//"):/host/files
kubectl cp ./network/production/configtx.yaml $(kubectl get pods -o=name | grep storage-setup | sed "s/^.\{4\}//"):/host/files
kubectl cp ./network/production/config.yaml $(kubectl get pods -o=name | grep storage-setup | sed "s/^.\{4\}//"):/host/files
kubectl cp ./chaincode/resources $(kubectl get pods -o=name | grep storage-setup | sed "s/^.\{4\}//"):/host/files/chaincode
kubectl cp ./chaincode/resource_types $(kubectl get pods -o=name | grep storage-setup | sed "s/^.\{4\}//"):/host/files/chaincode
kubectl cp ~/bin $(kubectl get pods -o=name | grep storage-setup | sed "s/^.\{4\}//"):/host/files
```


Let's bash into the container and make sure everything copied over properly
```bash
kubectl exec -it $(kubectl get pods -o=name | grep storage-setup | sed "s/^.\{4\}//") bash
```

Finally ready to start the ca containers
```bash
kubectl apply -f network/minikube/cas
```

Your containers should be up and running. You can check the logs like so and it should look liek this.
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
```

Time to generate the artifacts inside one of the containers and in the files folder
```bash
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

sudo kubectl apply -f network/minikube/orgs/regulator/
sudo kubectl apply -f network/minikube/orgs/carrier/
sudo kubectl apply -f network/minikube/orgs/importer-bank/
sudo kubectl apply -f network/minikube/orgs/importer/
sudo kubectl apply -f network/minikube/orgs/exporter-bank/
sudo kubectl apply -f network/minikube/orgs/exporter/

sudo kubectl apply -f network/minikube/orgs/regulator/cli
sudo kubectl apply -f network/minikube/orgs/carrier/cli
sudo kubectl apply -f network/minikube/orgs/importer-bank/cli
sudo kubectl apply -f network/minikube/orgs/importer/cli
sudo kubectl apply -f network/minikube/orgs/exporter-bank/cli
sudo kubectl apply -f network/minikube/orgs/exporter/cli
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

Startup the api and the web app
```bash
kubectl apply -f network/production/backend/
kubectl apply -f network/production/frontend
```

To delete the cluster
```bash
kops delete cluster --yes
```
