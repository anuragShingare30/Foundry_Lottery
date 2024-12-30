// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {Lottery} from "src/Lottery.sol";
import {HelperConfig,CodeConstants} from "script/HelperConfig.s.sol";
import {LotteryScript} from "script/Deploy.s.sol";
import {Vm} from "lib/forge-std/src/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";


/**
 * @title A integration test of lottery smart contract
 * @author anurag shingare
 * @notice Here, we are going to perform some integration test i.e testing interaction parts of smart contract
 * @dev We will work with Helperconfig and Deploy script contract to extract our main contract.
 */


contract IntegrationTest is Test{
    Lottery lottery;
    HelperConfig helperConfig;

    // errors

    // type declaration

    // MOCK CONTRACT VALUES
    uint96 public constant MOCK_BASEPRICE = 100000000000000000;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1000000000;
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 0.004 ether; // 4e15

    // state varaibles
    uint256 _entranceFee;
    uint256 _interval;
    address _VRFCoordinator;
    bytes32 _gasLane;
    uint256 _subscriptionId;
    uint256 constant public STARTING_USER_BALANCE = 10 ether;
    address constant public USER = address(1);

    // events
    // events
    event EnteredUser(address indexed userAddress);
    event SelectedWinner(
        address indexed userAddress,
        string userName,
        uint256 prizePool
    );
    event LotteryWinner(
        uint256 requestId,
        address indexed winnerAddress,
        uint256 indexOfWinner
    );
    event RequestedLotteryWinner(uint256 indexed requestId);


    // functions
    function setUp() external {
        LotteryScript lotteryScript = new LotteryScript();
        (lottery,helperConfig) = lotteryScript.setUp();
        HelperConfig.NetworkConfig config = helperConfig.getConfigByChainId(block.chainid);
        _entranceFee = config.entranceFee;
        _interval = config.interval;
        _VRFCoordinator = config.VRFCoordinator;
        _gasLane = config.gasLane;
        _subscriptionId = config.subscriptionId;

        // provide some eth to user for testing
        vm.deal(USER,STARTING_USER_BALANCE);
    }


    /**
        @dev Testing fulfillRandomWords() function
    */  
    modifier enterLottery(){
        vm.prank(USER);
        lottery.enterLottery{value:_entranceFee}();
        vm.warp((block.timestamp + _interval + 1));
        vm.roll(block.timestamp + 1);
        _;
    }

    function test_callFullFillRandomWordsAfterPerformUpKeep() public enterLottery{
        vm.expectRevert("invalid requestid");
        VRFCoordinatorV2_5Mock(_VRFCoordinator).fulfillRandomWords(0, address(lottery));

        vm.expectRevert("invalid request id");
        VRFCoordinatorV2_5Mock(_VRFCoordinator).fulfillRandomWords(1, address(lottery));

    }

    function test_FullFillRandomWords(uint256 requestId) public enterLottery{
        // vm.prank(USER);
        // lottery.enterLottery{value:_entranceFee}();
        // vm.warp((block.timestamp + _interval + 1));
        // vm.roll(block.timestamp + 1);
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(_VRFCoordinator).fulfillRandomWords(requestId, address(lottery));
    }


    function test_FullFillRandomWordsResetsArrayAndSendsMoney() public enterLottery {
        uint totalUsers = 4;
        uint startingIndex = 2;
        address expectedWinner = address(1);

        for (uint256 i = startingIndex; i <= totalUsers; i++) {
            address newUser = address(uint160(i));
            hoax(newUser,_entranceFee);
            lottery.enterLottery{value:_entranceFee}();
        }

        uint startingTimeStamp = lottery.getLastTimeStamp();
        uint winnerStartingBalance = expectedWinner.balance;

        // call for requestId
        vm.recordLogs();
        lottery.performUpkeep("");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        console.logBytes32(logs[1].topics[1]);
        bytes32 requestId = logs[1].topics[1];
        VRFCoordinatorV2_5Mock(_VRFCoordinator).fulfillRandomWords(uint256(requestId), address(lottery));


        address recentWinner = lottery.getRecentWinner();
        Lottery.LotteryStatus lotteryStatus = lottery.getLotteryStatus();
        uint winnerBalance = recentWinner.balance;
        uint endingTimeStamp = lottery.getLastTimeStamp();
        uint prizePool = _entranceFee * totalUsers;

        assert(recentWinner == expectedWinner);
        assert(endingTimeStamp > startingTimeStamp);
        assert((winnerBalance-winnerStartingBalance) == prizePool);
        assert(lotteryStatus == Lottery.LotteryStatus.Open);
    }
}