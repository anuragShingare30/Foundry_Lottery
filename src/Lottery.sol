// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.2.0/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts@1.2.0/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A lottery smart contract
 * @author anurag shingare
 * @notice A sample smart contract for lottery functionality on etheruem network
 * @dev Implements chainlink VRFv2.5 and chainlink automation
 */

abstract contract Lottery is VRFConsumerBaseV2Plus {
    // Errors
    error Lottery_NotEnoughETHSent();
    error Lottery_NoEnoughUser();
    error Lottery_NoEnoughTimeHasPassed();
    error Lottery_FailedToWithDrawPrizePool();
    error Lottery_LotteryIsClosed();

    // Type Declaration
    struct User {
        uint256 id;
        uint256 entryFee;
        address payable userAddress;
        string userName;
    }

    enum LotteryStatus {
        Open,
        Closed
    }

    // State Variable
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    uint256 private s_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;
    LotteryStatus private s_lotteryStatus;

    // Events
    event EnteredUser(address indexed userAddress, string userName);
    event SelectedWinner(
        address indexed userAddress,
        string userName,
        uint256 prizePool
    );
    event LotteryWinner(
        uint256 requestId,
        address winnerAddress,
        uint indexOfWinner
    );

    constructor(
        uint256 entranceFee,
        uint256 interval,
        bytes32 gasLane,
        uint subscriptionId
    ) VRFConsumerBaseV2Plus(0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        s_subscriptionId = subscriptionId;
        s_lotteryStatus = LotteryStatus.Open;
    }

    User[] private s_userArray;

    function enterLottery(string memory _userName) public payable {
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
            userAddress: payable(msg.sender),
            userName: _userName
        });
        s_userArray.push(newuser);

        emit EnteredUser(msg.sender, _userName);
    }

    // 1. Get a random number
    // 2. use random number to pick a player
    // 3. Use chainlink automation to automatically called

    function selectWinner() public payable returns (uint256) {
        // check for enough time is passed
        if ((block.timestamp - s_lastTimeStamp < i_interval)) {
            revert Lottery_NoEnoughTimeHasPassed();
        }

        // change the lottery status
        s_lotteryStatus = LotteryStatus.Closed;
        // This is a struct from VRF
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

        uint requestId = s_vrfCoordinator.requestRandomWords(request);
        return requestId;
    }

    // CEI: Checks(Conditionals), Effect(Internal Contract State), Interaction(External Contract Interaction) pattern
    function fulfillRandomWords(
        // Checks
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        // EFFECT
        uint index = (_randomWords[0] % s_userArray.length);
        // change the status to open to start new lottery
        s_lotteryStatus = LotteryStatus.Open;
        // resetting the s_userArray to zero
        s_userArray = new User[](0);
        s_lastTimeStamp = block.timestamp;
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
