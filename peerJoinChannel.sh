#!/bin/bash
set -e

source $(dirname "$0")/env.sh
usage() { echo "Usage: $0 [-c <channelID>] [-e <orderer>] [-p <port>] [-f <pathconfig>]" 1>&2; exit 1; }

while getopts ":c:e:p:f:" o; do
    case "${o}" in
        c)
            c=${OPTARG}
            ;;
        e)
            e=${OPTARG}
            ;;
        p)
            p=${OPTARG}
            ;;
        f)
            f=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${c}" ] || [ -z "${e}" ] || [ -z "$p" ] || [ -z "$f" ]
then
    usage
fi
echo "create channel with peer"
export FABRIC_CFG_PATH=$GOPATH/src/github.com/hyperledger/fabric/bftsmartconfig/
export FABRIC_CA_CLIENT_HOME=/etc/hyperledger/peer/peer1-or1
export FABRIC_CA_CLIENT_TLS_CERTFILES=/data/org1-ca-chain.pem
export ENROLLMENT_URL=https://peer1-org1:peer1-org1pw@ica-org1:7054
export PEER_NAME=peer1-org1
export PEER_HOME=/etc/hyperledger/peer/peer1-org1
export PEER_HOST=peer1-org1
export PEER_NAME_PASS=peer1-org1:peer1-org1pw
export CORE_PEER_ID=peer1-org1
export CORE_PEER_ADDRESS=peer1-org1:7051
export CORE_PEER_LOCALMSPID=org1MSP
export CORE_PEER_MSPCONFIGPATH=/home/datlv/data/orgs/org1/admin/msp
export CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
export CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=net_fabric-ca
export CORE_LOGGING_LEVEL=DEBUG
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/peer/peer1-org1/tls/server.crt
export CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/peer/peer1-org1/tls/server.key
export CORE_PEER_TLS_ROOTCERT_FILE=/home/datlv/data/org1-ca-chain.pem
export CORE_PEER_TLS_CLIENTAUTHREQUIRED=true
export CORE_PEER_TLS_CLIENTROOTCAS_FILES=/home/datlv/data/org1-ca-chain.pem
export CORE_PEER_TLS_CLIENTCERT_FILE=/home/datlv/data/tls/peer1-org1-client.crt
export CORE_PEER_TLS_CLIENTKEY_FILE=/home/datlv/data/tls/peer1-org1-client.key
export CORE_PEER_GOSSIP_USELEADERELECTION=true
export CORE_PEER_GOSSIP_ORGLEADER=false
export CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer1-org1:7051
export CORE_PEER_GOSSIP_SKIPHANDSHAKE=true
export ORG=org1
export ORG_ADMIN_CERT=/home/datlv/data/orgs/org1/msp/admincerts/cert.pem

initOrdererVars "org0" 1
export ORDERER_PORT_ARGS="-o $ORDERER_HOST:7050 --tls true --cafile $CA_CHAINFILE --clientauth "
echo $ORDERER_PORT_ARGS
initPeerVars "org1" 1
echo $ORDERER_CONN_ARGS

#ORDERER_PORT_ARGS=" -o 127.0.0.1:7050 --tls true --cafile /home/datlv/data/org0-ca-chain.pem --clientauth"
#ORDERER_CONN_ARGS=" $ORDERER_PORT_ARGS --keyfile $CORE_PEER_TLS_CLIENTKEY_FILE --certfile $CORE_PEER_TLS_CLIENTCERT_FILE"
#echo $ORDERER_CONN_ARGS
cd $GOPATH/src/github.com/hyperledger/fabric && ./build/bin/peer channel create  -c "${c}" -f ./channel-artifacts/"${c}.tx" $ORDERER_CONN_ARGS -t 100 --logging-level=DEBUG
# cd $GOPATH/src/github.com/hyperledger/fabric && ./build/bin/peer channel join -b ./"${c}.block"
