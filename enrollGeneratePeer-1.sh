#!/bin/bash
# initOrgs
# enrollAdmin
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

ORG="org1"

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

   ROOT_CA_CERTFILE=/${DATA}/${ORG}-ca-cert.pem
   INT_CA_CHAINFILE=/${DATA}/${ORG}-ca-chain.pem
   ANCHOR_TX_FILE=/${DATA}/orgs/${ORG}/anchors.tx
   ORG_MSP_ID=${ORG}MSP
   ORG_MSP_DIR=/${DATA}/orgs/${ORG}/msp
   ORG_ADMIN_CERT=${ORG_MSP_DIR}/admincerts/cert.pem
   ORG_ADMIN_HOME=/${DATA}/orgs/$ORG/admin
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
# enrollAdmin
export FABRIC_CA_CLIENT_HOME=$HOME/cas/$CA_NAME
export FABRIC_CA_CLIENT_TLS_CERTFILES=$CA_CHAINFILE
$GOPATH/src/github.com/hyperledger/fabric-ca/cmd/fabric-ca-client/fabric-ca-client enroll -d -u "https://"$CA_ADMIN_USER_PASS"@localhost:7057"

local COUNT=1
while [[ "$COUNT" -le $NUM_PEERS ]]; do
   NUM=$COUNT
   PEER_HOST=peer${NUM}-${ORG}
   PEER_NAME=peer${NUM}-${ORG}
   PEER_PASS=${PEER_NAME}pw
   PEER_NAME_PASS=${PEER_NAME}:${PEER_PASS}
   PEER_LOGFILE=$LOGDIR/${PEER_NAME}.log
   MYHOME=/opt/gopath/src/github.com/hyperledger/fabric/peer
   TLSDIR=$MYHOME/tls

   export FABRIC_CA_CLIENT=$MYHOME
   export CORE_PEER_ID=$PEER_HOST
   export CORE_PEER_ADDRESS=$PEER_HOST:7051
   export CORE_PEER_LOCALMSPID=$ORG_MSP_ID
   export CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
   # the following setting starts chaincode containers on the same
   # bridge network as the peers
   # https://docs.docker.com/compose/networking/
   #export CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=${COMPOSE_PROJECT_NAME}_${NETWORK}
   export CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=net_${NETWORK}
   # export CORE_LOGGING_LEVEL=ERROR
   export CORE_LOGGING_LEVEL=DEBUG
   export CORE_PEER_TLS_ENABLED=true
   export CORE_PEER_TLS_CLIENTAUTHREQUIRED=true
   export CORE_PEER_TLS_ROOTCERT_FILE=$CA_CHAINFILE
   export CORE_PEER_TLS_CLIENTCERT_FILE=/$DATA/tls/$PEER_NAME-cli-client.crt
   export CORE_PEER_TLS_CLIENTKEY_FILE=/$DATA/tls/$PEER_NAME-cli-client.key
   export CORE_PEER_PROFILE_ENABLED=true
   # gossip variables
   export CORE_PEER_GOSSIP_USELEADERELECTION=true
   export CORE_PEER_GOSSIP_ORGLEADER=false
   export CORE_PEER_GOSSIP_EXTERNALENDPOINT=$PEER_HOST:7051
   if [ $NUM -gt 1 ]; then
      # Point the non-anchor peers to the anchor peer, which is always the 1st peer
      export CORE_PEER_GOSSIP_BOOTSTRAP=peer1-${ORG}:7051
   fi
   echo $PEER_NAME
   export ORDERER_CONN_ARGS="$ORDERER_PORT_ARGS --keyfile $CORE_PEER_TLS_CLIENTKEY_FILE --certfile $CORE_PEER_TLS_CLIENTCERT_FILE"
 	log "Registering $PEER_NAME with $CA_NAME"
 	$GOPATH/src/github.com/hyperledger/fabric-ca/cmd/fabric-ca-client/fabric-ca-client register -d --id.name $PEER_NAME --id.secret $PEER_PASS --id.type peer -u "https://"$CA_ADMIN_USER_PASS"@localhost:7057"
 	COUNT=$((COUNT+1))
  done
log "Registering admin identity with $CA_NAME"
# The admin identity has the "admin" attribute which is added to ECert by default
$GOPATH/src/github.com/hyperledger/fabric-ca/cmd/fabric-ca-client/fabric-ca-client register -d --id.name $ADMIN_NAME --id.secret $ADMIN_PASS --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert" -u "https://"$CA_ADMIN_USER_PASS"@localhost:7057"
log "Registering user identity with $CA_NAME"
$GOPATH/src/github.com/hyperledger/fabric-ca/cmd/fabric-ca-client/fabric-ca-client register -d --id.name $USER_NAME --id.secret $USER_PASS -u "https://"$CA_ADMIN_USER_PASS"@localhost:7057"

## getcert
## initOrgVars $ORG
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
  log "Getting CA certs for organization $ORG and storing in $ORG_MSP_DIR"
  export FABRIC_CA_CLIENT_TLS_CERTFILES=$CA_CHAINFILE
  $GOPATH/src/github.com/hyperledger/fabric-ca/cmd/fabric-ca-client/fabric-ca-client getcacert -d -u "https://localhost:7057" -M $ORG_MSP_DIR
  # finishMSPSetup $ORG_MSP_DIR
  if [ ! -d $ORG_MSP_DIR/tlscacerts ]; then
      mkdir $ORG_MSP_DIR/tlscacerts
      cp $ORG_MSP_DIR/cacerts/* $ORG_MSP_DIR/tlscacerts
      if [ -d $ORG_MSP_DIR/intermediatecerts ]; then
         mkdir $ORG_MSP_DIR/tlsintermediatecerts
         cp $ORG_MSP_DIR/intermediatecerts/* $ORG_MSP_DIR/tlsintermediatecerts
      fi
   fi
  # If ADMINCERTS is true, we need to enroll the admin now to populate the admincerts directory
  if [ $ADMINCERTS ]; then
     if [ ! -d $ORG_ADMIN_HOME ]; then
      dowait "$CA_NAME to start" 60 $CA_LOGFILE $CA_CHAINFILE
      log "Enrolling admin '$ADMIN_NAME' with $CA_HOST ..."
      export FABRIC_CA_CLIENT_HOME=$ORG_ADMIN_HOME
      export FABRIC_CA_CLIENT_TLS_CERTFILES=$CA_CHAINFILE
      $GOPATH/src/github.com/hyperledger/fabric-ca/cmd/fabric-ca-client/fabric-ca-client enroll -d -u "https://"$ADMIN_NAME":"$ADMIN_PASS"@localhost:7057"
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



  