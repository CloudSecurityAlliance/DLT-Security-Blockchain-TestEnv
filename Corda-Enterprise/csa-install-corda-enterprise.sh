#!/usr/bin/env bash
#
# Copyright Kurt Seifried kseifried@cloudsecurityalliance.org CloudSecurityAlliance 2021
# License: Apache 2.0
#
# You can get this script via
# curl https://raw.githubusercontent.com/cloudsecurityalliance/DLT-Security-Blockchain-TestEnv/master/Corda-Enterprise/csa-install-corda-enterprise.sh > csa-install-corda-enterprise.sh
# chmod +x csa-install-corda-enterprise.sh
#
# Runs most stuff as root, it's for testing. I know it's a bad habit.
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
sudo mkdir /opt/corda-enterprise
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
sudo apt-get update
sudo apt-get -y --with-new-pkgs upgrade

# Java
# Suggest we use Azul systems as easiest to download:
# https://docs.azul.com/core/zulu-openjdk/install/debian
#
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9
curl -O https://cdn.azul.com/zulu/bin/zulu-repo_1.0.0-2_all.deb
sudo apt-get install ./zulu-repo_1.0.0-2_all.deb
sudo apt-get update
sudo apt-get upgrade


