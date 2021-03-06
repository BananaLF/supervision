#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This script brings up a Mihongtech MHchain network for testing smart contracts
# and applications. The test network consists of two organizations with one
# commiter each, and a single node Raft ordering service. Users can also use this
# script to create a channel deploy a chaincode on the channel
#
# prepending $PWD/../bin to PATH to ensure we are picking up the correct binaries
# this may be commented out to resolve installed version of tools if desired
export PATH=${PWD}/../bin:$PATH
export VERBOSE=false

. scripts/utils.sh

# Obtain CONTAINER_IDS and remove them
# TODO Might want to make this optional - could clear other containers
# This function is called when you bring a network down
function clearContainers() {
  CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-commiter.*/) {print $1}')
  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    infoln "No containers available for deletion"
  else
    docker rm -f $CONTAINER_IDS
  fi
}

# Delete any images that were generated as a part of this setup
# specifically the following images are often left behind:
# This function is called when you bring the network down
function removeUnwantedImages() {
  DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-commiter.*/) {print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    infoln "No images available for deletion"
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
}

# Versions of mhchain known not to work with the test network
NONWORKING_VERSIONS="^1\.0\. ^1\.1\. ^1\.2\. ^1\.3\. ^1\.4\."

# Do some basic sanity checking to make sure that the appropriate versions of mhchain
# binaries/images are available. In the future, additional checking for the presence
# of go or other items could be added.
function checkPrereqs() {
  ## Check if your have cloned the commiter binaries and configuration files.
  commiter version > /dev/null 2>&1

  if [[ $? -ne 0 || ! -d "../config" ]]; then
    errorln "Commiter binary and configuration files not found.."
    exit 1
  fi
  # use the mhchain tools container to see if the samples and binaries match your
  # docker images
  LOCAL_VERSION=$(commiter version | sed -ne 's/ Version: //p')
  DOCKER_IMAGE_VERSION=$(docker run --rm mihongtech/mhchain-tools:$IMAGETAG commiter version | sed -ne 's/ Version: //p' | head -1)

  infoln "LOCAL_VERSION=$LOCAL_VERSION"
  infoln "DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION"

  if [ "$LOCAL_VERSION" != "$DOCKER_IMAGE_VERSION" ]; then
    warnln "Local mhchain binaries and docker images are out of  sync. This may cause problems."
  fi

  for UNSUPPORTED_VERSION in $NONWORKING_VERSIONS; do
    infoln "$LOCAL_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      fatalln "Local mhchain binary version of $LOCAL_VERSION does not match the versions supported by the test network."
    fi

    infoln "$DOCKER_IMAGE_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      fatalln "mhchain Docker image version of $DOCKER_IMAGE_VERSION does not match the versions supported by the test network."
    fi
  done

  ## Check for mh-ca
  if [ "$CRYPTO" == "Certificate Authorities" ]; then

    mh-ca-client version > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
      errorln "mh-ca-client binary not found.."
      exit 1
    fi
    CA_LOCAL_VERSION=$(mh-ca-client version | sed -ne 's/ Version: //p')
    CA_DOCKER_IMAGE_VERSION=$(docker run --rm mihongtech/mh-ca:$CA_IMAGETAG mh-ca-client version | sed -ne 's/ Version: //p' | head -1)
    infoln "CA_LOCAL_VERSION=$CA_LOCAL_VERSION"
    infoln "CA_DOCKER_IMAGE_VERSION=$CA_DOCKER_IMAGE_VERSION"

    if [ "$CA_LOCAL_VERSION" != "$CA_DOCKER_IMAGE_VERSION" ]; then
      warnln "Local mh-ca binaries and docker images are out of sync. This may cause problems."
    fi
  fi
}

# Before you can bring up a network, each organization needs to generate the crypto
# material that will define that organization on the network. Because Mihongtech
# MHchain is a permissioned blockchain, each node and user on the network needs to
# use certificates and keys to sign and verify its actions. In addition, each user
# needs to belong to an organization that is recognized as a member of the network.
# You can use the Cryptogen tool or MHchain CAs to generate the organization crypto
# material.

