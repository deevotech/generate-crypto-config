#!/bin/bash
export FABRIC_CA_SERVER_HOME="/etc/hyperledger/fabric-ca"
export FABRIC_CA_SERVER_TLS_ENABLED=true
export FABRIC_CA_SERVER_CSR_CN="localhost"
export FABRIC_CA_SERVER_CSR_HOSTS="localhost"
export FABRIC_CA_SERVER_DEBUG=true
BOOTSTRAP_USER_PASS="rca-org0-admin:rca-org0-adminpw"
TARGET_CERTFILE="/home/datlv/data/org0-ca-cert.pem"
FABRIC_ORGS="org0 org1 org2"
set -e

# Initialize the root CA
$GOPATH/src/github.com/hyperledger/fabric-ca/cmd/fabric-ca-server/fabric-ca-server init -b $BOOTSTRAP_USER_PASS

# Copy the root CA's signing certificate to the data directory to be used by others
cp $FABRIC_CA_SERVER_HOME/ca-cert.pem $TARGET_CERTFILE

# Add the custom orgs
for o in $FABRIC_ORGS; do
   aff=$aff"\n   $o: []"
done
aff="${aff#\\n   }"
sed -i "/affiliations:/a \\   $aff" \
   $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml

# Start the root CA
$GOPATH/src/github.com/hyperledger/fabric-ca/cmd/fabric-ca-server/fabric-ca-server start -b rca-org0-admin:rca-org0-adminpw
