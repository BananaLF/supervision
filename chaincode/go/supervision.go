/*
SPDX-License-Identifier: Apache-2.0
*/

package main

import (
	"encoding/json"
	"fmt"
	"github.com/hyperledger/fabric-chaincode-go/shim"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for managing a car
type SmartContract struct {
	contractapi.Contract
}

// Evaluation describes basic details of what makes up a car
type Evaluation struct {
	Key  string `json:"key"`
	Data string `json:"data"`
}

// InitLedger adds a base set of cars to the ledger
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	return nil
}

func (s *SmartContract) queryData(stub shim.ChaincodeStubInterface, key string) ([]byte, error) {
	bytes, err := stub.GetState(key)
	if err != nil {
		return nil, err
	}
	if bytes == nil {
		return nil, fmt.Errorf("key %s is not exist", key)
	}
	return bytes, nil
}

// AddEvaluation adds a new evaluation to the world state with given details
func (s *SmartContract) AddEvaluation(ctx contractapi.TransactionContextInterface, key string, data string) error {
	stub := ctx.GetStub()
	if _, err := s.queryData(stub, key); err == nil {
		return fmt.Errorf("Failed to add evaluation to world state. Because key:%s is exist.Error %s", key, err)
	}
	evaluation := Evaluation{
		Key:  key,
		Data: data,
	}

	bytes, err := json.Marshal(evaluation)
	if err != nil {
		return fmt.Errorf("Failed to add evaluation from world state. Because json marshal failed. ERROR:%s", err.Error())
	}
	stub.PutState(key, bytes)
	stub.SetEvent("AddEvaluation", bytes)
	return nil
}

// RemoveEvaluation remove a evaluation at the world state with given key
func (s *SmartContract) RemoveEvaluation(ctx contractapi.TransactionContextInterface, key string) error {
	stub := ctx.GetStub()
	if _, err := s.queryData(stub, key); err != nil {
		return fmt.Errorf("Failed to remove evaluation in world state. Because key:%s is not exist. ERROR:%s", key, err.Error())
	}
	stub.DelState(key)
	stub.SetEvent("RemoveEvaluation", []byte(key))
	return nil
}

// RemoveEvaluation remove a evaluation at the world state with given key
func (s *SmartContract) ModifyEvaluation(ctx contractapi.TransactionContextInterface, key string, data string) error {
	stub := ctx.GetStub()
	if _, err := s.queryData(stub, key); err != nil {
		return fmt.Errorf("Failed to modify evaluation from world state. Because key %s is not exist. ERROR:%s", key, err.Error())
	}

	evaluation := Evaluation{
		Key:  key,
		Data: data,
	}

	bytes, err := json.Marshal(evaluation)
	if err != nil {
		return fmt.Errorf("Failed to modify evaluation from world state. Because json marshal failed. ERROR:%s", err.Error())
	}
	stub.PutState(key, bytes)
	stub.SetEvent("ModifyEvaluation", bytes)
	return nil
}

// QueryCar returns the car stored in the world state with given id
func (s *SmartContract) QueryEvaluation(ctx contractapi.TransactionContextInterface, key string) (*Evaluation, error) {
	stub := ctx.GetStub()
	bytes, err := s.queryData(stub, key)
	if err != nil {
		return nil, fmt.Errorf("Failed to query evaluation from world state. ERROR %s", err.Error())
	}

	evaluation := new(Evaluation)
	err = json.Unmarshal(bytes, evaluation)
	if err != nil {
		return nil, fmt.Errorf("Failed to query evaluation from world state. Because json unmarshal failed. ERROR:%s", err.Error())
	}

	return evaluation, nil
}

// QueryAllCars returns all cars found in world state
func (s *SmartContract) QueryEvaluations(ctx contractapi.TransactionContextInterface, keys []string) ([]Evaluation, error) {
	results := []Evaluation{}
	stub := ctx.GetStub()
	for i := range keys {
		bytes, err := s.queryData(stub, keys[i])
		if err != nil {
			return nil, fmt.Errorf("Failed to query evaluations from world state. Key:%s. ERROR %s", keys[i], err.Error())
		}

		evaluation := new(Evaluation)
		err = json.Unmarshal(bytes, evaluation)
		if err != nil {
			return nil, fmt.Errorf("Failed to query evaluations from world state. Because json unmarshal failed. Key:%s. ERROR:%s", keys[i], err.Error())
		}

		results = append(results, *evaluation)
	}

	return results, nil
}

func (s *SmartContract) RemoveEvaluations(ctx contractapi.TransactionContextInterface, keys []string) error {
	stub := ctx.GetStub()
	for i := range keys {
		err := stub.DelState(keys[i])
		if err != nil {
			return fmt.Errorf("Remove Evalution failed. Key : %s. Error:%s", keys[i], err.Error())
		}
	}
	eventBytes, _ := json.Marshal(keys)
	stub.SetEvent("RemoveEvaluations", eventBytes)
	return nil
}

func (s *SmartContract) QueryHistoricalEvaluation(ctx contractapi.TransactionContextInterface, key string) ([]Evaluation, error) {
	stub := ctx.GetStub()

	iterator, err := stub.GetHistoryForKey(key)
	if err != nil {
		return nil, fmt.Errorf("Query Historical Evaluation failed. Key : %s. Error:%s", key, err.Error())
	}
	defer iterator.Close()

	results := []Evaluation{}

	for iterator.HasNext() {
		queryResponse, err := iterator.Next()
		if err != nil {
			return nil, err
		}

		evaluation := new(Evaluation)
		_ = json.Unmarshal(queryResponse.Value, evaluation)

		results = append(results, *evaluation)
	}
	return results, nil
}

func main() {

	chaincode, err := contractapi.NewChaincode(new(SmartContract))

	if err != nil {
		fmt.Printf("Error create Evaluation chaincode: %s", err.Error())
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting Evaluation chaincode: %s", err.Error())
	}
}
