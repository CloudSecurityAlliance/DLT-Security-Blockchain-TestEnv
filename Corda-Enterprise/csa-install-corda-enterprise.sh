#!/usr/bin/env bash
#
# Copyright Kurt Seifried kseifried@cloudsecurityalliance.org CloudSecurityAlliance 2021
# License: Apache 2.0
#
# You can get this script via
# curl https://raw.githubusercontent.com/cloudsecurityalliance/DLT-Security-Blockchain-TestEnv/master/Corda-Enterprise/csa-install-corda-enterprise.sh > csa-install-corda-enterprise.sh
# chmod +x csa-install-corda-enterprise.sh
#
# Runs as root, it's for testing. I know it's a bad habit.
#
# Check for Ubuntu 18.04
#

PRETTY_NAME=`grep PRETTY_NAME /etc/os-release`

if [[ $PRETTY_NAME =~ "PRETTY_NAME=\"Ubuntu 18.04.6 LTS\"" ]]; then
    echo "Ubuntu detected 18.04, continuing"
else
    echo "This only works reliably on Ubuntu. You can manually edit this check to bypass it (for e.g. Debian)."
    exit
fi

#
# Check for free disk space
# /opt/corda/ (2 gigs)
#
echo "Making directory /opt/corda-enterprise"
mkdir /opt/corda-enterprise
#
DIR_CORDA=`df -m /opt/corda-enterprise/ --output=avail | grep "[0-9]"`

if [ $DIR_CORDA -lt 2048 ]; then
    echo "Not enough space found in  /opt/corda-enterprise/ and/or  /var/lib/docker/"
else
    echo "Found enough free space, continuing"
fi

#
# Update the system
#
apt-get update
apt-get -y --with-new-pkgs upgrade

