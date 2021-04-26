#!/bin/bash


function createConsensus3() {
  LOCAL_CONSENSUS_NAME=$1
  export CA_ROOT_PATH=${PWD}/..
  export FABRIC_CA_CLIENT_HOME=${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com

  ###### Consensus3
  infoln "Registering ${LOCAL_CONSENSUS_NAME}"
  set -x
  mh-ca-client register --caname ca-consensus --id.name ${LOCAL_CONSENSUS_NAME} --id.secret ${LOCAL_CONSENSUS_NAME}pw --id.type consensus --tls.certfiles "${CA_ROOT_PATH}/organizations/mh-ca/consensusOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the ${LOCAL_CONSENSUS_NAME} msp"
  set -x
  mh-ca-client enroll -u https://${LOCAL_CONSENSUS_NAME}:${LOCAL_CONSENSUS_NAME}pw@localhost:9054 --caname ca-consensus -M "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/${LOCAL_CONSENSUS_NAME}.example.com/msp" --csr.hosts ${LOCAL_CONSENSUS_NAME}.example.com --csr.hosts localhost --tls.certfiles "${CA_ROOT_PATH}/organizations/mh-ca/consensusOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/msp/config.yaml" "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/${LOCAL_CONSENSUS_NAME}.example.com/msp/config.yaml"

  infoln "Generating the ${LOCAL_CONSENSUS_NAME}-tls certificates"
  set -x
  mh-ca-client enroll -u https://${LOCAL_CONSENSUS_NAME}:${LOCAL_CONSENSUS_NAME}pw@localhost:9054 --caname ca-consensus -M "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/${LOCAL_CONSENSUS_NAME}.example.com/tls" --enrollment.profile tls --csr.hosts ${LOCAL_CONSENSUS_NAME}.example.com --csr.hosts localhost --tls.certfiles "${CA_ROOT_PATH}/organizations/mh-ca/consensusOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/${LOCAL_CONSENSUS_NAME}.example.com/tls/tlscacerts/"* "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/${LOCAL_CONSENSUS_NAME}.example.com/tls/ca.crt"
  cp "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/${LOCAL_CONSENSUS_NAME}.example.com/tls/signcerts/"* "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/${LOCAL_CONSENSUS_NAME}.example.com/tls/server.crt"
  cp "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/${LOCAL_CONSENSUS_NAME}.example.com/tls/keystore/"* "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/${LOCAL_CONSENSUS_NAME}.example.com/tls/server.key"

  mkdir -p "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/${LOCAL_CONSENSUS_NAME}.example.com/msp/tlscacerts"
  cp "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/${LOCAL_CONSENSUS_NAME}.example.com/tls/tlscacerts/"* "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/${LOCAL_CONSENSUS_NAME}.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
}