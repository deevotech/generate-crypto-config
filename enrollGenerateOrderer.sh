#!/bin/bash
# Name of the docker-compose network
NETWORK=fabric-ca

# Names of the orderer organizations
ORDERER_ORGS="org0"

# Names of the peer organizations
PEER_ORGS="org1 org2"

# Number of peers in each peer organization
NUM_PEERS=2

#
# The remainder of this file contains variables which typically would not be changed.
#

# All org names
ORGS="$ORDERER_ORGS $PEER_ORGS"

# Set to true to populate the "admincerts" folder of MSPs
ADMINCERTS=true

# Number of orderer nodes
NUM_ORDERERS=1

# The volume mount to share data between containers
DATA="/home/datlv/data"

# The path to the genesis block
GENESIS_BLOCK_FILE=$DATA/genesis.block

# The path to a channel transaction
CHANNEL_TX_FILE=$DATA/channel.tx

# Name of test channel
CHANNEL_NAME=mychannel

# Query timeout in seconds
QUERY_TIMEOUT=15

# Setup timeout in seconds (for setup container to complete)
SETUP_TIMEOUT=120

# Log directory
LOGDIR=$DATA/logs
LOGPATH=/$LOGDIR

# Name of a the file to create when setup is successful
SETUP_SUCCESS_FILE=${LOGDIR}/setup.successful
# The setup container's log file
SETUP_LOGFILE=${LOGDIR}/setup.log

# The run container's log file
RUN_LOGFILE=${LOGDIR}/run.log
# The run container's summary log file
RUN_SUMFILE=${LOGDIR}/run.sum
RUN_SUMPATH=/${RUN_SUMFILE}
# Run success and failure files
RUN_SUCCESS_FILE=${LOGDIR}/run.success
RUN_FAIL_FILE=${LOGDIR}/run.fail

# Affiliation is not used to limit users in this sample, so just put
# all identities in the same affiliation.
export FABRIC_CA_CLIENT_ID_AFFILIATION=org1

# Set to true to enable use of intermediate CAs
USE_INTERMEDIATE_CA=true


# Config block file path
CONFIG_BLOCK_FILE=/tmp/config_block.pb

# Update config block payload file path
CONFIG_UPDATE_ENVELOPE_FILE=/tmp/config_update_as_envelope.pb
# initOrgVars $ORG
# enrollCAAdmin
# local COUNT=1
# initOrgVars $ORG
ORG="org0"

