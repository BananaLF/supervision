#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This is a collection of bash functions used by different scripts

# imports
. scripts/utils.sh

export CORE_PEER_TLS_ENABLED=true
export CONSENSUS_CA=${PWD}/organizations/consensusOrganizations/example.com/consensuss/consensus.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export CONSENSUS1_CA=${PWD}/organizations/consensusOrganizations/example.com/consensuss/consensus1.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export CONSENSUS2_CA=${PWD}/organizations/consensusOrganizations/example.com/consensuss/consensus2.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

export PEER0_ORG1_CA=${PWD}/organizations/commiterOrganizations/org1.example.com/commiters/commiter0.org1.example.com/tls/ca.crt
export PEER0_ORG2_CA=${PWD}/organizations/commiterOrganizations/org2.example.com/commiters/commiter0.org2.example.com/tls/ca.crt
export PEER0_ORG3_CA=${PWD}/organizations/commiterOrganizations/org3.example.com/commiters/commiter0.org3.example.com/tls/ca.crt
export CONSENSUS_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/consensusOrganizations/example.com/consensuss/consensus.example.com/tls/server.crt
export CONSENSUS_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/consensusOrganizations/example.com/consensuss/consensus.example.com/tls/server.key
export CONSENSUS1_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/consensusOrganizations/example.com/consensuss/consensus1.example.com/tls/server.crt
export CONSENSUS1_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/consensusOrganizations/example.com/consensuss/consensus1.example.com/tls/server.key
export CONSENSUS2_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/consensusOrganizations/example.com/consensuss/consensus2.example.com/tls/server.crt
export CONSENSUS2_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/consensusOrganizations/example.com/consensuss/consensus2.example.com/tls/server.key

# Set environment variables for the commiter org
setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  infoln "Using organization ${USING_ORG}"
  if [ $USING_ORG -eq 1 ]; then
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/commiterOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/commiterOrganizations/org2.example.com/users/Admin@org2.example.com/msp
    export CORE_PEER_ADDRESS=localhost:9051

  elif [ $USING_ORG -eq 3 ]; then
    export CORE_PEER_LOCALMSPID="Org3MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG3_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/commiterOrganizations/org3.example.com/users/Admin@org3.example.com/msp
    export CORE_PEER_ADDRESS=localhost:11051
  else
    errorln "ORG Unknown"
  fi

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}

# Set environment variables for use in the CLI container 
setGlobalsCLI() {
  setGlobals $1

  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  if [ $USING_ORG -eq 1 ]; then
    export CORE_PEER_ADDRESS=commiter0.org1.example.com:7051
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_ADDRESS=commiter0.org2.example.com:9051
  elif [ $USING_ORG -eq 3 ]; then
    export CORE_PEER_ADDRESS=commiter0.org3.example.com:11051
  else
    errorln "ORG Unknown"
  fi
}

# parseCommiterConnectionParameters $@
# Helper function that sets the commiter connection parameters for a chaincode
# operation
parseCommiterConnectionParameters() {
  PEER_CONN_PARMS=()
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    PEER="peer0.org$1"
    ## Set peer addresses
    if [ -z "$PEERS" ]
    then
	PEERS="$PEER"
    else
	PEERS="$PEERS $PEER"
    fi
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
    ## Set path to TLS certificate
    CA=PEER0_ORG$1_CA
    TLSINFO=(--tlsRootCertFiles "${!CA}")
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" "${TLSINFO[@]}")
    # shift by one to get to the next organization
    shift
  done
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}
