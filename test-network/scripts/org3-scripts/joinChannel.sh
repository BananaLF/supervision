#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# This script is designed to be run in the cli container as the
# second step of the EYFN tutorial. It joins the org3 commiters to the
# channel previously setup in the BYFN tutorial and install the
# chaincode as version 2.0 on commiter0.org3.
#

CHANNEL_NAME="$1"
DELAY="$2"
TIMEOUT="$3"
VERBOSE="$4"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${TIMEOUT:="10"}
: ${VERBOSE:="false"}
COUNTER=1
MAX_RETRY=5

# import environment variables
. scripts/envVar.sh

# joinChannel ORG
joinChannel() {
  ORG=$1
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
	verifyResult $res "After $MAX_RETRY attempts, commiter0.org${ORG} has failed to join channel '$CHANNEL_NAME' "
}

setAnchorCommiter() {
  ORG=$1
  scripts/setAnchorCommiter.sh $ORG $CHANNEL_NAME
}

setGlobalsCLI 3
BLOCKFILE="${CHANNEL_NAME}.block"

echo "Fetching channel config block from consensus..."
set -x
commiter channel fetch 0 $BLOCKFILE -o consensus.example.com:7050 --ordererTLSHostnameOverride consensus.example.com -c $CHANNEL_NAME --tls --cafile "$CONSENSUS_CA" >&log.txt
res=$?
{ set +x; } 2>/dev/null
cat log.txt
verifyResult $res "Fetching config block from consensus has failed"

infoln "Joining org3 commiter to the channel..."
joinChannel 3

infoln "Setting anchor commiter for org3..."
setAnchorCommiter 3

successln "Channel '$CHANNEL_NAME' joined"
successln "Org3 commiter successfully added to network"