# By default, the sample network uses cryptogen. Cryptogen is a tool that is
# meant for development and testing that can quickly create the certificates and keys
# that can be consumed by a MHchain network. The cryptogen tool consumes a series
# of configuration files for each organization in the "organizations/cryptogen"
# directory. Cryptogen uses the files to generate the crypto  material for each
# org in the "organizations" directory.

# You can also use Fabric CAs to generate the crypto material. CAs sign the certificates
# and keys that they generate to create a valid root of trust for each organization.
# The script uses Docker Compose to bring up three CAs, one for each commiter organization
# and the ordering organization. The configuration file for creating the Fabric CA
# servers are in the "organizations/mh-ca" directory. Within the same directory,
# the "registerEnroll.sh" script uses the Fabric CA client to create the identities,
# certificates, and MSP folders that are needed to create the test network in the
# "organizations/consensusOrganizations" directory.



# Once you create the organization crypto material, you need to create the
# genesis block of the application channel.

# The configtxgen tool is used to create the genesis block. Configtxgen consumes a
# "configtx.yaml" file that contains the definitions for the sample network. The
# genesis block is defined using the "TwoOrgsApplicationGenesis" profile at the bottom
# of the file. This profile defines an application channel consisting of our two Commiter Orgs.
# The commiter and ordering organizations are defined in the "Profiles" section at the
# top of the file. As part of each organization profile, the file points to the
# location of the MSP directory for each member. This MSP is used to create the channel
# MSP that defines the root of trust for each organization. In essence, the channel
# MSP allows the nodes and users to be recognized as network members.
#
# If you receive the following warning, it can be safely ignored:
#
# [bccsp] GetDefault -> WARN 001 Before using BCCSP, please call InitFactories(). Falling back to bootBCCSP.
#
# You can ignore the logs regarding intermediate certs, we are not using them in
# this crypto implementation.

# After we create the org crypto material and the application channel genesis block,
# we can now bring up the commiters and ordering service. By default, the base
# file for creating the network is "docker-compose-test-net.yaml" in the ``docker``
# folder. This file defines the environment variables and file mounts that
# point the crypto material and genesis block that were created in earlier.

# Bring up the commiter and consensus nodes using docker compose.
function networkUp() {
  checkPrereqs
  # generate artifacts if they don't exist
  if [ ! -d "organizations/commiterOrganizations" ]; then
    createOrgs
  fi

  COMPOSE_FILES="-f ${COMPOSE_FILE_BASE}"

  if [ "${DATABASE}" == "couchdb" ]; then
    COMPOSE_FILES="${COMPOSE_FILES} -f ${COMPOSE_FILE_COUCH}"
  fi

  IMAGE_TAG=$IMAGETAG docker-compose ${COMPOSE_FILES} up -d 2>&1

  docker ps -a
  if [ $? -ne 0 ]; then
    fatalln "Unable to start network"
  fi
}

# call the script to create the channel, join the commiters of org1 and org2,
# and then update the anchor commiters for each organization
function createChannel() {
  # Bring up the network if it is not already up.

  if [ ! -d "organizations/commiterOrganizations" ]; then
    infoln "Bringing up network"
    networkUp
  fi

  # now run the script that creates a channel. This script uses configtxgen once
  # to create the channel creation transaction and the anchor commiter updates.
  scripts/createChannel.sh $CHANNEL_NAME $CLI_DELAY $MAX_RETRY $VERBOSE
}


## Call the script to deploy a chaincode to the channel
function deployCC() {
  scripts/deployCC.sh $CHANNEL_NAME $CC_NAME $CC_SRC_PATH $CC_SRC_LANGUAGE $CC_VERSION $CC_SEQUENCE $CC_INIT_FCN $CC_END_POLICY $CC_COLL_CONFIG $CLI_DELAY $MAX_RETRY $VERBOSE

  if [ $? -ne 0 ]; then
    fatalln "Deploying chaincode failed"
  fi
}


