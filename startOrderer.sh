#!/bin/bash
usage() { echo "Usage: $0 [-c <channelID>] [-n <filename>] [-f <mspConfigPath>]" 1>&2; exit 1; }

while getopts ":c:n:f:" o; do
    case "${o}" in
        c)
            c=${OPTARG}
            ;;
        n)
            n=${OPTARG}
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

if [ -z "${c}" ] || [ -z "${n}" ] || [ -z "${f}" ]
then
    usage
fi
if [ ! -d "$GOPATH/src/github.com/hyperledger/fabric/channel-artifacts" ]
then
    echo "create folder: channel-artifacts"
    mkdir $GOPATH/src/github.com/hyperledger/fabric/channel-artifacts
else
    echo "rm files in channel-artifacts"
    rm -rf $GOPATH/src/github.com/hyperledger/fabric/channel-artifacts/*
fi
echo "kill process order"
kill $(pidof orderer)
echo "rm files in /var/hyperledger/production"
rm -rf /var/hyperledger/production/*
## generate genesis block
echo "generate genesis block"
export FABRIC_CFG_PATH=${f}
cd $GOPATH/src/github.com/hyperledger/fabric && ./build/bin/configtxgen -profile SampleSingleMSPBFTsmart -channelID "${c}" -outputBlock ./channel-artifacts/"${n}"

export FABRIC_CA_CLIENT_HOME=/etc/hyperledger/orderer
export FABRIC_CA_CLIENT_TLS_CERTFILES=/home/datlv/data/org0-ca-chain.pem
export ENROLLMENT_URL=https://orderer1-org0:orderer1-org0pw@ica-org0:7054
export ORDERER_HOME=/etc/hyperledger/orderer
export ORDERER_HOST=127.0.0.1
export ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
export ORDERER_GENERAL_GENESISMETHOD=file
export ORDERER_GENERAL_GENESISFILE=$GOPATH/src/github.com/hyperledger/fabric/channel-artifacts/genesis.block
export ORDERER_GENERAL_LOCALMSPID=org0MSP
export ORDERER_GENERAL_LOCALMSPDIR=/etc/hyperledger/orderer/msp
export ORDERER_GENERAL_TLS_ENABLED=true
export ORDERER_GENERAL_TLS_PRIVATEKEY=/etc/hyperledger/orderer/tls/server.key
export ORDERER_GENERAL_TLS_CERTIFICATE=/etc/hyperledger/orderer/tls/server.crt
export ORDERER_GENERAL_TLS_ROOTCAS=[/home/datlv/data/org0-ca-chain.pem]
export ORDERER_GENERAL_TLS_CLIENTAUTHREQUIRED=true
export ORDERER_GENERAL_TLS_CLIENTROOTCAS=[/home/datlv/data/org0-ca-chain.pem]
export ORDERER_GENERAL_LOGLEVEL=debug
export ORDERER_DEBUG_BROADCASTTRACEDIR=/data/logs
export ORG=org0
export ORG_ADMIN_CERT=/home/datlv/data/orgs/org0/msp/admincerts/cert.pem

cd $GOPATH/src/github.com/hyperledger/fabric && ./build/bin/orderer start

