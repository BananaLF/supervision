#!/bin/bash
function createConsensus3() {
  export CA_ROOT_PATH=${PWD}/..
  export FABRIC_CA_CLIENT_HOME=${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com
  ###### Consensus3
  infoln "Registering consensus3"
  set -x
  fabric-ca-client register --caname ca-consensus --id.name consensus3 --id.secret consensus3pw --id.type consensus --tls.certfiles "${CA_ROOT_PATH}/organizations/fabric-ca/consensusOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the consensus3 msp"
  set -x
  fabric-ca-client enroll -u https://consensus3:consensus3pw@localhost:9054 --caname ca-consensus -M "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/consensus3.example.com/msp" --csr.hosts consensus3.example.com --csr.hosts localhost --tls.certfiles "${CA_ROOT_PATH}/organizations/fabric-ca/consensusOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/msp/config.yaml" "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/consensus3.example.com/msp/config.yaml"

  infoln "Generating the consensus3-tls certificates"
  set -x
  fabric-ca-client enroll -u https://consensus3:consensus3pw@localhost:9054 --caname ca-consensus -M "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/consensus3.example.com/tls" --enrollment.profile tls --csr.hosts consensus3.example.com --csr.hosts localhost --tls.certfiles "${CA_ROOT_PATH}/organizations/fabric-ca/consensusOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/consensus3.example.com/tls/tlscacerts/"* "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/consensus3.example.com/tls/ca.crt"
  cp "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/consensus3.example.com/tls/signcerts/"* "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/consensus3.example.com/tls/server.crt"
  cp "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/consensus3.example.com/tls/keystore/"* "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/consensus3.example.com/tls/server.key"

  mkdir -p "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/consensus3.example.com/msp/tlscacerts"
  cp "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/consensus3.example.com/tls/tlscacerts/"* "${CA_ROOT_PATH}/organizations/consensusOrganizations/example.com/consensuss/consensus3.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
}