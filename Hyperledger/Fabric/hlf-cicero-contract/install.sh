
#
# You must install `jq` to run this script
#
# Run this script from the root of the hlf-cicero-contract directory
# the script packages the chaincode and then installs it onto org1 and org2
# it is based on: https://hyperledger-fabric.readthedocs.io/en/master/deploy_chaincode.html#install-the-chaincode-package

# set these two values based on your HLF install location
export HLF_TEST_NETWORK=${HLF_INSTALL_DIR}/test-network
# end set

rm *.tar.gz
npm install

export PATH=${HLF_INSTALL_DIR}/bin:$PATH
export FABRIC_CFG_PATH=${HLF_INSTALL_DIR}/config/
peer version

# package the chaincode
export CC_VERSION=$(cat package.json | jq -r ".version")
echo Packaging chaincode ${CC_VERSION}
peer lifecycle chaincode package cicero_${CC_VERSION}.tar.gz --path . --lang node --label cicero_${CC_VERSION}

# install on org1
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

peer lifecycle chaincode install cicero_${CC_VERSION}.tar.gz
echo Installed on org1

# install on org2
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_TLS_ROOTCERT_FILE=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051

peer lifecycle chaincode install cicero_${CC_VERSION}.tar.gz
echo Installed on org2

# install on org3
export CORE_PEER_LOCALMSPID="Org3MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
export CORE_PEER_TLS_ROOTCERT_FILE=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
export CORE_PEER_ADDRESS=localhost:11051

peer lifecycle chaincode install cicero_${CC_VERSION}.tar.gz
echo Installed on org3

# install on org4
export CORE_PEER_LOCALMSPID="Org4MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org4.example.com/peers/peer0.org4.example.com/tls/ca.crt
export CORE_PEER_TLS_ROOTCERT_FILE=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org4.example.com/peers/peer0.org4.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org4.example.com/users/Admin@org4.example.com/msp
export CORE_PEER_ADDRESS=localhost:13051

peer lifecycle chaincode install cicero_${CC_VERSION}.tar.gz
echo Installed on org4

# install on org5
export CORE_PEER_LOCALMSPID="Org5MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org5.example.com/peers/peer0.org5.example.com/tls/ca.crt
export CORE_PEER_TLS_ROOTCERT_FILE=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org5.example.com/peers/peer0.org5.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org5.example.com/users/Admin@org5.example.com/msp
export CORE_PEER_ADDRESS=localhost:15051

peer lifecycle chaincode install cicero_${CC_VERSION}.tar.gz
echo Installed on org5

# install on org6
export CORE_PEER_LOCALMSPID="Org6MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org6.example.com/peers/peer0.org6.example.com/tls/ca.crt
export CORE_PEER_TLS_ROOTCERT_FILE=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org6.example.com/peers/peer0.org6.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org6.example.com/users/Admin@org6.example.com/msp
export CORE_PEER_ADDRESS=localhost:17051

peer lifecycle chaincode install cicero_${CC_VERSION}.tar.gz
echo Installed on org6

# get the last installed package id for the CC version
peer lifecycle chaincode queryinstalled
export CC_PACKAGE_ID=$(peer lifecycle chaincode queryinstalled --output json | jq -r "[.installed_chaincodes[] | select(.label == \"cicero_${CC_VERSION}\") | .package_id][-1]")
echo "Chaincode package id: " ${CC_PACKAGE_ID}

# get the sequence number to use
export CC_SEQUENCE=$(peer lifecycle chaincode querycommitted --channelID mychannel cicero --output json | jq -r ".chaincode_definitions[0].sequence+1")
echo "Sequence number" ${CC_SEQUENCE}

# approveformyorg
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name cicero --version ${CC_VERSION} --package-id $CC_PACKAGE_ID --sequence ${CC_SEQUENCE} --tls --cafile ${HLF_TEST_NETWORK}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
echo "Approved for org2"

# approve chaincode org1
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_MSPCONFIGPATH=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051

peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name cicero --version ${CC_VERSION} --package-id $CC_PACKAGE_ID --sequence ${CC_SEQUENCE} --tls --cafile ${HLF_TEST_NETWORK}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
echo "Approved for org1"

# approve chaincode org2
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_MSPCONFIGPATH=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:9051

peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name cicero --version ${CC_VERSION} --package-id $CC_PACKAGE_ID --sequence ${CC_SEQUENCE} --tls --cafile ${HLF_TEST_NETWORK}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
echo "Approved for org2"

# approve chaincode org3
export CORE_PEER_LOCALMSPID="Org3MSP"
export CORE_PEER_MSPCONFIGPATH=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:11051

peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name cicero --version ${CC_VERSION} --package-id $CC_PACKAGE_ID --sequence ${CC_SEQUENCE} --tls --cafile ${HLF_TEST_NETWORK}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
echo "Approved for org3"

# approve chaincode org4
export CORE_PEER_LOCALMSPID="Org4MSP"
export CORE_PEER_MSPCONFIGPATH=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org4.example.com/users/Admin@org4.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org4.example.com/peers/peer0.org4.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:13051

peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name cicero --version ${CC_VERSION} --package-id $CC_PACKAGE_ID --sequence ${CC_SEQUENCE} --tls --cafile ${HLF_TEST_NETWORK}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
echo "Approved for org4"

# approve chaincode org5
export CORE_PEER_LOCALMSPID="Org5MSP"
export CORE_PEER_MSPCONFIGPATH=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org5.example.com/users/Admin@org5.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org5.example.com/peers/peer0.org5.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:15051

peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name cicero --version ${CC_VERSION} --package-id $CC_PACKAGE_ID --sequence ${CC_SEQUENCE} --tls --cafile ${HLF_TEST_NETWORK}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
echo "Approved for org5"

# approve chaincode org6
export CORE_PEER_LOCALMSPID="Org6MSP"
export CORE_PEER_MSPCONFIGPATH=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org6.example.com/users/Admin@org6.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${HLF_TEST_NETWORK}/organizations/peerOrganizations/org6.example.com/peers/peer0.org6.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:17051

peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com \
     --channelID mychannel --name cicero --version ${CC_VERSION} --package-id $CC_PACKAGE_ID --sequence ${CC_SEQUENCE} \
     --tls --cafile ${HLF_TEST_NETWORK}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
echo "Approved for org6"


peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name cicero --version ${CC_VERSION} --sequence ${CC_SEQUENCE} \
     --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --output json
echo "checkcommitreadiness"

# we commit the chaincode
peer lifecycle chaincode commit -o localhost:7050 \
     --ordererTLSHostnameOverride orderer.example.com \
     --channelID mychannel \
     --name cicero \
     --version ${CC_VERSION} \
     --sequence ${CC_SEQUENCE} \
     --tls --cafile ${HLF_TEST_NETWORK}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
     --peerAddresses localhost:7051 --tlsRootCertFiles ${HLF_TEST_NETWORK}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
     --peerAddresses localhost:9051 --tlsRootCertFiles ${HLF_TEST_NETWORK}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
     --peerAddresses localhost:11051 --tlsRootCertFiles ${HLF_TEST_NETWORK}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt \
     --peerAddresses localhost:13051 --tlsRootCertFiles ${HLF_TEST_NETWORK}/organizations/peerOrganizations/org4.example.com/peers/peer0.org4.example.com/tls/ca.crt \
     --peerAddresses localhost:15051 --tlsRootCertFiles ${HLF_TEST_NETWORK}/organizations/peerOrganizations/org5.example.com/peers/peer0.org5.example.com/tls/ca.crt \
     --peerAddresses localhost:17051 --tlsRootCertFiles ${HLF_TEST_NETWORK}/organizations/peerOrganizations/org6.example.com/peers/peer0.org6.example.com/tls/ca.crt
echo "chaincode committed"
