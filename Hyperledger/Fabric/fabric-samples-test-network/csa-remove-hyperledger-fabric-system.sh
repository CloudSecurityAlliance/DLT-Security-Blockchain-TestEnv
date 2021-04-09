#!/usr/bin/env bash
#
# Copyright Kurt Seifried kseifried@cloudsecurityalliance.org CloudSecurityAlliance 2021
# License: Apache 2.0
#
# curl https://raw.githubusercontent.com/cloudsecurityalliance/DLT-Security-Blockchain-TestEnv/master/Hyperledger/Fabric/fabric-samples-test-network/csa-remove-hyperledger-fabric-system.sh > csa-remove-hyperledger-fabric-system.sh
#
echo "HIT CTRL-C NOW ID YOU DIDN'T MEAN TO RUN THIS"
echo "5"
sleep 1
echo "4"
sleep 1
echo "3"
sleep 1
echo "2"
sleep 1
echo "1"
sleep 1
#
# KILL all running dockers
#
docker ps | cut -d" " -f1 | grep -v "^CONTAINER" | xargs docker kill
# 
# Remove all volumes
#
docker volume prune -f
#
# Remove all containers/builds/etc
#
docker system prune -a -f
#
# Remove the source dir
#
rm -rf /opt/hyperledger/*.sh
rm -rf /opt/hyperledger/fabric-samples/
