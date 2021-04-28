/*
Copyright 2020 IBM All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
*/

package main

import (
	"errors"
	"fmt"
	"github.com/hyperledger/fabric-sdk-go/pkg/common/providers/fab"
	"github.com/hyperledger/fabric-sdk-go/pkg/core/config"
	"github.com/hyperledger/fabric-sdk-go/pkg/gateway"
	"io/ioutil"
	"os"
	"path/filepath"
)

func main() {
	os.Setenv("DISCOVERY_AS_LOCALHOST", "true") // if you connect to server you must be set false. if you connect to localhost you must be set true
	wallet, err := gateway.NewFileSystemWallet("wallet")
	if err != nil {
		fmt.Printf("Failed to create wallet: %s\n", err)
		os.Exit(1)
	}

	if !wallet.Exists("appUser") {
		err = populateWallet(wallet)
		if err != nil {
			fmt.Printf("Failed to populate wallet contents: %s\n", err)
			os.Exit(1)
		}
	}

	ccpPath := filepath.Join(
		"..",
		"..",
		"test-network",
		"organizations",
		"commiterOrganizations",
		"org1.example.com",
		"connection-org1.yaml",
	)

	gw, err := gateway.Connect(
		gateway.WithConfig(config.FromFile(filepath.Clean(ccpPath))),
		gateway.WithIdentity(wallet, "appUser"),
	)
	if err != nil {
		fmt.Printf("Failed to connect to gateway: %s\n", err)
		os.Exit(1)
	}
	defer gw.Close()

	network, err := gw.GetNetwork("mychannel")
	if err != nil {
		fmt.Printf("Failed to get network: %s\n", err)
		os.Exit(1)
	}

	contract := network.GetContract("supervision")

	eventID := ".*"
	end := make(chan bool)
	reg, notifier, err := contract.RegisterEvent(eventID)
	if err != nil {
		fmt.Printf("Failed to register contract event: %s", err)
		return
	}
	defer contract.Unregister(reg)

	go func(notifier <-chan *fab.CCEvent) {
		for i := 0; i >= 0; i++ {
			var ccEvent *fab.CCEvent
			select {
			case ccEvent = <-notifier:
				fmt.Printf("       Event:	%s\n", ccEvent.EventName)
				fmt.Printf("Chaincode ID:   %s\n", ccEvent.ChaincodeID)
				fmt.Printf("Block Number:	%d\n", ccEvent.BlockNumber)
				fmt.Printf(" Transaction:	%s\n", ccEvent.TxID)
				fmt.Printf("  Source URL:	%s\n", ccEvent.SourceURL)
				fmt.Printf("     Payload:	%s\n", string(ccEvent.Payload))
				fmt.Printf("\n\n")
				if ccEvent.EventName == "RemoveEvaluation" {
					end <- true
					break
				}
			}
		}
	}(notifier)

	var resourcesTest = []struct {
		Key  string `json:"key"`
		Data string `json:"data"`
	}{
		{"1", "org.example.com.1"},
		{"1", "org.example.com.2"},
		{"1", "org.example.com.3"},
		{"1", "org.example.com.4"},
		{"1", "org.example.com.5"},
		{"1", "org.example.com.6"},
		{"1", "org.example.com.7"},
	}

	_, err = contract.SubmitTransaction("AddEvaluation", "1", "org.example.com.0")
	if err != nil {
		fmt.Printf("Failed to submit transaction: %s\n", err)
		os.Exit(1)
	}
	//fmt.Println("Time:", time.Now().Format("2006-01-02 15:04:05"), "AddEvaluation success")

	_, err = contract.SubmitTransaction("AddEvaluation", "2", "lifei.example.com.0")
	if err != nil {
		fmt.Printf("Failed to submit transaction: %s\n", err)
		os.Exit(1)
	}
	for i := range resourcesTest {
		_, err := contract.SubmitTransaction("ModifyEvaluation", resourcesTest[i].Key, resourcesTest[i].Data)
		if err != nil {
			fmt.Printf("Failed to submit transaction: %s\n", err)
			os.Exit(1)
		}
		//fmt.Println("Time:", time.Now().Format("2006-01-02 15:04:05"), "AddEvaluation success")
	}

	//fmt.Println("Time:", time.Now().Format("2006-01-02 15:04:05"), "AddEvaluation success")
	_, err = contract.SubmitTransaction("RemoveEvaluation", "2")
	if err != nil {
		fmt.Printf("Failed to submit transaction: %s\n", err)
		os.Exit(1)
	}
	result, err := contract.EvaluateTransaction("QueryEvaluation", "1")
	if err != nil {
		fmt.Printf("Failed to submit transaction: %s\n", err)
		os.Exit(1)
	}
	fmt.Println(string(result))

	_, err = contract.EvaluateTransaction("QueryEvaluation", "2")
	if err == nil {
		fmt.Printf("Failed to QueryEvaluation\n")
		os.Exit(1)
	}

	result, err = contract.EvaluateTransaction("QueryHistoricalEvaluation", "1")
	if err != nil {
		fmt.Printf("Failed to submit transaction: %s\n", err)
		os.Exit(1)
	}
	fmt.Println(string(result))

	<-end
}

func populateWallet(wallet *gateway.Wallet) error {
	credPath := filepath.Join(
		"..",
		"..",
		"test-network",
		"organizations",
		"commiterOrganizations",
		"org1.example.com",
		"users",
		"User1@org1.example.com",
		"msp",
	)
	fmt.Println(credPath)
	certPath := filepath.Join(credPath, "signcerts", "cert.pem")
	// read the certificate pem
	cert, err := ioutil.ReadFile(filepath.Clean(certPath))
	if err != nil {
		return err
	}

	keyDir := filepath.Join(credPath, "keystore")
	// there's a single file in this dir containing the private key
	files, err := ioutil.ReadDir(keyDir)
	if err != nil {
		return err
	}
	if len(files) != 1 {
		return errors.New("keystore folder should have contain one file")
	}
	keyPath := filepath.Join(keyDir, files[0].Name())
	key, err := ioutil.ReadFile(filepath.Clean(keyPath))
	if err != nil {
		return err
	}

	identity := gateway.NewX509Identity("Org1MSP", string(cert), string(key))

	err = wallet.Put("appUser", identity)
	if err != nil {
		return err
	}
	return nil
}
