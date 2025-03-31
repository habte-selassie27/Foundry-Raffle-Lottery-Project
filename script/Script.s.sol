// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription,FundSubscription,AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {

function run() external returns (Raffle,HelperConfig) {

     

   HelperConfig helperConfig = new HelperConfig();
   HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

   uint _entranceFee = config.entranceFee;
   uint interval = config.interval;
   address _vrfCoordinator = config.vrfCoordinator;
   bytes32 _keyHash = config.keyHash;
   uint256 _subscriptionID = config.subscriptionID;
   uint32 _callbackGasLimit = config.callbackGasLimit;
   address _LinkTokenAddr = config.link;


    if (_subscriptionID == 0) {
        CreateSubscription createSubscription = new CreateSubscription();
        createSubscription.createSubscription(_vrfCoordinator);

        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(_vrfCoordinator,_subscriptionID,_LinkTokenAddr);

    }
    

    vm.startBroadcast();
    Raffle raffle = new Raffle(
        _entranceFee,
        interval,
        _vrfCoordinator,
        _keyHash,
        _subscriptionID,
        _callbackGasLimit
        );
    vm.stopBroadcast();

    AddConsumer addConsumer = new AddConsumer();
    addConsumer.addConsumer(address(raffle),_vrfCoordinator,_subscriptionID);

    
    return (raffle,helperConfig);
 }

}