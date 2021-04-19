#!/bin/bash

COMPOSE_FILE=docker/docker-compose-consensus3.yaml
IMAGETAG="latest"
CHANNEL_NAME="$1"
DELAY="$2"
MAX_RETRY="$3"
VERBOSE="$4"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}


export PATH=${PWD}/../../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}/../../config/
export CORE_PEER_TLS_ENABLED=true
export CONSENSUS_CA=${PWD}/../organizations/consensusOrganizations/example.com/consensuss/consensus.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export CONSENSUS3_CA=${PWD}/../organizations/consensusOrganizations/example.com/consensuss/consensus3.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export CONSENSUS3_ADMIN_TLS_SIGN_CERT=${PWD}/../organizations/consensusOrganizations/example.com/consensuss/consensus3.example.com/tls/server.crt
export CONSENSUS3_ADMIN_TLS_PRIVATE_KEY=${PWD}/../organizations/consensusOrganizations/example.com/consensuss/consensus3.example.com/tls/server.key
export PEER0_ORG1_CA=${PWD}/../organizations/commiterOrganizations/org1.example.com/commiters/commiter0.org1.example.com/tls/ca.crt
export PEER0_ORG2_CA=${PWD}/../organizations/commiterOrganizations/org2.example.com/commiters/commiter0.org2.example.com/tls/ca.crt
export PEER0_ORG3_CA=${PWD}/../organizations/commiterOrganizations/org3.example.com/commiters/commiter0.org3.example.com/tls/ca.crt
# import utils
. ../scripts/utils.sh
. ./mh-ca/registerEnroll.sh

if [ ! -d "chaindata" ]; then
	mkdir chaindata
