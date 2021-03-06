#!/bin/bash

source scripts/utils.sh

CHANNEL_NAME=${1:-"mychannel"}
LOCAL_COMMITER_NAME=${2}
LOCAL_COMMITER_PORT=${3}
CC_NAME=${4}
CC_SRC_PATH=${5}
CC_SRC_LANGUAGE=${6}
CC_VERSION=${7:-"1.0"}
CC_SEQUENCE=${8:-"1"}
CC_INIT_FCN=${9:-"NA"}
CC_END_POLICY=${10:-"NA"}
CC_COLL_CONFIG=${11:-"NA"}
DELAY=${12:-"3"}
MAX_RETRY=${13:-"5"}
VERBOSE=${14:-"false"}

COMMITER_SET_HOST=$(echo $LOCAL_COMMITER_NAME".org1.example.com")
. ../scripts/utils.sh

println "executing with the following"
println "- CHANNEL_NAME: ${C_GREEN}${CHANNEL_NAME}${C_RESET}"
println "- CC_NAME: ${C_GREEN}${CC_NAME}${C_RESET}"
println "- CC_SRC_PATH: ${C_GREEN}${CC_SRC_PATH}${C_RESET}"
println "- CC_SRC_LANGUAGE: ${C_GREEN}${CC_SRC_LANGUAGE}${C_RESET}"
println "- CC_VERSION: ${C_GREEN}${CC_VERSION}${C_RESET}"
println "- CC_SEQUENCE: ${C_GREEN}${CC_SEQUENCE}${C_RESET}"
println "- CC_END_POLICY: ${C_GREEN}${CC_END_POLICY}${C_RESET}"
println "- CC_COLL_CONFIG: ${C_GREEN}${CC_COLL_CONFIG}${C_RESET}"
println "- CC_INIT_FCN: ${C_GREEN}${CC_INIT_FCN}${C_RESET}"
println "- DELAY: ${C_GREEN}${DELAY}${C_RESET}"
println "- MAX_RETRY: ${C_GREEN}${MAX_RETRY}${C_RESET}"
println "- VERBOSE: ${C_GREEN}${VERBOSE}${C_RESET}"

export FABRIC_CFG_PATH=$PWD/../../config/
export PATH=${PWD}/../../bin:${PWD}:$PATH
export CONSENSUS_CA=${PWD}/../organizations/consensusOrganizations/example.com/consensuss/consensus.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export CORE_PEER_TLS_ENABLED=true
export PEER0_ORG1_CA=${PWD}/../organizations/commiterOrganizations/org1.example.com/commiters/commiter0.org1.example.com/tls/ca.crt
export PEER0_ORG2_CA=${PWD}/../organizations/commiterOrganizations/org2.example.com/commiters/commiter0.org2.example.com/tls/ca.crt
export LOCAL_PEER_ORG1_CA=${PWD}/../organizations/commiterOrganizations/org1.example.com/commiters/${COMMITER_SET_HOST}/tls/ca.crt

#User has not provided a name
if [ -z "$CC_NAME" ] || [ "$CC_NAME" = "NA" ]; then
  fatalln "No chaincode name was provided. Valid call example: ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go"

# User has not provided a path
elif [ -z "$CC_SRC_PATH" ] || [ "$CC_SRC_PATH" = "NA" ]; then
  fatalln "No chaincode path was provided. Valid call example: ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go"

# User has not provided a language
elif [ -z "$CC_SRC_LANGUAGE" ] || [ "$CC_SRC_LANGUAGE" = "NA" ]; then
  fatalln "No chaincode language was provided. Valid call example: ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go"

## Make sure that the path to the chaincode exists
elif [ ! -d "$CC_SRC_PATH" ]; then
  println "Path $CC_SRC_PATH"
  fatalln "Path to chaincode does not exist. Please provide different path."
fi

CC_SRC_LANGUAGE=$(echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:])

# do some language specific preparation to the chaincode before packaging
if [ "$CC_SRC_LANGUAGE" = "go" ]; then
  CC_RUNTIME_LANGUAGE=golang

  infoln "Vendoring Go dependencies at $CC_SRC_PATH"
  pushd $CC_SRC_PATH
  GO111MODULE=on go mod vendor
  popd
  successln "Finished vendoring Go dependencies"

