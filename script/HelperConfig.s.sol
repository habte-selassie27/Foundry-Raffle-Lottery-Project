// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;



import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
// import {CodeConstants} from "./CodeConstants.sol"; // ✅ Import the new file

abstract contract CodeConstants {
    /* VRF Mock Values*/
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;
    uint256 public constant ETH_SEPOLIA_CHAINID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}


contract HelperConfig is Script, CodeConstants {
   error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 keyHash;
        uint256 subscriptionID;
        uint32 callbackGasLimit;
        address link;
    }

    NetworkConfig public localNetworkConfig;
    mapping (uint256 => NetworkConfig) networkConfigs;

    // constructor(){
    //     if(block.chainid == 11155111){
    //         localNetworkConfig = getSepoliaEthConfig();
    //     } else {
    //         localNetworkConfig = getOrCreateAnvilEthConfig();
    //     }
      
    // }

    constructor(){
    if(block.chainid == 11155111){
        networkConfigs[11155111] = getSepoliaEthConfig();  // Store the config in the mapping
    } else {
        networkConfigs[LOCAL_CHAIN_ID] = getOrCreateAnvilEthConfig();  // Store the config for local network
    }
}


    function getConfigByChainId(uint256 chainId) public returns(NetworkConfig memory){
        if(networkConfigs[chainId].vrfCoordinator != address(0)){
            return networkConfigs[chainId];
        } else if(chainId == LOCAL_CHAIN_ID) {
           return getOrCreateAnvilEthConfig();
        } else {
           revert HelperConfig__InvalidChainId();
        }
     }

     function getConfig() public returns(NetworkConfig memory){
        return getConfigByChainId(block.chainid);
     }

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory){
      return NetworkConfig({
        entranceFee: 0.01 ether, // 1e16
        interval: 30, // 30 seconds
        vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
        keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
        callbackGasLimit: 2500000, // 500,000 gas
        subscriptionID: 0,
        link: 0x779877A7B0D9E8603169DdbD7836e478b4624789  
      });
    }

     function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory){
        // check to see if we set an active network config
        if(localNetworkConfig.vrfCoordinator != address(0)){
           return localNetworkConfig; 
        }

        // Deploy mocks and such
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,MOCK_GAS_PRICE_LINK,MOCK_WEI_PER_UNIT_LINK
        );

        LinkToken linkToken = new LinkToken();

        vm.stopBroadcast();

    localNetworkConfig = NetworkConfig({
        entranceFee: 0.01 ether, // 1e16
        interval: 30, // 30 seconds
        vrfCoordinator: address(vrfCoordinatorMock),
        keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
        callbackGasLimit: 500000, // 500,000 gas
        subscriptionID: 35950055785450893458896322881103460417870040245710164241423219158007605471698,
        link: address(linkToken)  
    });

     return localNetworkConfig;
  }

}