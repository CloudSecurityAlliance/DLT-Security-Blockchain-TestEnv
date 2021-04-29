#!/usr/bin/env bash
#
# Copyright Kurt Seifried kseifried@cloudsecurityalliance.org CloudSecurityAlliance 2021
# License: Apache 2.0
#
# You can get this script via
# curl https://raw.githubusercontent.com/cloudsecurityalliance/DLT-Security-Blockchain-TestEnv/master/Corda/samples-java/csa-install-corda-samples-java-basiccordapp.sh > csa-install-corda-samples-java-basiccordapp.sh
# chmod +x csa-install-corda-samples-java-basiccordapp.sh
#
# This script uses a forked version of samples-java
#
# Check for Ubuntu 18.04
#

PRETTY_NAME=`grep PRETTY_NAME /etc/os-release`

if [[ $PRETTY_NAME =~ "PRETTY_NAME=\"Ubuntu 18.04.5 LTS\"" ]]; then
    echo "Ubuntu detected 18.04, continuing"
else
    echo "This only works reliably on Ubuntu. You can manually edit this check to bypass it (for e.g. Debian)."
    exit
fi

#
# Check for free disk space
# /opt/gradle (1 gig) and /opt/corda/ (2 gigs)
#
echo "Making directory /opt/hyperledger"
mkdir /opt/gradle
echo "Making directory /var/lib/docker/"
mkdir /opt/corda
#
DIR_GRADLE=`df -m /opt/gradle/ --output=avail | grep "[0-9]"`
DIR_CORDA=`df -m /opt/corda/ --output=avail | grep "[0-9]"`

if [ $DIR_GRADLE -lt 1024 ] && [ $DIR_CORDA -lt 2048 ]; then
    echo "Not enough space found in  /opt/hyperledger/ and/or  /var/lib/docker/"
else
    echo "Found enough free space, continuing"
fi

#
# Update the system
#
apt-get update
apt-get -y --with-new-pkgs upgrade
#
# Install dependancies
#
apt-get -y install openjdk-8-jdk unzip wget
#
# Install Gradle
#
# TODO: check if Gradle 5.6.4 is already installed - dir check?
#
cd /opt/gradle
wget https://services.gradle.org/distributions/gradle-5.6.4-bin.zip
unzip gradle-5.6.4-bin.zip
#
# Add gradle bin to path now, also in .profile later
#
export PATH="$PATH:/opt/gradle/gradle-5.6.4/bin"

echo "Setting up root paths for Hyperledger commands (log out and back in for it to work)"
cat << 'EOF' >> /root/.profile
#
# Add gradle to path
#
export PATH="$PATH:/opt/gradle/gradle-5.6.4/bin"
EOF
#
# Install corda sample app
#
cd /opt/corda/
git clone https://github.com/corda/samples-java
#
# Change localhost to global listening. DANGEROUS
#
cd /opt/corda/samples-java/Basic/cordapp-example
sed 's/localhost/0.0.0.0/' build.gradle > 2 ; mv -f 2 build.gradle
#
# Add additional parties
#
# Remove the final "}"
#
tac build.gradle | sed "0,/}/s///"| tac > 2
curl -fsSL https://raw.githubusercontent.com/cloudsecurityalliance/DLT-Security-Blockchain-TestEnv/master/Corda/samples-java/Basic/cordapp-example/build.gradle-4-m\
ore-parties >> 2
mv -f 2 build.gradle
#
# Set secure passwords:
#
PartyA_password=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c10`
PartyB_password=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c10`
#
# This uses sed to change the first instance of "test", to "[random]", so the first one gets PartyA and the second one gets PartyB
# Later we need to echo this, suggest we grep it from the build.gradle so we show what was actually used
#
cd /opt/corda/samples-java/Basic/cordapp-example

sed "0,/\"test\",/s//\"$PartyA_password\",/" build.gradle > 2 ; mv -f 2 build.gradle
sed "0,/\"test\",/s//\"$PartyB_password\",/" build.gradle > 2 ; mv -f 2 build.gradle
# TODO: change username/password to something random?
#
./gradlew clean deployNodes

#
# Run the corda thing
#
cd /opt/corda/samples-java/Basic/cordapp-example/build/nodes/
./runnodes
#
# Sleep for 20 seconds to let the server stuff start
#
sleep 20
#
# Print out the passwords/accounts
#
echo "passwords and login for PartyA and PartyB:"
echo ""
grep "rpcUsers =" /opt/corda/samples-java/Basic/cordapp-example/build.gradle
