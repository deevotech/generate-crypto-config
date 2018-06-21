#!/bin/bash
usage() { echo "Usage: $0 [-c <channelID>] [-a <anchorOrg1>] [-n <anchorName1>] [-b <anchorOrg2>] [-l <anchorName2>] [-f <pathconfig>]" 1>&2; exit 1; }

while getopts ":c:a:n:b:l:f:" o; do
    case "${o}" in
        c)
            c=${OPTARG}
            ;;
        a)
            a=${OPTARG}
            ;;
        n)
            n=${OPTARG}
            ;;
 	b)
            b=${OPTARG}
            ;;
        l)
            l=${OPTARG}
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

if [ -z "${c}" ] || [ -z "${a}" ] || [ -z "${n}" ] || [ -z "${b}" ] || [ -z "${l}" ]  || [ -z "${f}" ]
then
    usage
fi
echo "kill peer"
kill $(pidof peer)
echo "create ${c}"
export FABRIC_CFG_PATH=${f}
cd $GOPATH/src/github.com/hyperledger/fabric && ./build/bin/configtxgen -profile SampleSingleMSPChannel -outputCreateChannelTx ./channel-artifacts/"${c}.tx" -channelID "${c}"
echo "update ${c}"
cd $GOPATH/src/github.com/hyperledger/fabric && ./build/bin/configtxgen -profile SampleSingleMSPChannel -outputAnchorPeersUpdate ./channel-artifacts/"anchors.tx" -channelID "${c}" -asOrg "${a}"
cd $GOPATH/src/github.com/hyperledger/fabric && ./build/bin/configtxgen -profile SampleSingleMSPChannel -outputAnchorPeersUpdate ./channel-artifacts/"anchors.tx" -channelID "${c}" -asOrg "${b}"
echo "peer node start" 
export FABRIC_CFG_PATH=$GOPATH/src/github.com/hyperledger/fabric/bftsmartconfig/
export FABRIC_CA_CLIENT_HOME=/etc/hyperledger/peer/peer1-org1
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
export ORDERER_PORT_ARGS=" -o orderer1-org0:7050 --tls --cafile /home/datlv/data/org0-ca-chain.pem --clientauth "
export ORDERER_CONN_ARGS="$ORDERER_PORT_ARGS --keyfile $CORE_PEER_TLS_CLIENTKEY_FILE --certfile $CORE_PEER_TLS_CLIENTCERT_FILE"

cd $GOPATH/src/github.com/hyperledger/fabric && ./build/bin/peer node start
