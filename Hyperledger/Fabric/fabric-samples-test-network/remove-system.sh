#!/usr/bin/env bash
#
# Copyright Kurt Seifried kseifried@cloudsecurityalliance.org CloudSecurityAlliance 2021
# License: Apache 2.0
#
echo "THIS REMOVES ALL DOCKER IMAGES, VOLUMES and /opt/hyperledger/"
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