ORG_CONTAINER_NAME=${ORG//./-}
   ROOT_CA_HOST=rca-${ORG}
   ROOT_CA_NAME=rca-${ORG}
   ROOT_CA_LOGFILE=$LOGDIR/${ROOT_CA_NAME}.log
   INT_CA_HOST=ica-${ORG}
   INT_CA_NAME=ica-${ORG}
   INT_CA_LOGFILE=$LOGDIR/${INT_CA_NAME}.log

   # Root CA admin identity
   ROOT_CA_ADMIN_USER=rca-${ORG}-admin
   ROOT_CA_ADMIN_PASS=${ROOT_CA_ADMIN_USER}pw
   ROOT_CA_ADMIN_USER_PASS=${ROOT_CA_ADMIN_USER}:${ROOT_CA_ADMIN_PASS}
   # Root CA intermediate identity to bootstrap the intermediate CA
   ROOT_CA_INT_USER=ica-${ORG}
   ROOT_CA_INT_PASS=${ROOT_CA_INT_USER}pw
   ROOT_CA_INT_USER_PASS=${ROOT_CA_INT_USER}:${ROOT_CA_INT_PASS}
   # Intermediate CA admin identity
   INT_CA_ADMIN_USER=ica-${ORG}-admin
   INT_CA_ADMIN_PASS=${INT_CA_ADMIN_USER}pw
   INT_CA_ADMIN_USER_PASS=${INT_CA_ADMIN_USER}:${INT_CA_ADMIN_PASS}
   # Admin identity for the org
   ADMIN_NAME=admin-${ORG}
   ADMIN_PASS=${ADMIN_NAME}pw
   # Typical user identity for the org
   USER_NAME=user-${ORG}
   USER_PASS=${USER_NAME}pw

   ROOT_CA_CERTFILE=${DATA}/${ORG}-ca-cert.pem
   INT_CA_CHAINFILE=${DATA}/${ORG}-ca-chain.pem
   ANCHOR_TX_FILE=${DATA}/orgs/${ORG}/anchors.tx
   ORG_MSP_ID=${ORG}MSP
   ORG_MSP_DIR=${DATA}/orgs/${ORG}/msp
   ORG_ADMIN_CERT=${ORG_MSP_DIR}/admincerts/cert.pem
   ORG_ADMIN_HOME=${DATA}/orgs/$ORG/admin

   if test "$USE_INTERMEDIATE_CA" = "true"; then
      CA_NAME=$INT_CA_NAME
      CA_HOST=$INT_CA_HOST
      CA_CHAINFILE=$INT_CA_CHAINFILE
      CA_ADMIN_USER_PASS=$INT_CA_ADMIN_USER_PASS
      CA_LOGFILE=$INT_CA_LOGFILE
   else
      CA_NAME=$ROOT_CA_NAME
      CA_HOST=$ROOT_CA_HOST
      CA_CHAINFILE=$ROOT_CA_CERTFILE
      CA_ADMIN_USER_PASS=$ROOT_CA_ADMIN_USER_PASS
      CA_LOGFILE=$ROOT_CA_LOGFILE
   fi
#enroll admin 
export FABRIC_CA_CLIENT_HOME=$HOME/cas/$CA_NAME
export FABRIC_CA_CLIENT_TLS_CERTFILES=$CA_CHAINFILE
$GOPATH/src/github.com/hyperledger/fabric-ca/cmd/fabric-ca-client/fabric-ca-client enroll -d -u "https://"$CA_ADMIN_USER_PASS"@localhost:7055"
local COUNT=1
while [[ "$COUNT" -le $NUM_ORDERERS ]]; do
   NUM=${COUNT}
   ORDERER_HOST=orderer${NUM}-${ORG}
   ORDERER_NAME=orderer${NUM}-${ORG}
   ORDERER_PASS=${ORDERER_NAME}pw
   ORDERER_NAME_PASS=${ORDERER_NAME}:${ORDERER_PASS}
   ORDERER_LOGFILE=$LOGDIR/${ORDERER_NAME}.log
   MYHOME=/etc/hyperledger/orderer

   export FABRIC_CA_CLIENT=$MYHOME
   export ORDERER_GENERAL_LOGLEVEL=debug
   export ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
   export ORDERER_GENERAL_GENESISMETHOD=file
   export ORDERER_GENERAL_GENESISFILE=$GENESIS_BLOCK_FILE
   export ORDERER_GENERAL_LOCALMSPID=$ORG_MSP_ID
   export ORDERER_GENERAL_LOCALMSPDIR=$MYHOME/msp
   # enabled TLS
   export ORDERER_GENERAL_TLS_ENABLED=true
   TLSDIR=$MYHOME/tls
   export ORDERER_GENERAL_TLS_PRIVATEKEY=$TLSDIR/server.key
   export ORDERER_GENERAL_TLS_CERTIFICATE=$TLSDIR/server.crt
   export ORDERER_GENERAL_TLS_ROOTCAS=[$CA_CHAINFILE]
   $GOPATH/src/github.com/hyperledger/fabric-ca/cmd/fabric-ca-client/fabric-ca-client register -d --id.name $ORDERER_NAME --id.secret $ORDERER_PASS --id.type orderer
   COUNT=$((COUNT+1))
done
log "Registering admin identity with $CA_NAME"
# The admin identity has the "admin" attribute which is added to ECert by default
$GOPATH/src/github.com/hyperledger/fabric-ca/cmd/fabric-ca-client/fabric-ca-client register -d --id.name $ADMIN_NAME --id.secret $ADMIN_PASS --id.attrs "admin=true:ecert" 

## get cert
ORG_CONTAINER_NAME=${ORG//./-}
   ROOT_CA_HOST=rca-${ORG}
   ROOT_CA_NAME=rca-${ORG}
   ROOT_CA_LOGFILE=$LOGDIR/${ROOT_CA_NAME}.log
   INT_CA_HOST=ica-${ORG}
   INT_CA_NAME=ica-${ORG}
   INT_CA_LOGFILE=$LOGDIR/${INT_CA_NAME}.log

   # Root CA admin identity
   ROOT_CA_ADMIN_USER=rca-${ORG}-admin
   ROOT_CA_ADMIN_PASS=${ROOT_CA_ADMIN_USER}pw
   ROOT_CA_ADMIN_USER_PASS=${ROOT_CA_ADMIN_USER}:${ROOT_CA_ADMIN_PASS}
   # Root CA intermediate identity to bootstrap the intermediate CA
   ROOT_CA_INT_USER=ica-${ORG}
   ROOT_CA_INT_PASS=${ROOT_CA_INT_USER}pw
   ROOT_CA_INT_USER_PASS=${ROOT_CA_INT_USER}:${ROOT_CA_INT_PASS}
   # Intermediate CA admin identity
   INT_CA_ADMIN_USER=ica-${ORG}-admin
   INT_CA_ADMIN_PASS=${INT_CA_ADMIN_USER}pw
   INT_CA_ADMIN_USER_PASS=${INT_CA_ADMIN_USER}:${INT_CA_ADMIN_PASS}
   # Admin identity for the org
   ADMIN_NAME=admin-${ORG}
   ADMIN_PASS=${ADMIN_NAME}pw
   # Typical user identity for the org
   USER_NAME=user-${ORG}
   USER_PASS=${USER_NAME}pw

   ROOT_CA_CERTFILE=${DATA}/${ORG}-ca-cert.pem
   INT_CA_CHAINFILE=${DATA}/${ORG}-ca-chain.pem
   ANCHOR_TX_FILE=${DATA}/orgs/${ORG}/anchors.tx
   ORG_MSP_ID=${ORG}MSP
   ORG_MSP_DIR=${DATA}/orgs/${ORG}/msp
   ORG_ADMIN_CERT=${ORG_MSP_DIR}/admincerts/cert.pem
   ORG_ADMIN_HOME=${DATA}/orgs/$ORG/admin

   if test "$USE_INTERMEDIATE_CA" = "true"; then
      CA_NAME=$INT_CA_NAME
      CA_HOST=$INT_CA_HOST
      CA_CHAINFILE=$INT_CA_CHAINFILE
      CA_ADMIN_USER_PASS=$INT_CA_ADMIN_USER_PASS
      CA_LOGFILE=$INT_CA_LOGFILE
   else
      CA_NAME=$ROOT_CA_NAME
      CA_HOST=$ROOT_CA_HOST
      CA_CHAINFILE=$ROOT_CA_CERTFILE
      CA_ADMIN_USER_PASS=$ROOT_CA_ADMIN_USER_PASS
      CA_LOGFILE=$ROOT_CA_LOGFILE
   fi
export FABRIC_CA_CLIENT_TLS_CERTFILES=$CA_CHAINFILE
$GOPATH/src/github.com/hyperledger/fabric-ca/cmd/fabric-ca-client/fabric-ca-client getcacert -d -u "https://localhost:7055" -M $ORG_MSP_DIR

if [ ! -d $ORG_MSP_DIR/tlscacerts ]; then
      mkdir $ORG_MSP_DIR/tlscacerts
      cp $ORG_MSP_DIR/cacerts/* $ORG_MSP_DIR/tlscacerts
      if [ -d $ORG_MSP_DIR/intermediatecerts ]; then
         mkdir $ORG_MSP_DIR/tlsintermediatecerts
         cp $ORG_MSP_DIR/intermediatecerts/* $ORG_MSP_DIR/tlsintermediatecerts
      fi
   fi
if [ $ADMINCERTS ]; then
if [ ! -d $ORG_ADMIN_HOME ]; then
      dowait "$CA_NAME to start" 60 $CA_LOGFILE $CA_CHAINFILE
      log "Enrolling admin '$ADMIN_NAME' with $CA_HOST ..."
      export FABRIC_CA_CLIENT_HOME=$ORG_ADMIN_HOME
      export FABRIC_CA_CLIENT_TLS_CERTFILES=$CA_CHAINFILE
      $GOPATH/src/github.com/hyperledger/fabric-ca/cmd/fabric-ca-client/fabric-ca-client enroll -d -u "https://"$ADMIN_NAME":"$ADMIN_PASS"@localhost:7055"
      # If admincerts are required in the MSP, copy the cert there now and to my local MSP also
      if [ $ADMINCERTS ]; then
         mkdir -p $(dirname "${ORG_ADMIN_CERT}")
         cp $ORG_ADMIN_HOME/msp/signcerts/* $ORG_ADMIN_CERT
         mkdir $ORG_ADMIN_HOME/msp/admincerts
         cp $ORG_ADMIN_HOME/msp/signcerts/* $ORG_ADMIN_HOME/msp/admincerts
      fi
   fi
   export CORE_PEER_MSPCONFIGPATH=$ORG_ADMIN_HOME/msp
fi

   
   
