#!/bin/bash

function createOrg1() {
  infoln "Enrolling the CA admin"
  mkdir -p organizations/commiterOrganizations/org1.example.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/commiterOrganizations/org1.example.com/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-org1 --tls.certfiles "${PWD}/organizations/fabric-ca/org1/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-org1.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-org1.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-org1.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-org1.pem
    OrganizationalUnitIdentifier: consensus' > "${PWD}/organizations/commiterOrganizations/org1.example.com/msp/config.yaml"

  infoln "Registering commiter0"
  set -x
  fabric-ca-client register --caname ca-org1 --id.name commiter0 --id.secret commiter0pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/org1/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering user"
  set -x
  fabric-ca-client register --caname ca-org1 --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/org1/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the org admin"
  set -x
  fabric-ca-client register --caname ca-org1 --id.name org1admin --id.secret org1adminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/org1/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the commiter0 msp"
  set -x
  fabric-ca-client enroll -u https://commiter0:commiter0pw@localhost:7054 --caname ca-org1 -M "${PWD}/organizations/commiterOrganizations/org1.example.com/commiters/commiter0.org1.example.com/msp" --csr.hosts commiter0.org1.example.com --tls.certfiles "${PWD}/organizations/fabric-ca/org1/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/commiterOrganizations/org1.example.com/msp/config.yaml" "${PWD}/organizations/commiterOrganizations/org1.example.com/commiters/commiter0.org1.example.com/msp/config.yaml"

  infoln "Generating the commiter0-tls certificates"
  set -x
  fabric-ca-client enroll -u https://commiter0:commiter0pw@localhost:7054 --caname ca-org1 -M "${PWD}/organizations/commiterOrganizations/org1.example.com/commiters/commiter0.org1.example.com/tls" --enrollment.profile tls --csr.hosts commiter0.org1.example.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/org1/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/commiterOrganizations/org1.example.com/commiters/commiter0.org1.example.com/tls/tlscacerts/"* "${PWD}/organizations/commiterOrganizations/org1.example.com/commiters/commiter0.org1.example.com/tls/ca.crt"
  cp "${PWD}/organizations/commiterOrganizations/org1.example.com/commiters/commiter0.org1.example.com/tls/signcerts/"* "${PWD}/organizations/commiterOrganizations/org1.example.com/commiters/commiter0.org1.example.com/tls/server.crt"
  cp "${PWD}/organizations/commiterOrganizations/org1.example.com/commiters/commiter0.org1.example.com/tls/keystore/"* "${PWD}/organizations/commiterOrganizations/org1.example.com/commiters/commiter0.org1.example.com/tls/server.key"

  mkdir -p "${PWD}/organizations/commiterOrganizations/org1.example.com/msp/tlscacerts"
  cp "${PWD}/organizations/commiterOrganizations/org1.example.com/commiters/commiter0.org1.example.com/tls/tlscacerts/"* "${PWD}/organizations/commiterOrganizations/org1.example.com/msp/tlscacerts/ca.crt"

  mkdir -p "${PWD}/organizations/commiterOrganizations/org1.example.com/tlsca"
  cp "${PWD}/organizations/commiterOrganizations/org1.example.com/commiters/commiter0.org1.example.com/tls/tlscacerts/"* "${PWD}/organizations/commiterOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem"

  mkdir -p "${PWD}/organizations/commiterOrganizations/org1.example.com/ca"
  cp "${PWD}/organizations/commiterOrganizations/org1.example.com/commiters/commiter0.org1.example.com/msp/cacerts/"* "${PWD}/organizations/commiterOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem"

  infoln "Generating the user msp"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 --caname ca-org1 -M "${PWD}/organizations/commiterOrganizations/org1.example.com/users/User1@org1.example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/org1/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/commiterOrganizations/org1.example.com/msp/config.yaml" "${PWD}/organizations/commiterOrganizations/org1.example.com/users/User1@org1.example.com/msp/config.yaml"

  infoln "Generating the org admin msp"
  set -x
  fabric-ca-client enroll -u https://org1admin:org1adminpw@localhost:7054 --caname ca-org1 -M "${PWD}/organizations/commiterOrganizations/org1.example.com/users/Admin@org1.example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/org1/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/commiterOrganizations/org1.example.com/msp/config.yaml" "${PWD}/organizations/commiterOrganizations/org1.example.com/users/Admin@org1.example.com/msp/config.yaml"
}

