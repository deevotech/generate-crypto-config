#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

source $(dirname "$0")/env.sh

export FABRIC_CA_CLIENT_HOME=/etc/hyperledger/peer/
export FABRIC_CA_CLIENT_TLS_CERTFILES=/home/datlv/data/org1-ca-chain.pem
export ENROLLMENT_URL=https://peer2-org1:peer2-org1pw@localhost:7057
export PEER_NAME=peer2-org1
export PEER_HOME=/etc/hyperledger/peer/
export PEER_HOST=peer2-org1
export PEER_NAME_PASS=peer2-org1:peer2-org1pw
export CORE_PEER_ID=peer2-org1
export CORE_PEER_ADDRESS=peer2-org1:7051
export CORE_PEER_LOCALMSPID=org1MSP
export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/peer/msp
export CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
export CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=net_fabric-ca
export CORE_LOGGING_LEVEL=DEBUG
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/peer/tls/server.crt
export CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/peer/tls/server.key
export CORE_PEER_TLS_ROOTCERT_FILE=/home/datlv/data/org1-ca-chain.pem
export CORE_PEER_TLS_CLIENTAUTHREQUIRED=true
export CORE_PEER_TLS_CLIENTROOTCAS_FILES=/home/datlv/data/org1-ca-chain.pem
export CORE_PEER_TLS_CLIENTCERT_FILE=/home/datlv/data/tls/peer2-org1-client.crt
export CORE_PEER_TLS_CLIENTKEY_FILE=/home/datlv/data/tls/peer2-org1-client.key
export CORE_PEER_GOSSIP_USELEADERELECTION=true
export CORE_PEER_GOSSIP_ORGLEADER=false
export CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer2-org1:7051
export CORE_PEER_GOSSIP_SKIPHANDSHAKE=true
export ORG=org1
export ORG_ADMIN_CERT=/home/datlv/data/orgs/org1/msp/admincerts/cert.pem
export CORE_PEER_GOSSIP_BOOTSTRAP=peer1-org1:7051

# Although a peer may use the same TLS key and certificate file for both inbound and outbound TLS,
# we generate a different key and certificate for inbound and outbound TLS simply to show that it is permissible

# Generate server TLS cert and key pair for the peer
$GOPATH/src/github.com/hyperledger/fabric-ca/cmd/fabric-ca-client/fabric-ca-client enroll -d --enrollment.profile tls -u $ENROLLMENT_URL -M /tmp/tls --csr.hosts $PEER_HOST

# Copy the TLS key and cert to the appropriate place
TLSDIR=$PEER_HOME/tls
mkdir -p $TLSDIR
cp /tmp/tls/signcerts/* $CORE_PEER_TLS_CERT_FILE
cp /tmp/tls/keystore/* $CORE_PEER_TLS_KEY_FILE
rm -rf /tmp/tls

# Generate client TLS cert and key pair for the peer
genClientTLSCert $PEER_NAME $CORE_PEER_TLS_CLIENTCERT_FILE $CORE_PEER_TLS_CLIENTKEY_FILE

# Generate client TLS cert and key pair for the peer CLI
genClientTLSCert $PEER_NAME $DATA/tls/$PEER_NAME-cli-client.crt $DATA/tls/$PEER_NAME-cli-client.key

# Enroll the peer to get an enrollment certificate and set up the core's local MSP directory
$GOPATH/src/github.com/hyperledger/fabric-ca/cmd/fabric-ca-client/fabric-ca-client enroll -d -u $ENROLLMENT_URL -M $CORE_PEER_MSPCONFIGPATH
finishMSPSetup $CORE_PEER_MSPCONFIGPATH
copyAdminCert $CORE_PEER_MSPCONFIGPATH

