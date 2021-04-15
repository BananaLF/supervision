#!/bin/bash
function createCommiter() {
  export CA_ROOT_PATH=${PWD}/..
  export FABRIC_CA_CLIENT_HOME=${CA_ROOT_PATH}/organizations/commiterOrganizations/org1.example.com

  echo
  echo "Register commiter1"
  echo
  set -x
  fabric-ca-client register --caname ca-org1 --id.name commiter1 --id.secret commiter1pw --id.type peer --tls.certfiles ${CA_ROOT_PATH}/organizations/fabric-ca/org1/tls-cert.pem
  set +x

  echo
  echo "## Generate the commiter1 msp"
  echo
  set -x
  fabric-ca-client enroll -u https://commiter1:commiter1pw@localhost:7054 --caname ca-org1 -M ${CA_ROOT_PATH}/organizations/commiterOrganizations/org1.example.com/commiters/commiter1.org1.example.com/msp --csr.hosts commiter1.org1.example.com --tls.certfiles ${CA_ROOT_PATH}/organizations/fabric-ca/org1/tls-cert.pem
  set +x

  cp ${CA_ROOT_PATH}/organizations/commiterOrganizations/org1.example.com/msp/config.yaml ${CA_ROOT_PATH}/organizations/commiterOrganizations/org1.example.com/commiters/commiter1.org1.example.com/msp/config.yaml

  echo
  echo "## Generate the commiter1-tls certificates"
  echo
  set -x
  fabric-ca-client enroll -u https://commiter1:commiter1pw@localhost:7054 --caname ca-org1 -M ${CA_ROOT_PATH}/organizations/commiterOrganizations/org1.example.com/commiters/commiter1.org1.example.com/tls --enrollment.profile tls --csr.hosts commiter1.org1.example.com --csr.hosts localhost --tls.certfiles ${CA_ROOT_PATH}/organizations/fabric-ca/org1/tls-cert.pem
  set +x

  cp ${CA_ROOT_PATH}/organizations/commiterOrganizations/org1.example.com/commiters/commiter1.org1.example.com/tls/tlscacerts/* ${CA_ROOT_PATH}/organizations/commiterOrganizations/org1.example.com/commiters/commiter1.org1.example.com/tls/ca.crt
  cp ${CA_ROOT_PATH}/organizations/commiterOrganizations/org1.example.com/commiters/commiter1.org1.example.com/tls/signcerts/* ${CA_ROOT_PATH}/organizations/commiterOrganizations/org1.example.com/commiters/commiter1.org1.example.com/tls/server.crt
  cp ${CA_ROOT_PATH}/organizations/commiterOrganizations/org1.example.com/commiters/commiter1.org1.example.com/tls/keystore/* ${CA_ROOT_PATH}/organizations/commiterOrganizations/org1.example.com/commiters/commiter1.org1.example.com/tls/server.key
}