# Tear down running network
function networkDown() {
  # stop org3 containers also in addition to org1 and org2, in case we were running sample to add org3
  docker-compose -f $COMPOSE_FILE_BASE -f $COMPOSE_FILE_COUCH -f $COMPOSE_FILE_CA down --volumes --remove-orphans
  docker-compose -f $COMPOSE_FILE_COUCH_ORG3 -f $COMPOSE_FILE_ORG3 down --volumes --remove-orphans
  docker-compose -f $COMPOSE_FILE_CONSENSUS3 down --volumes --remove-orphans
  docker-compose -f $COMPOSE_FILE_PEER1 down --volumes --remove-orphans
  rm -rf addConsensus3/chaindata/*
  docker volume prune -f
  # Don't remove the generated artifacts -- note, the ledgers are always removed
  if [ "$MODE" != "restart" ]; then
    # Bring down the network, deleting the volumes
    #Cleanup the chaincode containers
    clearContainers
    #Cleanup images
    removeUnwantedImages
    # remove consensus block and other channel configuration transactions and certs
    docker run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf system-genesis-block/*.block organizations/commiterOrganizations organizations/consensusOrganizations'
    ## remove fabric ca artifacts
    docker run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf organizations/mh-ca/org1/msp organizations/mh-ca/org1/tls-cert.pem organizations/mh-ca/org1/ca-cert.pem organizations/mh-ca/org1/IssuerPublicKey organizations/mh-ca/org1/IssuerRevocationPublicKey organizations/mh-ca/org1/mh-ca-server.db'
    docker run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf organizations/mh-ca/org2/msp organizations/mh-ca/org2/tls-cert.pem organizations/mh-ca/org2/ca-cert.pem organizations/mh-ca/org2/IssuerPublicKey organizations/mh-ca/org2/IssuerRevocationPublicKey organizations/mh-ca/org2/mh-ca-server.db'
    docker run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf organizations/mh-ca/consensusOrg/msp organizations/mh-ca/consensusOrg/tls-cert.pem organizations/mh-ca/consensusOrg/ca-cert.pem organizations/mh-ca/consensusOrg/IssuerPublicKey organizations/mh-ca/consensusOrg/IssuerRevocationPublicKey organizations/mh-ca/consensusOrg/mh-ca-server.db'
    docker run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf addOrg3/mh-ca/org3/msp addOrg3/mh-ca/org3/tls-cert.pem addOrg3/mh-ca/org3/ca-cert.pem addOrg3/mh-ca/org3/IssuerPublicKey addOrg3/mh-ca/org3/IssuerRevocationPublicKey addOrg3/mh-ca/org3/mh-ca-server.db'
    # remove channel and script artifacts
    docker run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf channel-artifacts log.txt *.tar.gz'
  fi
}

# Obtain the OS and Architecture string that will be used to select the correct
# native binaries for your platform, e.g., darwin-amd64 or linux-amd64
OS_ARCH=$(echo "$(uname -s | tr '[:upper:]' '[:lower:]' | sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
# Using crpto vs CA. default is cryptogen
CRYPTO="cryptogen"
# timeout duration - the duration the CLI should wait for a response from
# another container before giving up
MAX_RETRY=5
# default for delay between commands
CLI_DELAY=3
# channel name defaults to "mychannel"
CHANNEL_NAME="mychannel"
# chaincode name defaults to "NA"
CC_NAME="NA"
# chaincode path defaults to "NA"
CC_SRC_PATH="NA"
# endorsement policy defaults to "NA". This would allow chaincodes to use the majority default policy.
CC_END_POLICY="NA"
# collection configuration defaults to "NA"
CC_COLL_CONFIG="NA"
# chaincode init function defaults to "NA"
CC_INIT_FCN="NA"
# use this as the default docker-compose yaml definition
COMPOSE_FILE_BASE=docker/docker-compose-test-net.yaml
# docker-compose.yaml file if you are using couchdb
COMPOSE_FILE_COUCH=docker/docker-compose-couch.yaml
# certificate authorities compose file
COMPOSE_FILE_CA=docker/docker-compose-ca.yaml
# use this as the docker compose couch file for org3
COMPOSE_FILE_COUCH_ORG3=addOrg3/docker/docker-compose-couch-org3.yaml
# use this as the default docker-compose yaml definition for org3
COMPOSE_FILE_ORG3=addOrg3/docker/docker-compose-org3.yaml

COMPOSE_FILE_CONSENSUS3=addConsensus3/docker/docker-compose-consensus3.yaml

COMPOSE_FILE_PEER1=addCommiter/docker/docker-compose-commiter1.yaml
#
# chaincode language defaults to "NA"
CC_SRC_LANGUAGE="NA"
# Chaincode version
CC_VERSION="1.0"
# Chaincode definition sequence
CC_SEQUENCE=1
# default image tag
IMAGETAG="latest"
# default ca image tag
CA_IMAGETAG="latest"
# default database
DATABASE="leveldb"

# Parse commandline args

## Parse mode
if [[ $# -lt 1 ]] ; then
  printHelp
  exit 0
else
  MODE=$1
  shift
fi

# parse a createChannel subcommand if used
if [[ $# -ge 1 ]] ; then
  key="$1"
  if [[ "$key" == "createChannel" ]]; then
      export MODE="createChannel"
      shift
  fi
fi

# parse flags

while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -h )
    printHelp $MODE
    exit 0
    ;;
  -c )
    CHANNEL_NAME="$2"
    shift
    ;;
  -ca )
    CRYPTO="Certificate Authorities"
    ;;
  -r )
    MAX_RETRY="$2"
    shift
    ;;
  -d )
    CLI_DELAY="$2"
    shift
    ;;
  -s )
    DATABASE="$2"
    shift
    ;;
  -ccl )
    CC_SRC_LANGUAGE="$2"
    shift
    ;;
  -ccn )
    CC_NAME="$2"
    shift
    ;;
  -ccv )
    CC_VERSION="$2"
    shift
    ;;
  -ccs )
    CC_SEQUENCE="$2"
    shift
    ;;
  -ccp )
    CC_SRC_PATH="$2"
    shift
    ;;
  -ccep )
    CC_END_POLICY="$2"
    shift
    ;;
  -cccg )
    CC_COLL_CONFIG="$2"
    shift
    ;;
  -cci )
    CC_INIT_FCN="$2"
    shift
    ;;
  -i )
    IMAGETAG="$2"
    shift
    ;;
  -cai )
    CA_IMAGETAG="$2"
    shift
    ;;
  -verbose )
    VERBOSE=true
    shift
    ;;
  * )
    errorln "Unknown flag: $key"
    printHelp
    exit 1
    ;;
  esac
  shift
done

# Are we generating crypto material with this command?
if [ ! -d "organizations/commiterOrganizations" ]; then
  CRYPTO_MODE="with crypto from '${CRYPTO}'"
else
  CRYPTO_MODE=""
fi

# Determine mode of operation and printing out what we asked for
if [ "$MODE" == "up" ]; then
  infoln "Starting nodes with CLI timeout of '${MAX_RETRY}' tries and CLI delay of '${CLI_DELAY}' seconds and using database '${DATABASE}' ${CRYPTO_MODE}"
elif [ "$MODE" == "createChannel" ]; then
  infoln "Creating channel '${CHANNEL_NAME}'."
  infoln "If network is not up, starting nodes with CLI timeout of '${MAX_RETRY}' tries and CLI delay of '${CLI_DELAY}' seconds and using database '${DATABASE} ${CRYPTO_MODE}"
elif [ "$MODE" == "down" ]; then
  infoln "Stopping network"
elif [ "$MODE" == "restart" ]; then
  infoln "Restarting network"
elif [ "$MODE" == "deployCC" ]; then
  infoln "deploying chaincode on channel '${CHANNEL_NAME}'"
else
  printHelp
  exit 1
fi

if [ "${MODE}" == "up" ]; then
  networkUp
elif [ "${MODE}" == "createChannel" ]; then
  createChannel
elif [ "${MODE}" == "deployCC" ]; then
  deployCC
elif [ "${MODE}" == "down" ]; then
  networkDown
else
  printHelp
  exit 1
fi
