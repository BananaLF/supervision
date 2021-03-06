#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

function createOrg3 {
	infoln "Enrolling the CA admin"
	mkdir -p ../organizations/commiterOrganizations/org3.example.com/

	export FABRIC_CA_CLIENT_HOME=${PWD}/../organizations/commiterOrganizations/org3.example.com/

  set -x
  mh-ca-client enroll -u https://admin:adminpw@localhost:11054 --caname ca-org3 --tls.certfiles "${PWD}/mh-ca/org3/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-org3.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-org3.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-org3.pem
    OrganizationalUnitIdentifier: admin
  ConsensusOUIdentifier:
    Certificate: cacerts/localhost-11054-ca-org3.pem
    OrganizationalUnitIdentifier: consensus' > "${PWD}/../organizations/commiterOrganizations/org3.example.com/msp/config.yaml"

	infoln "Registering commiter0"
  set -x
	mh-ca-client register --caname ca-org3 --id.name commiter0 --id.secret commiter0pw --id.type peer --tls.certfiles "${PWD}/mh-ca/org3/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering user"
  set -x
  mh-ca-client register --caname ca-org3 --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/mh-ca/org3/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the org admin"
  set -x
  mh-ca-client register --caname ca-org3 --id.name org3admin --id.secret org3adminpw --id.type admin --tls.certfiles "${PWD}/mh-ca/org3/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the commiter0 msp"
  set -x
	mh-ca-client enroll -u https://commiter0:commiter0pw@localhost:11054 --caname ca-org3 -M "${PWD}/../organizations/commiterOrganizations/org3.example.com/commiters/commiter0.org3.example.com/msp" --csr.hosts commiter0.org3.example.com --tls.certfiles "${PWD}/mh-ca/org3/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/../organizations/commiterOrganizations/org3.example.com/msp/config.yaml" "${PWD}/../organizations/commiterOrganizations/org3.example.com/commiters/commiter0.org3.example.com/msp/config.yaml"

  infoln "Generating the commiter0-tls certificates"
  set -x
  mh-ca-client enroll -u https://commiter0:commiter0pw@localhost:11054 --caname ca-org3 -M "${PWD}/../organizations/commiterOrganizations/org3.example.com/commiters/commiter0.org3.example.com/tls" --enrollment.profile tls --csr.hosts commiter0.org3.example.com --csr.hosts localhost --tls.certfiles "${PWD}/mh-ca/org3/tls-cert.pem"
  { set +x; } 2>/dev/null


  cp "${PWD}/../organizations/commiterOrganizations/org3.example.com/commiters/commiter0.org3.example.com/tls/tlscacerts/"* "${PWD}/../organizations/commiterOrganizations/org3.example.com/commiters/commiter0.org3.example.com/tls/ca.crt"
  cp "${PWD}/../organizations/commiterOrganizations/org3.example.com/commiters/commiter0.org3.example.com/tls/signcerts/"* "${PWD}/../organizations/commiterOrganizations/org3.example.com/commiters/commiter0.org3.example.com/tls/server.crt"
  cp "${PWD}/../organizations/commiterOrganizations/org3.example.com/commiters/commiter0.org3.example.com/tls/keystore/"* "${PWD}/../organizations/commiterOrganizations/org3.example.com/commiters/commiter0.org3.example.com/tls/server.key"

  mkdir "${PWD}/../organizations/commiterOrganizations/org3.example.com/msp/tlscacerts"
  cp "${PWD}/../organizations/commiterOrganizations/org3.example.com/commiters/commiter0.org3.example.com/tls/tlscacerts/"* "${PWD}/../organizations/commiterOrganizations/org3.example.com/msp/tlscacerts/ca.crt"

  mkdir "${PWD}/../organizations/commiterOrganizations/org3.example.com/tlsca"
  cp "${PWD}/../organizations/commiterOrganizations/org3.example.com/commiters/commiter0.org3.example.com/tls/tlscacerts/"* "${PWD}/../organizations/commiterOrganizations/org3.example.com/tlsca/tlsca.org3.example.com-cert.pem"

  mkdir "${PWD}/../organizations/commiterOrganizations/org3.example.com/ca"
  cp "${PWD}/../organizations/commiterOrganizations/org3.example.com/commiters/commiter0.org3.example.com/msp/cacerts/"* "${PWD}/../organizations/commiterOrganizations/org3.example.com/ca/ca.org3.example.com-cert.pem"

  infoln "Generating the user msp"
  set -x
	mh-ca-client enroll -u https://user1:user1pw@localhost:11054 --caname ca-org3 -M "${PWD}/../organizations/commiterOrganizations/org3.example.com/users/User1@org3.example.com/msp" --tls.certfiles "${PWD}/mh-ca/org3/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/../organizations/commiterOrganizations/org3.example.com/msp/config.yaml" "${PWD}/../organizations/commiterOrganizations/org3.example.com/users/User1@org3.example.com/msp/config.yaml"

  infoln "Generating the org admin msp"
  set -x
	mh-ca-client enroll -u https://org3admin:org3adminpw@localhost:11054 --caname ca-org3 -M "${PWD}/../organizations/commiterOrganizations/org3.example.com/users/Admin@org3.example.com/msp" --tls.certfiles "${PWD}/mh-ca/org3/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/../organizations/commiterOrganizations/org3.example.com/msp/config.yaml" "${PWD}/../organizations/commiterOrganizations/org3.example.com/users/Admin@org3.example.com/msp/config.yaml"
}
