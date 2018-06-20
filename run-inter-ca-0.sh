#!/bin/bash
export FABRIC_CA_SERVER_HOME="/etc/hyperledger/fabric-ca/ica-org0"
export FABRIC_CA_SERVER_CA_NAME="localhost"
export FABRIC_CA_SERVER_INTERMEDIATE_TLS_CERTFILES="/home/datlv/data/org0-ca-cert.pem"
export FABRIC_CA_SERVER_CSR_HOSTS="localhost"
export FABRIC_CA_SERVER_TLS_ENABLED=true
export FABRIC_CA_SERVER_DEBUG=true
BOOTSTRAP_USER_PASS="ica-org0-admin:ica-org0-adminpw"
PARENT_URL="https://rca-org0-admin:rca-org0-adminpw@localhost:7054"
TARGET_CHAINFILE="/home/datlv/data/org0-ca-chain.pem"
ORG="org0"
FABRIC_ORGS="org0 org1 org2"
set -e

# Initialize the root CA
$GOPATH/src/github.com/hyperledger/fabric-ca/cmd/fabric-ca-server/fabric-ca-server init -b $BOOTSTRAP_USER_PASS -u $PARENT_URL

# Copy the root CA's signing certificate to the data directory to be used by others
cp $FABRIC_CA_SERVER_HOME/ca-chain.pem $TARGET_CHAINFILE

# Add the custom orgs
for o in $FABRIC_ORGS; do
   aff=$aff"\n   $o: []"
done
aff="${aff#\\n   }"
sed -i "/affiliations:/a \\   $aff" \
   $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml
sed -i "s/port: 7054/port: 7055/g" \
   $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml
# Start the root CA
# $GOPATH/src/github.com/hyperledger/fabric-ca/cmd/fabric-ca-server/fabric-ca-server start -b "ica-org0-admin:ica-org0-adminpw" -u "https://rca-org0-admin:rca-org0-adminpw@localhost:7054"
$GOPATH/src/github.com/hyperledger/fabric-ca/cmd/fabric-ca-server/fabric-ca-server start -b $BOOTSTRAP_USER_PASS"@localhost:7055" -u $PARENT_URL