elif [ "$CC_SRC_LANGUAGE" = "java" ]; then
  CC_RUNTIME_LANGUAGE=java

  infoln "Compiling Java code..."
  pushd $CC_SRC_PATH
  ./gradlew installDist
  popd
  successln "Finished compiling Java code"
  CC_SRC_PATH=$CC_SRC_PATH/build/install/$CC_NAME

elif [ "$CC_SRC_LANGUAGE" = "javascript" ]; then
  CC_RUNTIME_LANGUAGE=node

elif [ "$CC_SRC_LANGUAGE" = "typescript" ]; then
  CC_RUNTIME_LANGUAGE=node

  infoln "Compiling TypeScript code into JavaScript..."
  pushd $CC_SRC_PATH
  npm install
  npm run build
  popd
  successln "Finished compiling TypeScript code into JavaScript"

else
  fatalln "The chaincode language ${CC_SRC_LANGUAGE} is not supported by this script. Supported chaincode languages are: go, java, javascript, and typescript"
  exit 1
fi

INIT_REQUIRED="--init-required"
# check if the init fcn should be called
if [ "$CC_INIT_FCN" = "NA" ]; then
  INIT_REQUIRED=""
fi

if [ "$CC_END_POLICY" = "NA" ]; then
  CC_END_POLICY=""
else
  CC_END_POLICY="--signature-policy $CC_END_POLICY"
fi

if [ "$CC_COLL_CONFIG" = "NA" ]; then
  CC_COLL_CONFIG=""
else
  CC_COLL_CONFIG="--collections-config $CC_COLL_CONFIG"
fi

# import utils


packageChaincode() {
  set -x
  commiter lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode packaging has failed"
  successln "Chaincode is packaged"
}

# installChaincode COMMITER ORG
installChaincode() {
  ORG=$1
  setGlobals $ORG
  set -x
  commiter lifecycle chaincode install ${CC_NAME}.tar.gz >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode installation on commiter0.org${ORG} has failed"
  successln "Chaincode is installed on commiter0.org${ORG}"
}

# queryInstalled COMMITER ORG
queryInstalled() {
  ORG=$1
  setGlobals $ORG
  set -x
  commiter lifecycle chaincode queryinstalled >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
  verifyResult $res "Query installed on commiter0.org${ORG} has failed"
  successln "Query installed successful on commiter0.org${ORG} on channel"
}

# approveForMyOrg VERSION COMMITER ORG
approveForMyOrg() {
  ORG=$1
  setGlobals $ORG
  set -x
  commiter lifecycle chaincode approveformyorg -o consensus.example.com:7050 --ordererTLSHostnameOverride consensus.example.com --tls --cafile "$CONSENSUS_CA" --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode definition approved on commiter0.org${ORG} on channel '$CHANNEL_NAME' failed"
  successln "Chaincode definition approved on commiter0.org${ORG} on channel '$CHANNEL_NAME'"
}

# checkCommitReadiness VERSION COMMITER ORG
checkCommitReadiness() {
  ORG=$1
  shift 1
  setGlobals $ORG
  infoln "Checking the commit readiness of the chaincode definition on commiter0.org${ORG} on channel '$CHANNEL_NAME'..."
  local rc=1
  local COUNTER=1
  # continue to poll
  # we either get a successful response, or reach MAX RETRY
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    infoln "Attempting to check the commit readiness of the chaincode definition on commiter0.org${ORG}, Retry after $DELAY seconds."
    set -x
    commiter lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} --output json >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    let rc=0
    for var in "$@"; do
      grep "$var" log.txt &>/dev/null || let rc=1
    done
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    infoln "Checking the commit readiness of the chaincode definition successful on commiter0.org${ORG} on channel '$CHANNEL_NAME'"
  else
    fatalln "After $MAX_RETRY attempts, Check commit readiness result on commiter0.org${ORG} is INVALID!"
  fi
}

