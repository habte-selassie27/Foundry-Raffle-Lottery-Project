// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {SubscriptionAPI} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/SubscriptionAPI.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function CreateSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        (uint256 subID, ) = createSubscription(vrfCoordinator);

        console.log(" Created Subscription ID:", subID);
        console.log(" VRF Coordinator Address:", vrfCoordinator);
        console.log(" Please update the subscription ID in HelperConfig.s.sol!");

        return (subID, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns (uint256, address) {
        console.log(" Creating subscription on chain ID:", block.chainid);
        console.log(" VRF Coordinator Address:", vrfCoordinator);

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock coordinator = VRFCoordinatorV2_5Mock(vrfCoordinator);
        uint256 subID = coordinator.createSubscription();
        vm.stopBroadcast();

        console.log(" Subscription Created with ID:", subID);
        return (subID, vrfCoordinator);
    }

    function run() public {
        CreateSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint256 public constant FUND_AMOUNT = 3 ether; // 3 LINK

    function fundSubscriptionUsingConfig(uint256 subscriptionID) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionID = helperConfig.getConfig().subscriptionID;
        address linkToken = helperConfig.getConfig().link;

        require(subscriptionID > 0, " Invalid Subscription ID!");

        fundSubscription(vrfCoordinator, subscriptionID, linkToken);
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionID, address linkToken) public {
        console.log(" Funding Subscription ID:", subscriptionID);
        console.log(" Using VRF Coordinator:", vrfCoordinator);
        console.log(" On Chain ID:", block.chainid);

        require(subscriptionID > 0, " Subscription ID is invalid!");

        vm.startBroadcast();
        if (block.chainid == 31337) { // Local testnet
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionID, FUND_AMOUNT*100);
        } else {
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionID));
        }
        vm.stopBroadcast();

        console.log(" Subscription funded successfully!");
    }

    function run() public {
        fundSubscriptionUsingConfig(1);
    }
}

contract AddConsumer is Script {
    function addConsumer(address raffle, address vrfCoordinator, uint256 subscriptionID) public {
        console.log(" Adding Consumer Contract:", raffle);
        console.log(" VRF Coordinator:", vrfCoordinator);
        console.log(" On Chain ID:", block.chainid);

        require(subscriptionID > 0, " Invalid Subscription ID!");

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock coordinator = VRFCoordinatorV2_5Mock(vrfCoordinator);
        coordinator.addConsumer(subscriptionID, raffle);
        vm.stopBroadcast();

        console.log(" Consumer added successfully!");
    }

    function addConsumerUsingConfig(address raffle,uint256 subscriptionID) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionID = helperConfig.getConfig().subscriptionID;

        addConsumer(raffle, vrfCoordinator, subscriptionID);
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment("MyContract", block.chainid);
        addConsumerUsingConfig(raffle,1);
    }
}










// pragma solidity 0.8.19;


// import {Script,console} from "forge-std/Script.sol";
// import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
// import {VRFCoordinatorV2_5Mock} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
// import {SubscriptionAPI} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/SubscriptionAPI.sol";
// import {LinkToken} from "../test/mocks/LinkToken.sol";
// import {CodeConstants} from "./HelperConfig.s.sol";
// import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";



// contract CreateSubscription is Script {

//     function CreateSubscriptionUsingConfig() public returns(uint256, address) {
//         HelperConfig helperConfig = new HelperConfig();
//         address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
//         (uint256 subID, ) = createSubscription(vrfCoordinator);

//         // create subscription ... 
//          return (subID, vrfCoordinator);

//     }

//     function createSubscription(address vrfCoordinator) public returns(uint256, address) {
//       console.log("Creating subscription on chain id ",block.chainid);
//       console.log("VRF Coordinator in getConfig:", address(vrfCoordinator));

//       vm.startBroadcast();
//       uint256 subID = SubscriptionAPI(vrfCoordinator).createSubscription();
//       vm.stopBroadcast();
//       console.log("Your Subscription Id is:", subID);
//       console.log("Please update the subscription Id in your HelperConfig.s.sol");
//       return (subID, vrfCoordinator);


//     }

//     function run() public {
//       CreateSubscriptionUsingConfig();
//     }

// }

// contract FundSubscription is Script, CodeConstants {

//   uint256 public constant FUND_AMOUNT = 3 ether; // 3 LINK

//   function fundSubscriptionUsingConfig() public {
//     HelperConfig helperConfig = new HelperConfig();
//      address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
//      uint256 subscrptionID = helperConfig.getConfig().subscriptionID;
//      address linkToken = helperConfig.getConfig().link;

//      fundSubscription(vrfCoordinator,subscrptionID,linkToken);     
//   }
   
//    function fundSubscription(address vrfCoordinator, uint256 subscriptionID, address linkToken) public {
//      console.log("Funding subscription:", subscriptionID);
//      console.log("Using vrfCoordinator:", vrfCoordinator);
//      console.log("On ChainId:",block.chainid);

//       if(block.chainid == LOCAL_CHAIN_ID) {
//         vm.startBroadcast();
//          VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionID,
//          FUND_AMOUNT);
//         vm.stopBroadcast();
//       } else {
//         vm.startBroadcast();
//          LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT,abi.encode(subscriptionID));

//         vm.stopBroadcast();
//       }
//    }
   
//   function run() public {
//     fundSubscriptionUsingConfig();
//   }
// }


// contract AddConsumer is Script {

//   function addConsumer(address raffle, address vrfCoordinator, uint256 subscriptionID) public {
//     console.log("Adding consumer contract:", raffle);
//     console.log("Using VRFCoordinator:",vrfCoordinator);
//     console.log("On chain id:", block.chainid);

//     vm.startBroadcast();
//     VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subscriptionID, raffle);
//     vm.stopBroadcast();
//   }

//   /*
//         uint256 entranceFee;
//         uint256 interval;
//         address vrfCoordinator;
//         bytes32 keyHash;
//         uint256 subscriptionID;
//         uint32 callbackGasLimit;
//         address link;
//   */

//   function addConsumerUsingConfig(address raffle) public {
//     HelperConfig helperConfig = new HelperConfig();

//     HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

//     address vrfCoordinator = config.vrfCoordinator;

//     uint256 subscriptionID = config.subscriptionID;

//     // (
//     //   ,

//     //   ,

//     //   address vrfCoordinator
//     //   ,

//     //   uint256 subscriptionID

//     //   ,
//     //   ,
//     // ) = helperConfig.getConfig();

//     addConsumer(raffle, vrfCoordinator, subscriptionID);

//   }

//   function run() external {
//     address raffle = DevOpsTools.get_most_recent_deployment("MyContract", block.chainid);
//     addConsumerUsingConfig(raffle);

//   }
// }  