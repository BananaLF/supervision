#!/bin/bash

export PATH=${PWD}/../bin:$PATH
export VERBOSE=false

. scripts/utils.sh

# Create Organization crypto material using cryptogen or CAs
function createOrgs() {
  if [ -d "organizations/commiterOrganizations" ]; then
    rm -Rf organizations/commiterOrganizations && rm -Rf organizations/consensusOrganizations
  fi

  infoln "Generating certificates using Fabric CA"

    IMAGE_TAG=${CA_IMAGETAG} docker-compose -f $COMPOSE_FILE_CA up -d 2>&1

    . registerEnroll.sh
  # Create crypto material using Fabric CA

  while :
    do
      if [ ! -f "organizations/fabric-ca/org1/tls-cert.pem" ]; then
        sleep 1
      else
        break
      fi
    done

    infoln "Creating Org1 Identities"

    createOrg1

    infoln "Creating Org2 Identities"

    createOrg2

    infoln "Creating Consensus Org Identities"

    createConsensus

  fi

  infoln "Generating CCP files for Org1 and Org2"
  ./organizations/ccp-generate.sh
}