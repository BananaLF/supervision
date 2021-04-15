package main

import (
	"testing"
	"encoding/json"

	"github.com/hyperledger/fabric-chaincode-go/shimtest"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"github.com/stretchr/testify/require"
)

var resourcesTest = []Evaluation{
	{"1", "www.example.com."},
	{"2", "org.example.com."},
	{"3", "org.example.com."},
	{"4", "org.example.com."},
	{"5", "org.example.com."},
	{"6", "org.example.com."},
	{"7", "org.example.com."},
	{"8", "org.example.com."},
}

func TestFunc_Init(t *testing.T) {
	contract := SmartContract{}
	chainCode, err := contractapi.NewChaincode(&contract)
	require.Nil(t, err)
	stub := shimtest.NewMockStub("contract", chainCode)

	response := stub.MockInit("1", [][]byte{[]byte("InitLedger")})
	require.Equal(t, int32(200), response.Status, response.String())
}

func TestFunc_AddEvaluation(t *testing.T) {
	contract := SmartContract{}
	chainCode, err := contractapi.NewChaincode(&contract)
	require.Nil(t, err)
	stub := shimtest.NewMockStub("contract", chainCode)

	response := stub.MockInit("1", [][]byte{[]byte("InitLedger")})
	require.Equal(t, int32(200), response.Status, response.String())

	response = stub.MockInvoke("1", [][]byte{[]byte("AddEvaluation"), []byte(resourcesTest[1].Key), []byte(resourcesTest[1].Data)})
	require.Equal(t, int32(200), response.Status, response.String())
}

func TestFunc_QueryEvaluation(t *testing.T) {
	contract := SmartContract{}
	chainCode, err := contractapi.NewChaincode(&contract)
	require.Nil(t, err)
	stub := shimtest.NewMockStub("contract", chainCode)

	response := stub.MockInit("1", [][]byte{[]byte("InitLedger")})
	require.Equal(t, int32(200), response.Status, response.String())

	for i := range resourcesTest {
		response = stub.MockInvoke("1", [][]byte{[]byte("AddEvaluation"), []byte(resourcesTest[i].Key), []byte(resourcesTest[i].Data)})
		require.Equal(t, int32(200), response.Status, response.String())
	}

	for i := range resourcesTest {
		response = stub.MockInvoke("1", [][]byte{[]byte("QueryEvaluation"), []byte(resourcesTest[i].Key)})
		require.Equal(t, int32(200), response.Status, response.String())
		buffer, err := json.Marshal(resourcesTest[i])
		require.Nil(t, err)
		require.Equal(t, buffer, response.Payload)
	}
}

func TestFunc_ModifyEvaluation(t *testing.T) {
	contract := SmartContract{}
	chainCode, err := contractapi.NewChaincode(&contract)
	require.Nil(t, err)
	stub := shimtest.NewMockStub("contract", chainCode)

	response := stub.MockInit("1", [][]byte{[]byte("InitLedger")})
	require.Equal(t, int32(200), response.Status, response.String())

	for i := range resourcesTest {
		response = stub.MockInvoke("1", [][]byte{[]byte("AddEvaluation"), []byte(resourcesTest[i].Key), []byte(resourcesTest[i].Data)})
		require.Equal(t, int32(200), response.Status, response.String())
	}

	newEvaluation := resourcesTest[2]
	newEvaluation.Data = "lifei.com"
	response = stub.MockInvoke("1", [][]byte{[]byte("ModifyEvaluation"), []byte(newEvaluation.Key), []byte(newEvaluation.Data)})
	require.Equal(t, int32(200), response.Status, response.String())

	response = stub.MockInvoke("1", [][]byte{[]byte("QueryEvaluation"), []byte(newEvaluation.Key)})
	require.Equal(t, int32(200), response.Status, response.String())
	buffer, err := json.Marshal(newEvaluation)
	require.Nil(t, err)
	require.Equal(t, buffer, response.Payload)
}

func TestFunc_RemoveEvaluation(t *testing.T) {
	contract := SmartContract{}
	chainCode, err := contractapi.NewChaincode(&contract)
	require.Nil(t, err)
	stub := shimtest.NewMockStub("contract", chainCode)

	response := stub.MockInit("1", [][]byte{[]byte("InitLedger")})
	require.Equal(t, int32(200), response.Status, response.String())

	for i := range resourcesTest {
		response = stub.MockInvoke("1", [][]byte{[]byte("AddEvaluation"), []byte(resourcesTest[i].Key), []byte(resourcesTest[i].Data)})
		require.Equal(t, int32(200), response.Status, response.String())
	}

	newEvaluation := resourcesTest[2]

	response = stub.MockInvoke("1", [][]byte{[]byte("RemoveEvaluation"), []byte(newEvaluation.Key)})
	require.Equal(t, int32(200), response.Status, response.String())

	response = stub.MockInvoke("1", [][]byte{[]byte("QueryEvaluation"), []byte(newEvaluation.Key)})
	require.Equal(t, int32(500), response.Status, response.String())
}

func TestFunc_RemoveEvaluations(t *testing.T) {
	contract := SmartContract{}
	chainCode, err := contractapi.NewChaincode(&contract)
	require.Nil(t, err)
	stub := shimtest.NewMockStub("contract", chainCode)

	response := stub.MockInit("1", [][]byte{[]byte("InitLedger")})
	require.Equal(t, int32(200), response.Status, response.String())

	for i := range resourcesTest {
		response = stub.MockInvoke("1", [][]byte{[]byte("AddEvaluation"), []byte(resourcesTest[i].Key), []byte(resourcesTest[i].Data)})
		require.Equal(t, int32(200), response.Status, response.String())
	}

	for i := range resourcesTest {
		response = stub.MockInvoke("1", [][]byte{[]byte("RemoveEvaluation"), []byte(resourcesTest[i].Key)})
		require.Equal(t, int32(200), response.Status, response.String())
	}
	for i := range resourcesTest {
		response = stub.MockInvoke("1", [][]byte{[]byte("QueryEvaluation"), []byte(resourcesTest[i].Key)})
		require.Equal(t, int32(500), response.Status, response.String())
	}
}

func TestFunc_QueryEvaluations(t *testing.T) {
	contract := SmartContract{}
	chainCode, err := contractapi.NewChaincode(&contract)
	require.Nil(t, err)
	stub := shimtest.NewMockStub("contract", chainCode)

	response := stub.MockInit("1", [][]byte{[]byte("InitLedger")})
	require.Equal(t, int32(200), response.Status, response.String())

	for i := range resourcesTest {
		response = stub.MockInvoke("1", [][]byte{[]byte("AddEvaluation"), []byte(resourcesTest[i].Key), []byte(resourcesTest[i].Data)})
		require.Equal(t, int32(200), response.Status, response.String())
	}

	keysSlice := make([]string, 0)
	for i := range resourcesTest {
		keysSlice = append(keysSlice, resourcesTest[i].Key)
	}
	keys, err := json.Marshal(keysSlice)
	require.Nil(t, err)

	response = stub.MockInvoke("1", [][]byte{[]byte("QueryEvaluations"), keys})
	require.Equal(t, int32(200), response.Status, response.String())

	expectBytes, err := json.Marshal(resourcesTest)
	require.Nil(t, err)
	require.Equal(t, expectBytes, response.Payload)
}
