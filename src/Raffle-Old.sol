// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import {VRFCoordinatorV2Interface} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2Plus} from "chainlink-brownie/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {Script,console} from "forge-std/Script.sol";
import {VRFV2PlusClient} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from 'chainlink-brownie-contracts/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol';
/**
 * @title A sample Raffle Contract
 * @author Habte Selassie Fitsum
 * @notice This contract is for creating a simple raffle.
 * @dev It Implements Chainlink VRFv2.5 and Chainlink automation.
 */


contract Raffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    /**
     * Errors
     */
    error Raffle_NotEnoughEthSent();
    error Raffle_TransferFailed();
    error Raffle_NotOpen();
    error Raffle_UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );


    /* Type Declarations */
    enum RaffleState {
        OPEN, // 0
        CALCULATING // 1
    }


   /* State Variables */
    address payable[] private s_players;
    // @dev the duration of the lottery in seconds
    uint256 private immutable i_interval;
    uint256 private immutable i_entranceFee;
    uint256 private s_lastTimeStamp;
    // Chainlink VRF related variables
     bytes32 private immutable i_keyHash;
     uint256  private immutable i_subId;
     uint16  private constant REQUEST_CONFIRMATOINS = 3;
     uint32  private immutable i_callbackGasLimit;
     uint32  private constant NUM_WORDS = 2;
     address private s_recentWinner;
     bytes extraArgs;

     RaffleState public s_raffleState;

     address immutable i_vrfCoordinator;

    /** Events */
    event EnteredRaffle(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestID);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 keyHash,
        uint256 subscriptionID,
       // uint16 requestConfirmations,
        uint32 callbackGasLimit
       // uint32 numWords
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = vrfCoordinator;
        i_keyHash = keyHash;
        i_subId = subscriptionID;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        // users should be able to enter the raffle by paying a ticker price;
        // require(msg.value >= i_entranceFee, "Not Enough ETH sent");
        if (msg.value < i_entranceFee) {
            revert Raffle_NotEnoughEthSent();
        }

        if(s_raffleState != RaffleState.OPEN) {
            revert Raffle_NotOpen();
        }
        s_players.push(payable(msg.sender));
        // 1. Makes migration easier
        // 2. Makes front end "indexing" easier
        emit EnteredRaffle(msg.sender);
        //require(msg.value >= i_entranceFee,"Raffle_NotEnoughEthSent");
    }

    // 1. Get a random number
    // 2. Use random number to pick a player
    // 3. be automatically called

    /// when should the winner be picked?

    /**
     * @dev This iss the function that the chainlink nodes will call to see
     * if the lottery is ready to have a winner pickked.
     * The following should be true in order for upkeepNeeded to be true.
     * 1. The time interval has passed between raffle runs.
     * 2. The Lottery is open
     * 3. The contract has ETH (has Players)
     * 4. Implicitly, Your Subscription has LINK
     * @param  - ignored
     * @return upkeepNeeded  - true if it's time to restart the lottery
     * @return - ignored
     */

    function checkUpkeep(bytes memory /* checkData */) 
    public 
    view 
     returns(bool upkeepNeeded, bytes memory /* performData */)
    {
       bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
       bool isOpen = s_raffleState == RaffleState.OPEN;
       bool hasBalance = address(this).balance > 0;
       bool hasPlayers = s_players.length > 0;


       console.log("Time Passed: ", timeHasPassed);
       console.log("Is Open: ", isOpen);
       console.log("Has Balance: ", hasBalance);
       console.log("Has Players: ", hasPlayers);


       upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
       //(bool upkeepNeeded, ) = raffle.checkUpkeep("");
        console.log("Upkeep Needed:", upkeepNeeded);

       return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        // at some point , we should be able to pick a winner out of the registered users.

        // checl to see if enough time has passed
        (bool upkeepNeeded, ) = checkUpkeep("");
         // require(upkeepNeeded, "Upkeep not needed");
        if(!upkeepNeeded) {
            revert Raffle_UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;

        // requet to RNG
      VRFV2PlusClient.RandomWordsRequest memory request =  VRFV2PlusClient.RandomWordsRequest(
        {
            keyHash : i_keyHash,
            subId : i_subId,
            requestConfirmations :  REQUEST_CONFIRMATOINS,
            callbackGasLimit : i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs : VRFV2PlusClient._argsToBytes(
                // set nativePayment to true to pay for VRF requests with Sepolia ETH instead of
               // LINK
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
      });


      uint256 requestID = s_vrfCoordinator.requestRandomWords(request);

      emit RequestedRaffleWinner(requestID);
         
        // Will revert if subscription is not set and funded.
//        uint256 requestId = VRFCoordinatorV2Interface(i_vrfCoordinator).requestRandomWords(
//     i_keyHash,          // bytes32 keyHash
//     uint64(i_subId),            // uint256 subId
//     REQUEST_CONFIRMATOINS,  // uint16 requestConfirmations
//     i_callbackGasLimit, // uint32 callbackGasLimit
//     NUM_WORDS           // uint32 numWords
// );


        // callback to cordinator
    }

    /**
     * Gettter Functions
     */
    // but we need people to be able to see what they should pay as `entranceFee`.
    //To facilitate this we will create a getter function.

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns(RaffleState){
      return s_raffleState;
    }

    function getPlayer(uint256 index) public view returns(address){
        return s_players[index];
    }

    function getLastTimeStamp() external view returns(uint256) {
        return s_lastTimeStamp;
    }

    function getRecentWinner() external view returns(address) {
        return s_recentWinner;
    }

    function fulfillRandomWords( uint256 requestId, uint256[] calldata randomWords
      ) internal virtual override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
       
        s_raffleState = RaffleState.OPEN;

        s_players = new address payable[](0);

        s_lastTimeStamp = block.timestamp;

        (bool success, ) = recentWinner.call{value: address(this).balance}("");
       // require(true,"Transfer Failed");
        if(!success) {
            revert Raffle_TransferFailed();
        }
        emit WinnerPicked(s_recentWinner);
    }

  
}






// Layout of the contract file:
// version
// imports
// errors
// interfaces, libraries, contract

// Inside Contract:
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private

// view & pure functions

