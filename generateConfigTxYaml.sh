#!/bin/bash
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
LOGPATH=$LOGDIR

# Name of a the file to create when setup is successful
SETUP_SUCCESS_FILE=${LOGDIR}/setup.successful
# The setup container's log file
SETUP_LOGFILE=${LOGDIR}/setup.log

# The run container's log file
RUN_LOGFILE=${LOGDIR}/run.log
# The run container's summary log file
RUN_SUMFILE=${LOGDIR}/run.sum
RUN_SUMPATH=${RUN_SUMFILE}
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

function initOrgVars {
   if [ $# -ne 1 ]; then
      echo "Usage: initOrgVars <ORG>"
      exit 1
   fi
   ORG=$1
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
}
# initOrdererVars <NUM>
function initOrdererVars {
   if [ $# -ne 2 ]; then
      echo "Usage: initOrdererVars <ORG> <NUM>"
      exit 1
   fi
   initOrgVars $1
   NUM=$2
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
}
function initPeerVars {
   if [ $# -ne 2 ]; then
      echo "Usage: initPeerVars <ORG> <NUM>: $*"
      exit 1
   fi
   initOrgVars $1
   NUM=$2
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
   export CORE_PEER_TLS_CLIENTCERT_FILE=$DATA/tls/$PEER_NAME-cli-client.crt
   export CORE_PEER_TLS_CLIENTKEY_FILE=$DATA/tls/$PEER_NAME-cli-client.key
   export CORE_PEER_PROFILE_ENABLED=true
   # gossip variables
   export CORE_PEER_GOSSIP_USELEADERELECTION=true
   export CORE_PEER_GOSSIP_ORGLEADER=false
   export CORE_PEER_GOSSIP_EXTERNALENDPOINT=$PEER_HOST:7051
   if [ $NUM -gt 1 ]; then
      # Point the non-anchor peers to the anchor peer, which is always the 1st peer
      export CORE_PEER_GOSSIP_BOOTSTRAP=peer1-${ORG}:7051
   fi
   export ORDERER_CONN_ARGS="$ORDERER_PORT_ARGS --keyfile $CORE_PEER_TLS_CLIENTKEY_FILE --certfile $CORE_PEER_TLS_CLIENTCERT_FILE"
}

function main {
		makeConfigTxYaml
	}
	
function printOrg {
   echo "
  - &$ORG_CONTAINER_NAME

    Name: $ORG

    # ID to load the MSP definition as
    ID: $ORG_MSP_ID

    # MSPDir is the filesystem path which contains the MSP configuration
    MSPDir: $ORG_MSP_DIR"
}

# printOrdererOrg <ORG>
function printOrdererOrg {
   initOrgVars $1
   printOrg
}

# printPeerOrg <ORG> <COUNT>
function printPeerOrg {
   initPeerVars $1 $2
   printOrg
   echo "
    AnchorPeers:
       # AnchorPeers defines the location of peers which can be used
       # for cross org gossip communication.  Note, this value is only
       # encoded in the genesis block in the Application section context
       - Host: $PEER_HOST
         Port: 7051"
}

function makeConfigTxYaml {
   {
   echo "################################################################################
#
#   Profile
#
#   - Different configuration profiles may be encoded here to be specified
#   as parameters to the configtxgen tool
#
################################################################################
Profiles:

  OrgsOrdererGenesis:
    Orderer:
      # Orderer Type: The orderer implementation to start
      # Available types are \"solo\" and \"kafka\"
      OrdererType: solo
      Addresses:"

   for ORG in $ORDERER_ORGS; do
      local COUNT=1
      while [[ "$COUNT" -le $NUM_ORDERERS ]]; do
         initOrdererVars $ORG $COUNT
         echo "        - $ORDERER_HOST:7050"
         COUNT=$((COUNT+1))
      done
   done

   echo "
      # Batch Timeout: The amount of time to wait before creating a batch
      BatchTimeout: 2s

      # Batch Size: Controls the number of messages batched into a block
      BatchSize:

        # Max Message Count: The maximum number of messages to permit in a batch
        MaxMessageCount: 10

        # Absolute Max Bytes: The absolute maximum number of bytes allowed for
        # the serialized messages in a batch.
        AbsoluteMaxBytes: 99 MB

        # Preferred Max Bytes: The preferred maximum number of bytes allowed for
        # the serialized messages in a batch. A message larger than the preferred
        # max bytes will result in a batch larger than preferred max bytes.
        PreferredMaxBytes: 512 KB

      Kafka:
        # Brokers: A list of Kafka brokers to which the orderer connects
        # NOTE: Use IP:port notation
        Brokers:
          - 127.0.0.1:9092

      # Organizations is the list of orgs which are defined as participants on
      # the orderer side of the network
      Organizations:"

   for ORG in $ORDERER_ORGS; do
      initOrgVars $ORG
      echo "        - *${ORG_CONTAINER_NAME}"
   done

   echo "
    Consortiums:

      SampleConsortium:

        Organizations:"

   for ORG in $PEER_ORGS; do
      initOrgVars $ORG
      echo "          - *${ORG_CONTAINER_NAME}"
   done

   echo "
  OrgsChannel:
    Consortium: SampleConsortium
    Application:
      <<: *ApplicationDefaults
      Organizations:"

   for ORG in $PEER_ORGS; do
      initOrgVars $ORG
      echo "        - *${ORG_CONTAINER_NAME}"
   done

   echo "
################################################################################
#
#   Section: Organizations
#
#   - This section defines the different organizational identities which will
#   be referenced later in the configuration.
#
################################################################################
Organizations:"

   for ORG in $ORDERER_ORGS; do
      printOrdererOrg $ORG
   done

   for ORG in $PEER_ORGS; do
      printPeerOrg $ORG 1
   done

   echo "
################################################################################
#
#   SECTION: Application
#
#   This section defines the values to encode into a config transaction or
#   genesis block for application related parameters
#
################################################################################
Application: &ApplicationDefaults

    # Organizations is the list of orgs which are defined as participants on
    # the application side of the network
    Organizations:
"

   } > /etc/hyperledger/fabric/configtx.yaml
   # Copy it to the data directory to make debugging easier
   cp /etc/hyperledger/fabric/configtx.yaml $DATA
}

function generateChannelArtifacts() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    fatal "configtxgen tool not found. exiting"
  fi

  log "Generating orderer genesis block at $GENESIS_BLOCK_FILE"
  # Note: For some unknown reason (at least for now) the block file can't be
  # named orderer.genesis.block or the orderer will fail to launch!
  $GOPATH/src/github.com/hyperleder/fabric/build/bin/configtxgen -profile OrgsOrdererGenesis -outputBlock $GENESIS_BLOCK_FILE
  if [ "$?" -ne 0 ]; then
    fatal "Failed to generate orderer genesis block"
  fi

  log "Generating channel configuration transaction at $CHANNEL_TX_FILE"
  $GOPATH/src/github.com/hyperleder/fabric/build/bin/configtxgen -profile OrgsChannel -outputCreateChannelTx $CHANNEL_TX_FILE -channelID $CHANNEL_NAME
  if [ "$?" -ne 0 ]; then
    fatal "Failed to generate channel configuration transaction"
  fi

  for ORG in $PEER_ORGS; do
     initOrgVars $ORG
     log "Generating anchor peer update transaction for $ORG at $ANCHOR_TX_FILE"
     $GOPATH/src/github.com/hyperleder/fabric/build/bin/configtxgen -profile OrgsChannel -outputAnchorPeersUpdate $ANCHOR_TX_FILE \
                 -channelID $CHANNEL_NAME -asOrg $ORG
     if [ "$?" -ne 0 ]; then
        fatal "Failed to generate anchor peer update for $ORG"
     fi
  done
}

main

