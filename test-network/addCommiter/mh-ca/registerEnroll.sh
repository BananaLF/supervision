#!/bin/bash
function createCommiter() {
  LOCAL_COMMITER_NAME=$1
  export CA_ROOT_PATH=${PWD}/..
  export FABRIC_CA_CLIENT_HOME=${CA_ROOT_PATH}/organizations/commiterOrganizations/org1.example.com

  echo
  echo "Register ${LOCAL_COMMITER_NAME}"
  echo
  set -x
  mh-ca-client register --caname ca-org1 --id.name ${LOCAL_COMMITER_NAME} --id.secret ${LOCAL_COMMITER_NAME}pw --id.type peer --tls.certfiles ${CA_ROOT_PATH}/organizations/mh-ca/org1/tls-cert.pem
  set +x

  echo
  echo "## Generate the ${LOCAL_COMMITER_NAME} msp"
  echo
  set -x
  mh-ca-client enroll -u https://${LOCAL_COMMITER_NAME}:${LOCAL_COMMITER_NAME}pw@localhost:7054 --caname ca-org1 -M ${CA_ROOT_PATH}/organizations/commiterOrganizations/org1.example.com/commiters/${LOCAL_COMMITER_NAME}.org1.example.com/msp --csr.hosts ${LOCAL_COMMITER_NAME}.org1.example.com --tls.certfiles ${CA_ROOT_PATH}/organizations/mh-ca/org1/tls-cert.pem
  set +x

  cp ${CA_ROOT_PATH}/organizations/commiterOrganizations/org1.example.com/msp/config.yaml ${CA_ROOT_PATH}/organizations/commiterOrganizations/org1.example.com/commiters/${LOCAL_COMMITER_NAME}.org1.example.com/msp/config.yaml

  echo
  echo "## Generate the ${LOCAL_COMMITER_NAME}-tls certificates"
  echo
  set -x
  mh-ca-client enroll -u https://${LOCAL_COMMITER_NAME}:${LOCAL_COMMITER_NAME}pw@localhost:7054 --caname ca-org1 -M ${CA_ROOT_PATH}/organizations/commiterOrganizations/org1.example.com/commiters/${LOCAL_COMMITER_NAME}.org1.example.com/tls --enrollment.profile tls --csr.hosts ${LOCAL_COMMITER_NAME}.org1.example.com --csr.hosts localhost --tls.certfiles ${CA_ROOT_PATH}/organizations/mh-ca/org1/tls-cert.pem
  set +x

  cp ${CA_ROOT_PATH}/organizations/commiterOrganizations/org1.example.com/commiters/${LOCAL_COMMITER_NAME}.org1.example.com/tls/tlscacerts/* ${CA_ROOT_PATH}/organizations/commiterOrganizations/org1.example.com/commiters/${LOCAL_COMMITER_NAME}.org1.example.com/tls/ca.crt
  cp ${CA_ROOT_PATH}/organizations/commiterOrganizations/org1.example.com/commiters/${LOCAL_COMMITER_NAME}.org1.example.com/tls/signcerts/* ${CA_ROOT_PATH}/organizations/commiterOrganizations/org1.example.com/commiters/${LOCAL_COMMITER_NAME}.org1.example.com/tls/server.crt
  cp ${CA_ROOT_PATH}/organizations/commiterOrganizations/org1.example.com/commiters/${LOCAL_COMMITER_NAME}.org1.example.com/tls/keystore/* ${CA_ROOT_PATH}/organizations/commiterOrganizations/org1.example.com/commiters/${LOCAL_COMMITER_NAME}.org1.example.com/tls/server.key
}
