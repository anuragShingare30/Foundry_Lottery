// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.2.0/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts@1.2.0/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts@1.2.0/src/v0.8/automation/AutomationCompatible.sol";

/**
 * @title A lottery smart contract
 * @author anurag shingare
 * @notice A sample smart contract for lottery functionality on etheruem network
 * @dev Implements chainlink VRFv2.5 and chainlink automation
 */

abstract contract Lottery is
    VRFConsumerBaseV2Plus,
    AutomationCompatibleInterface
{
    // Errors
    error Lottery_NotEnoughETHSent();
    error Lottery_NoEnoughUser();
    error Lottery_NoEnoughTimeHasPassed();
    error Lottery_FailedToWithDrawPrizePool();
    error Lottery_LotteryIsClosed();
    error Lottery_ConditionNotMetToSelectWinner();

    // Type Declaration
    struct User {
        uint256 id;
        uint256 entryFee;
        address payable userAddress;
    }

    enum LotteryStatus {
        Open,
        Closed
    }

    // State Variable
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_timeInterval;
    uint256 private s_lastTimeStamp;
    uint256 private s_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint32 private callbackGasLimit = 100000;
    uint16 private requestConfirmations = 3;
    uint32 private numWords = 1;
    address public s_recentWinner;
    uint256 public s_recentWinnerPrizePool;
    LotteryStatus public s_lotteryStatus;

    // Events
    event EnteredUser(address indexed userAddress);
    event SelectedWinner(
        address indexed userAddress,
        string userName,
        uint256 prizePool
    );
    event LotteryWinner(
        uint256 requestId,
        address winnerAddress,
        uint256 indexOfWinner
    );

    constructor(
        uint256 entranceFee,
        uint256 interval,
        bytes32 gasLane,
        uint256 subscriptionId
    ) VRFConsumerBaseV2Plus(0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B) {
        i_entranceFee = entranceFee;
        i_timeInterval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        s_subscriptionId = subscriptionId;
        s_lotteryStatus = LotteryStatus.Open;
    }

    User[] private s_userArray;

    /**
     * Check the status and eligibility for user to enter lottery
     */
    function enterLottery() public payable {
        // check the status of lottery
        if (s_lotteryStatus != LotteryStatus.Open) {
            revert Lottery_LotteryIsClosed();
        }
        // gas efficient than require()
        if (msg.value < i_entranceFee) {
            revert Lottery_NotEnoughETHSent();
        }
        if (s_userArray.length >= 5) {
            revert Lottery_NoEnoughUser();
        }
        User memory newuser = User({
            id: s_userArray.length,
            entryFee: msg.value,
            userAddress: payable(msg.sender)
        });
        s_userArray.push(newuser);

        emit EnteredUser(msg.sender);
    }


    /**
     * @dev ChainLink automation v2.0
     * checkUpkeep function that contains the logic that will be executed offchain to see if performUpkeep should be executed.
     * checkUpkeep returns two params upkeepNeeded and performData.
     * performUpkeep function that will be executed onchain when checkUpkeep returns true.

     * The following should be true in order doe upkeepNeeded to be true:
     * 1. timeHasPassed
     * 2. lottery is open
     * 3. contract has balance and players
     */
    function checkUpkeep() public view returns (bool upkeepNeeded) {
        upkeepNeeded =
            ((block.timestamp - s_lastTimeStamp) > i_timeInterval) &&
            (s_lotteryStatus == LotteryStatus.Open) &&
            (address(this).balance > 0) &&
            (s_userArray.length > 0);
        return upkeepNeeded;
    }

    /**
     * @dev Chainlink VRFv2.5
     * Get a random number using chainlink VRF
     * use random number to pick a player
     * This function is named selectWinner to performUpkeep
     * Use chainlink automation to automatically called
     */
    function performUpkeep() external  payable returns (uint256) {
        
        // check the condition for function to be called automatically
        (bool upkeepNeeded) = checkUpkeep();
        if(!upkeepNeeded){
            revert Lottery_ConditionNotMetToSelectWinner();
        }
        // change the lottery status
        s_lotteryStatus = LotteryStatus.Closed;
        // This is a struct from VRF to call the requestId for RNG
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        return requestId;
    }

    /**
     * CEI pattern
     * Checks(Conditionals)
     * Effect(Internal Contract State)
     * Interaction(External Contract Interaction)
     */
    function fulfillRandomWords(
        // Checks
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        // EFFECT
        uint256 index = (_randomWords[0] % s_userArray.length);
        // change the status to open to start new lottery
        s_lotteryStatus = LotteryStatus.Open;
        // resetting the s_userArray to zero
        s_userArray = new User[](0);
        s_lastTimeStamp = block.timestamp;
        s_recentWinner = s_userArray[index].userAddress;
        s_recentWinnerPrizePool = (address(this).balance);
        emit LotteryWinner(_requestId, s_userArray[index].userAddress, index);

        // INTERACTION (EXTERNAL CONTRACT INTERACTION)
        (bool success, ) = s_userArray[index].userAddress.call{
            value: address(this).balance
        }("");
        if (!success) {
            revert Lottery_FailedToWithDrawPrizePool();
        }
    }

    

    function getEntryFeeAmount() public view returns (uint256) {
        return i_entranceFee;
    }
}
