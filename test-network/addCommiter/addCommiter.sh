#!/bin/bash

# imports
. ../scripts/utils.sh
. ./mh-ca/registerEnroll.sh

CHANNEL_NAME="$1"
IMAGETAG="latest"
LOCAL_COMMITER_NAME="$2"
LOCAL_COMMITER_PORT="$3"
DELAY="$4"
MAX_RETRY="$5"
VERBOSE="$6"
: ${CHANNEL_NAME:="mychannel"}
: ${LOCAL_COMMITER_NAME:="commiter1"}
: ${LOCAL_COMMITER_PORT:="7051"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="true"}

COMMITER_SET_HOST=$(echo $LOCAL_COMMITER_NAME".org1.example.com")

export PATH=${PWD}/../../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}/../../config

export PEER0_ORG1_CA=${PWD}/../organizations/commiterOrganizations/org1.example.com/commiters/commiter0.org1.example.com/tls/ca.crt
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
export CORE_PEER_MSPCONFIGPATH=${PWD}/../organizations/commiterOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=${COMMITER_SET_HOST}:$LOCAL_COMMITER_PORT
export CORE_PEER_TLS_ENABLED=true


BLOCKFILE="${PWD}/../channel-artifacts/${CHANNEL_NAME}.block"
COMPOSE_FILE=docker/docker-compose-commiter1.yaml

networkUp(){
  infoln "create consensus..."
  createCommiter $LOCAL_COMMITER_NAME

  COMPOSE_FILE_CONSENSUS3="-f ${COMPOSE_FILE}"
  IMAGE_TAG=$IMAGETAG docker-compose ${COMPOSE_FILE_CONSENSUS3} up -d 2>&1
  docker ps -a
  if [ $? -ne 0 ]; then
    fatalln "Unable to start network"
  fi
}

# joinChannel ORG
joinChannel() {
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
    commiter channel join -b $BLOCKFILE >&log.txt
    res=$?
    { set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "After $MAX_RETRY attempts, ${COMMITER_SET_HOST} has failed to join channel '$CHANNEL_NAME' "
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}

infoln "Creating file .env ..."
cat docker/.env_template | sed "s/commiter/${LOCAL_COMMITER_NAME}/g" | sed "s/c_port/${LOCAL_COMMITER_PORT}/g" > docker/.env
cat docker/docker-compose-commiter1-template.yaml | sed "s/COMMITER_DOMAIN_NAME/${COMMITER_SET_HOST}/g" > docker/docker-compose-commiter1.yaml

infoln "Creating ${COMMITER_SET_HOST} ..."
networkUp

## Join all the commiters to the channel
infoln "Joining org1 commiter to the channel..."
joinChannel

