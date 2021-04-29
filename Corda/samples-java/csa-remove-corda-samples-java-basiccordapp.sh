#!/usr/bin/env bash
#
# Copyright Kurt Seifried kseifried@cloudsecurityalliance.org CloudSecurityAlliance 2021
# License: Apache 2.0
#
# You can get this script via
# curl https://raw.githubusercontent.com/cloudsecurityalliance/DLT-Security-Blockchain-TestEnv/master/Corda/samples-java/csa-remove-corda-samples-java-basiccordapp.sh > csa-remove-corda-samples-java-basiccordapp.sh
# chmod +x csa-remove-corda-samples-java-basiccordapp.sh
#
echo "HIT CTRL-C NOW IF YOU DIDN'T MEAN TO RUN THIS"
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
# Kill all the java processes
#
ps xauww  | grep net.corda.node.Corda | grep -v grep | cut -d" " -f7 | xargs kill
#
# Forcibly remove /opt/corda/samples-java/
#
rm -rf /opt/corda/samples-java/
#
# Leave gradle alone?
#