function createOrg2() {
  infoln "Enrolling the CA admin"
  mkdir -p organizations/commiterOrganizations/org2.example.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/commiterOrganizations/org2.example.com/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca-org2 --tls.certfiles "${PWD}/organizations/fabric-ca/org2/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-org2.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-org2.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-org2.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-org2.pem
    OrganizationalUnitIdentifier: consensus' > "${PWD}/organizations/commiterOrganizations/org2.example.com/msp/config.yaml"

  infoln "Registering commiter0"
  set -x
  fabric-ca-client register --caname ca-org2 --id.name commiter0 --id.secret commiter0pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/org2/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering user"
  set -x
  fabric-ca-client register --caname ca-org2 --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/org2/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the org admin"
  set -x
  fabric-ca-client register --caname ca-org2 --id.name org2admin --id.secret org2adminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/org2/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the commiter0 msp"
  set -x
  fabric-ca-client enroll -u https://commiter0:commiter0pw@localhost:8054 --caname ca-org2 -M "${PWD}/organizations/commiterOrganizations/org2.example.com/commiters/commiter0.org2.example.com/msp" --csr.hosts commiter0.org2.example.com --tls.certfiles "${PWD}/organizations/fabric-ca/org2/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/commiterOrganizations/org2.example.com/msp/config.yaml" "${PWD}/organizations/commiterOrganizations/org2.example.com/commiters/commiter0.org2.example.com/msp/config.yaml"

  infoln "Generating the commiter0-tls certificates"
  set -x
  fabric-ca-client enroll -u https://commiter0:commiter0pw@localhost:8054 --caname ca-org2 -M "${PWD}/organizations/commiterOrganizations/org2.example.com/commiters/commiter0.org2.example.com/tls" --enrollment.profile tls --csr.hosts commiter0.org2.example.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/org2/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/commiterOrganizations/org2.example.com/commiters/commiter0.org2.example.com/tls/tlscacerts/"* "${PWD}/organizations/commiterOrganizations/org2.example.com/commiters/commiter0.org2.example.com/tls/ca.crt"
  cp "${PWD}/organizations/commiterOrganizations/org2.example.com/commiters/commiter0.org2.example.com/tls/signcerts/"* "${PWD}/organizations/commiterOrganizations/org2.example.com/commiters/commiter0.org2.example.com/tls/server.crt"
  cp "${PWD}/organizations/commiterOrganizations/org2.example.com/commiters/commiter0.org2.example.com/tls/keystore/"* "${PWD}/organizations/commiterOrganizations/org2.example.com/commiters/commiter0.org2.example.com/tls/server.key"

  mkdir -p "${PWD}/organizations/commiterOrganizations/org2.example.com/msp/tlscacerts"
  cp "${PWD}/organizations/commiterOrganizations/org2.example.com/commiters/commiter0.org2.example.com/tls/tlscacerts/"* "${PWD}/organizations/commiterOrganizations/org2.example.com/msp/tlscacerts/ca.crt"

  mkdir -p "${PWD}/organizations/commiterOrganizations/org2.example.com/tlsca"
  cp "${PWD}/organizations/commiterOrganizations/org2.example.com/commiters/commiter0.org2.example.com/tls/tlscacerts/"* "${PWD}/organizations/commiterOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem"

  mkdir -p "${PWD}/organizations/commiterOrganizations/org2.example.com/ca"
  cp "${PWD}/organizations/commiterOrganizations/org2.example.com/commiters/commiter0.org2.example.com/msp/cacerts/"* "${PWD}/organizations/commiterOrganizations/org2.example.com/ca/ca.org2.example.com-cert.pem"

  infoln "Generating the user msp"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:8054 --caname ca-org2 -M "${PWD}/organizations/commiterOrganizations/org2.example.com/users/User1@org2.example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/org2/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/commiterOrganizations/org2.example.com/msp/config.yaml" "${PWD}/organizations/commiterOrganizations/org2.example.com/users/User1@org2.example.com/msp/config.yaml"

  infoln "Generating the org admin msp"
  set -x
  fabric-ca-client enroll -u https://org2admin:org2adminpw@localhost:8054 --caname ca-org2 -M "${PWD}/organizations/commiterOrganizations/org2.example.com/users/Admin@org2.example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/org2/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/commiterOrganizations/org2.example.com/msp/config.yaml" "${PWD}/organizations/commiterOrganizations/org2.example.com/users/Admin@org2.example.com/msp/config.yaml"
}