else
  rm -r chaindata/*
fi

if [ ! -d "log.txt" ]; then
	rm log.txt
fi

networkUp(){
  infoln "create consensus..."
  createConsensus3

  COMPOSE_FILE_CONSENSUS3="-f ${COMPOSE_FILE}"
  IMAGE_TAG=$IMAGETAG docker-compose ${COMPOSE_FILE_CONSENSUS3} up -d 2>&1
  docker ps -a
  if [ $? -ne 0 ]; then
    fatalln "Unable to start network"
  fi
}

joinChannel() {
  setGlobals 1
	# Poll in case the raft leader is not set yet
	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		osnadmin channel join --channelID $CHANNEL_NAME --config-block ../channel-artifacts/${CHANNEL_NAME}.block -o localhost:4053 --ca-file "$CONSENSUS3_CA" --client-cert "$CONSENSUS3_ADMIN_TLS_SIGN_CERT" --client-key "$CONSENSUS3_ADMIN_TLS_PRIVATE_KEY" >log.txt
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Channel creation failed"
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}

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
    export CORE_PEER_MSPCONFIGPATH=${PWD}/../organizations/commiterOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/../organizations/commiterOrganizations/org2.example.com/users/Admin@org2.example.com/msp
    export CORE_PEER_ADDRESS=localhost:9051

  elif [ $USING_ORG -eq 3 ]; then
    export CORE_PEER_LOCALMSPID="Org3MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG3_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/../organizations/commiterOrganizations/org3.example.com/users/Admin@org3.example.com/msp
    export CORE_PEER_ADDRESS=localhost:11051
  elif [ $USING_ORG -eq 4 ]; then
    export CORE_PEER_LOCALMSPID="ConsensusMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$CONSENSUS_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/../organizations/consensusOrganizations/example.com/users/Admin@example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
  else
    errorln "ORG Unknown"
  fi

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}

# fetchChannelConfig <org> <channel_id> <output_json>
# Writes the current channel config for a given channel to a JSON file
# NOTE: this must be run in a CLI container since it requires configtxlator
fetchChannelConfig() {
  ORG=$1
  CHANNEL=$2
  OUTPUT=$3

  setGlobals $ORG

  infoln "Fetching the most recent configuration block for the channel"
  set -x
  commiter channel fetch config chaindata/config_block.pb -o consensus.example.com:7050 --ordererTLSHostnameOverride consensus.example.com -c $CHANNEL --tls --cafile "$CONSENSUS_CA"
  { set +x; } 2>/dev/null

  infoln "Decoding config block to JSON and isolating config to ${OUTPUT}"
  set -x
  configtxlator proto_decode --input chaindata/config_block.pb --type common.Block --output chaindata/temp_config.Block
  cat chaindata/temp_config.Block | jq .data.data[0].payload.data.config >"${OUTPUT}"
  { set +x; } 2>/dev/null
}
createConfigUpdate() {
  CHANNEL=$1
  ORIGINAL=$2
  MODIFIED=$3
  OUTPUT=$4

  set -x
  configtxlator proto_encode --input "${ORIGINAL}" --type common.Config --output chaindata/original_config.pb
  configtxlator proto_encode --input "${MODIFIED}" --type common.Config --output chaindata/modified_config.pb
  configtxlator compute_update --channel_id "${CHANNEL}" --original chaindata/original_config.pb --updated chaindata/modified_config.pb --output chaindata/config_update.pb
  configtxlator proto_decode --input chaindata/config_update.pb --type common.ConfigUpdate --output chaindata/config_update.json
  echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL'", "type":2}},"data":{"config_update":'$(cat chaindata/config_update.json)'}}}' | jq . >chaindata/config_update_in_envelope.json
  configtxlator proto_encode --input chaindata/config_update_in_envelope.json --type common.Envelope --output "${OUTPUT}"
  { set +x; } 2>/dev/null
}
# signConfigtxAsCommiterOrg <org> <configtx.pb>
# Set the commiterOrg admin of an org and sign the config update
signConfigtxAsCommiterOrg() {
  ORG=$1
  CONFIGTXFILE=$2
  setGlobals $ORG
  set -x
  commiter channel signconfigtx -f "${CONFIGTXFILE}"
  { set +x; } 2>/dev/null
}

createModifyChannelConfig() {
  mkdir chaindata
  fetchChannelConfig 1 ${CHANNEL_NAME} chaindata/config.json
  cat chaindata/config.json | jq  -c '.channel_group.groups.Orderer.groups.ConsensusOrg.values.Endpoints.value.addresses | .[3]="consensus3.example.com:4050"' > chaindata/temp1.json
  jq -s '.[0] * {"channel_group":{"groups":{"Orderer":{"groups": {"ConsensusOrg":{"values":{"Endpoints":{"value":{"addresses":.[1]}}}}}}}}}' chaindata/config.json chaindata/temp1.json > chaindata/temp_config_1.json
  TEMP_TLS_CERT=$(cat ../organizations/consensusOrganizations/example.com/consensuss/consensus3.example.com/tls/server.crt | base64 | sed -e ':a;N;s/\n//;ta')
  cat chaindata/temp_config_1.json | jq -c '.channel_group.groups.Orderer.values.OrdererType.value.metadata.consenters | .[3]={"client_tls_cert":"TEMP_TLS_CERT","host":"consensus3.example.com","port":4050,"server_tls_cert":"TEMP_TLS_CERT"}'|sed  "s/TEMP_TLS_CERT/${TEMP_TLS_CERT}/g" > chaindata/temp2.json
  jq -s '.[0] * {"channel_group":{"groups":{"Orderer":{"values":{"OrdererType":{"value":{"metadata":{"consenters":.[1]}}}}}}}}' chaindata/temp_confg_1.json chaindata/temp2.json > chaindata/modified_config.json
}
infoln "Creating order3 ..."
networkUp

infoln "Joining order3 commiter to the channel..."
joinChannel
successln "Channel '$CHANNEL_NAME' created"

infoln "Modifing order3 config to the channel..."
createModifyChannelConfig
createConfigUpdate ${CHANNEL_NAME} chaindata/config.json chaindata/modified_config.json chaindata/consensus_update_in_envelope.pb

infoln "Signing config transaction"
signConfigtxAsCommiterOrg 4 chaindata/consensus_update_in_envelope.pb


infoln "Submitting transaction from a different commiter (commiter0.org2) which also signs it"
setGlobals 2
set -x
commiter channel update -f chaindata/consensus_update_in_envelope.pb -c ${CHANNEL_NAME} -o consensus.example.com:7050 --ordererTLSHostnameOverride consensus.example.com --tls --cafile "$CONSENSUS_CA"
{ set +x; } 2>/dev/null

successln "Config transaction to add org3 to network submitted"