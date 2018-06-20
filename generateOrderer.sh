#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
set -e

source $(dirname "$0")/env.sh

export FABRIC_CA_CLIENT_HOME=/etc/hyperledger/orderer
export FABRIC_CA_CLIENT_TLS_CERTFILES=/home/datlv/data/org0-ca-chain.pem
export ENROLLMENT_URL=https://orderer1-org0:orderer1-org0pw@localhost:7055
export ORDERER_HOME=/etc/hyperledger/orderer
export ORDERER_HOST=orderer1-org0
export ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
export ORDERER_GENERAL_GENESISMETHOD=file
export ORDERER_GENERAL_GENESISFILE=/home/datlv/data/genesis.block
export ORDERER_GENERAL_LOCALMSPID=org0MSP
export ORDERER_GENERAL_LOCALMSPDIR=/etc/hyperledger/orderer/msp
export ORDERER_GENERAL_TLS_ENABLED=true
export ORDERER_GENERAL_TLS_PRIVATEKEY=/etc/hyperledger/orderer/tls/server.key
export ORDERER_GENERAL_TLS_CERTIFICATE=/etc/hyperledger/orderer/tls/server.crt
export ORDERER_GENERAL_TLS_ROOTCAS=[/home/datlv/data/org0-ca-chain.pem]
export ORDERER_GENERAL_TLS_CLIENTAUTHREQUIRED=true
export ORDERER_GENERAL_TLS_CLIENTROOTCAS=[/home/datlv/data/org0-ca-chain.pem]
export ORDERER_GENERAL_LOGLEVEL=debug
export ORDERER_DEBUG_BROADCASTTRACEDIR=/home/datlv/data/logs
export ORG=org0
export ORG_ADMIN_CERT=/home/datlv/data/orgs/org0/msp/admincerts/cert.pem



# Wait for setup to complete sucessfully
# awaitSetup

# Enroll to get orderer's TLS cert (using the "tls" profile)
$GOPATH/src/github.com/hyperledger/fabric-ca/cmd/fabric-ca-client/fabric-ca-client enroll -d --enrollment.profile tls -u $ENROLLMENT_URL -M /tmp/tls --csr.hosts $ORDERER_HOST

# Copy the TLS key and cert to the appropriate place
TLSDIR=$ORDERER_HOME/tls
mkdir -p $TLSDIR
cp /tmp/tls/keystore/* $ORDERER_GENERAL_TLS_PRIVATEKEY
cp /tmp/tls/signcerts/* $ORDERER_GENERAL_TLS_CERTIFICATE
rm -rf /tmp/tls

# Enroll again to get the orderer's enrollment certificate (default profile)
$GOPATH/src/github.com/hyperledger/fabric-ca/cmd/fabric-ca-client/fabric-ca-client enroll -d -u $ENROLLMENT_URL -M $ORDERER_GENERAL_LOCALMSPDIR

# Finish setting up the local MSP for the orderer
finishMSPSetup $ORDERER_GENERAL_LOCALMSPDIR
copyAdminCert $ORDERER_GENERAL_LOCALMSPDIR