function createConsensus() {
  infoln "Enrolling the CA admin"
  mkdir -p organizations/consensusOrganizations/example.com

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/consensusOrganizations/example.com

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca-consensus --tls.certfiles "${PWD}/organizations/fabric-ca/consensusOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-consensus.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-consensus.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-consensus.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-consensus.pem
    OrganizationalUnitIdentifier: consensus' > "${PWD}/organizations/consensusOrganizations/example.com/msp/config.yaml"

  infoln "Registering consensus"
  set -x
  fabric-ca-client register --caname ca-consensus --id.name consensus --id.secret consensuspw --id.type consensus --tls.certfiles "${PWD}/organizations/fabric-ca/consensusOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the consensus admin"
  set -x
  fabric-ca-client register --caname ca-consensus --id.name consensusAdmin --id.secret consensusAdminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/consensusOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the consensus msp"
  set -x
  fabric-ca-client enroll -u https://consensus:consensuspw@localhost:9054 --caname ca-consensus -M "${PWD}/organizations/consensusOrganizations/example.com/consensuss/consensus.example.com/msp" --csr.hosts consensus.example.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/consensusOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/consensusOrganizations/example.com/msp/config.yaml" "${PWD}/organizations/consensusOrganizations/example.com/consensuss/consensus.example.com/msp/config.yaml"

  infoln "Generating the consensus-tls certificates"
  set -x
  fabric-ca-client enroll -u https://consensus:consensuspw@localhost:9054 --caname ca-consensus -M "${PWD}/organizations/consensusOrganizations/example.com/consensuss/consensus.example.com/tls" --enrollment.profile tls --csr.hosts consensus.example.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/consensusOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/consensusOrganizations/example.com/consensuss/consensus.example.com/tls/tlscacerts/"* "${PWD}/organizations/consensusOrganizations/example.com/consensuss/consensus.example.com/tls/ca.crt"
  cp "${PWD}/organizations/consensusOrganizations/example.com/consensuss/consensus.example.com/tls/signcerts/"* "${PWD}/organizations/consensusOrganizations/example.com/consensuss/consensus.example.com/tls/server.crt"
  cp "${PWD}/organizations/consensusOrganizations/example.com/consensuss/consensus.example.com/tls/keystore/"* "${PWD}/organizations/consensusOrganizations/example.com/consensuss/consensus.example.com/tls/server.key"

  mkdir -p "${PWD}/organizations/consensusOrganizations/example.com/consensuss/consensus.example.com/msp/tlscacerts"
  cp "${PWD}/organizations/consensusOrganizations/example.com/consensuss/consensus.example.com/tls/tlscacerts/"* "${PWD}/organizations/consensusOrganizations/example.com/consensuss/consensus.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

  mkdir -p "${PWD}/organizations/consensusOrganizations/example.com/msp/tlscacerts"
  cp "${PWD}/organizations/consensusOrganizations/example.com/consensuss/consensus.example.com/tls/tlscacerts/"* "${PWD}/organizations/consensusOrganizations/example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

  infoln "Generating the admin msp"
  set -x
  fabric-ca-client enroll -u https://consensusAdmin:consensusAdminpw@localhost:9054 --caname ca-consensus -M "${PWD}/organizations/consensusOrganizations/example.com/users/Admin@example.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/consensusOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/consensusOrganizations/example.com/msp/config.yaml" "${PWD}/organizations/consensusOrganizations/example.com/users/Admin@example.com/msp/config.yaml"

}