# commitChaincodeDefinition VERSION COMMITER ORG (COMMITER ORG)...
commitChaincodeDefinition() {
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of commiter and org parameters "

  # while 'commiter chaincode' command can get the consensus endpoint from the
  # commiter (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  commiter lifecycle chaincode commit -o consensus.example.com:7050 --ordererTLSHostnameOverride consensus.example.com --tls --cafile "$CONSENSUS_CA" --channelID $CHANNEL_NAME --name ${CC_NAME} --peerAddresses ${COMMITER_SET_HOST}:${LOCAL_COMMITER_PORT} --tlsRootCertFiles ${LOCAL_PEER_ORG1_CA} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode definition commit failed on commiter0.org${ORG} on channel '$CHANNEL_NAME' failed"
  successln "Chaincode definition committed on channel '$CHANNEL_NAME'"
}

# queryCommitted ORG
queryCommitted() {
  ORG=$1
  setGlobals $ORG
  EXPECTED_RESULT="Version: ${CC_VERSION}, Sequence: ${CC_SEQUENCE}, Endorsement Plugin: escc, Validation Plugin: vscc"
  infoln "Querying chaincode definition on commiter0.org${ORG} on channel '$CHANNEL_NAME'..."
  local rc=1
  local COUNTER=1
  # continue to poll
  # we either get a successful response, or reach MAX RETRY
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    infoln "Attempting to Query committed status on commiter0.org${ORG}, Retry after $DELAY seconds."
    set -x
    commiter lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME} >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    test $res -eq 0 && VALUE=$(cat log.txt | grep -o '^Version: '$CC_VERSION', Sequence: [0-9]*, Endorsement Plugin: escc, Validation Plugin: vscc')
    test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    successln "Query chaincode definition successful on commiter0.org${ORG} on channel '$CHANNEL_NAME'"
  else
    fatalln "After $MAX_RETRY attempts, Query chaincode definition result on commiter0.org${ORG} is INVALID!"
  fi
}


verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}

chaincodeInvokeInit() {
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of commiter and org parameters "

  # while 'commiter chaincode' command can get the consensus endpoint from the
  # commiter (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  fcn_call='{"function":"'${CC_INIT_FCN}'","Args":[]}'
  infoln "invoke fcn call:${fcn_call}"
  commiter chaincode invoke -o consensus.example.com:7050 --ordererTLSHostnameOverride consensus.example.com --tls --cafile "$CONSENSUS_CA" -C $CHANNEL_NAME -n ${CC_NAME} --peerAddresses ${COMMITER_SET_HOST}:${LOCAL_COMMITER_PORT} --tlsRootCertFiles LOCAL_PEER_ORG1_CA  --isInit -c ${fcn_call} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Invoke execution on $COMMITERS failed "
  successln "Invoke transaction successful on $COMMITERS on channel '$CHANNEL_NAME'"
}

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
    export CORE_PEER_ADDRESS=${COMMITER_SET_HOST}:${LOCAL_COMMITER_PORT}
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/../organizations/commiterOrganizations/org2.example.com/users/Admin@org2.example.com/msp
    export CORE_PEER_ADDRESS=localhost:9051
  else
    errorln "ORG Unknown"
  fi

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}


## package the chaincode
#packageChaincode
cp ../supervision.tar.gz supervision.tar.gz

## Install chaincode on commiter0.org1 and commiter0.org2
infoln "Installing chaincode on commiter0.org1..."
installChaincode 1

## query whether the chaincode is installed
queryInstalled 1

### approve the definition for org1
#approveForMyOrg 1
#
### check whether the chaincode definition is ready to be committed
### expect org1 to have approved and org2 not to
#checkCommitReadiness 1 "\"Org1MSP\": true" "\"Org2MSP\": false"
#checkCommitReadiness 2 "\"Org1MSP\": true" "\"Org2MSP\": false"
#
### now approve also for org2
#approveForMyOrg 2
#
### check whether the chaincode definition is ready to be committed
### expect them both to have approved
#checkCommitReadiness 1 "\"Org1MSP\": true" "\"Org2MSP\": true"
#checkCommitReadiness 2 "\"Org1MSP\": true" "\"Org2MSP\": true"
#
### now that we know for sure both orgs have approved, commit the definition
#commitChaincodeDefinition 1 2
#
### query on both orgs to see that the definition committed successfully
#queryCommitted 1
#queryCommitted 2
#
### Invoke the chaincode - this does require that the chaincode have the 'initLedger'
### method defined
#if [ "$CC_INIT_FCN" = "NA" ]; then
#  infoln "Chaincode initialization is not required"
#else
#  chaincodeInvokeInit 1 2
#fi

exit 0
