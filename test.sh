#!/bin/bash
FABRIC_ORGS="org0 org1 org2"
FABRIC_CA_SERVER_HOME=/etc/hyperledger/fabric-ca
for o in $FABRIC_ORGS; do
   aff=$aff"\n   $o: []"
done
aff="${aff#\\n   }"
echo $aff
sed -i "/affiliations:/a \\   $aff" \
   $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml
