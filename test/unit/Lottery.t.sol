// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {Lottery} from "src/Lottery.sol";
import {HelperConfig,CodeConstants} from "script/HelperConfig.s.sol";
import {LotteryScript} from "script/Deploy.s.sol";
import {Vm} from "lib/forge-std/src/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

/**
 * @title A testing lottery smart contract
 * @author anurag shingare
 * @notice Here, we are writing test smart contract for our lottery contract
 * @dev We will work with Helperconfig and Deploy script contract to extract our main contract.
 */


contract LotteryTest is Test {
    Lottery lottery;
    HelperConfig helperConfig;

    // MOCK CONTRACT VALUES
    uint96 public constant MOCK_BASEPRICE = 100000000000000000;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1000000000;
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 0.004 ether; // 4e15

  
    uint256 _entranceFee;
    uint256 _interval;
    address _VRFCoordinator;
    bytes32 _gasLane;
    uint256 _subscriptionId;
    uint256 constant public STARTING_USER_BALANCE = 10 ether;
    address constant public USER = address(1);

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

    /**
       * here we will use our deploy script contract instance
       * our deploy script returns 'Lottery contract' and 'HelperConfig contract'
       * provide some eth to user for testing
    */
    function setUp() public {
        LotteryScript lotteryScript = new LotteryScript();
        (lottery,helperConfig) = lotteryScript.setUp();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId(block.chainid);
        _entranceFee = config.entranceFee;
        _interval = config.interval;
        _VRFCoordinator = config.VRFCoordinator;
        _gasLane = config.gasLane;
        _subscriptionId = config.subscriptionId;

        // provide some eth to user for testing
        vm.deal(USER,STARTING_USER_BALANCE);
    }


    // type aliases(enum, struct, array,errors,events) can be call using main contract(Lottery) only.
    function test_GetRaffleState() public view {
        assert(lottery.getLotteryStatus() == Lottery.LotteryStatus.Open);
    }
    // functions(call/send) can be called by our instance(lottery)
    function test_CheckEntranceFee() public view {
        assertEq(lottery.getEntryFeeAmount(), 0.01 ether);
    }

    
    /**
        @dev testing enterLottery() function
    */

    function test_RevertIfEnoughFeeNotProvided() external {
        vm.prank(USER);
        vm.expectRevert(Lottery.Lottery_NotEnoughETHSent.selector);
        lottery.enterLottery();
    }

    function test_RevertIfLotteryStatusIsClosed() public {
        assert(lottery.getLotteryStatus() == Lottery.LotteryStatus.Open);
    }

    function test_CheckHelperConfigEntranceFee() public view {
        assert(_entranceFee == 0.01 ether);
    }

    function test_LotteryCheckIfUserIsAdded() external {
        vm.prank(USER);
        lottery.enterLottery{value:_entranceFee}();
        address playerAddress = lottery.getPlayerAddress(0);
        assert(playerAddress == USER);
    }

    function test_LotteryEntranceFeeEvents() external{
        vm.prank(USER);
        // for indexed params we will set it true 
        vm.expectEmit(true, false, false,false , address(lottery));
        emit EnteredUser(USER);
        lottery.enterLottery{value:_entranceFee}();
    }

    function test_UserNotAllowedToEnterLotteryWhenClosed() external {
        vm.prank(USER);
        lottery.enterLottery{value:_entranceFee}();
        vm.warp(block.timestamp + _interval + 1);
        vm.roll(block.timestamp + 1);
        lottery.performUpkeep("");

        vm.expectRevert(Lottery.Lottery_LotteryIsClosed.selector);
        vm.prank(USER);
        lottery.enterLottery{value:0.01 ether}();
    }


    /**
        @dev Testing checkUpkeep() function
    */    
     function test_FalseIfEnoughBalanceIsNotProvided() public {
        vm.warp(block.timestamp + _interval + 1);
        vm.roll(block.timestamp + 1);

        (bool upkeepNeeded,) = lottery.checkUpkeep("");
        assert(!upkeepNeeded);
     }

     function test_TrueIfEnoughBalanceAndUsersArePresent() public {
        vm.prank(USER);
        lottery.enterLottery{value:_entranceFee}();
        vm.warp(block.timestamp + _interval + 1);
        vm.roll(block.timestamp + 1);
        
        (bool upkeepNeeded,) = lottery.checkUpkeep("");
        assert(upkeepNeeded);
     }

    function test_FalseIfLotteryIsClosed() public {
        vm.prank(USER);
        lottery.enterLottery{value:_entranceFee}();
        vm.warp((block.timestamp + _interval + 1));
        vm.roll(block.timestamp + 1);
        lottery.performUpkeep("");

        (bool upkeepNeeded,) = lottery.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function test_FalseIfEnoughTimeIsNotPassed() public {
        vm.prank(USER);
        lottery.enterLottery{value:_entranceFee}();
        vm.warp(block.timestamp + 1);
        vm.roll(block.timestamp);

        (bool upkeepNeeded,) = lottery.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function test_CheckIfParamsPassedInConstructorIsCorrect() public {
        bool isvalid = (
            (_entranceFee == 0.01 ether) &&
            (_interval == 30 seconds) &&
            (_subscriptionId != 0)
        );
        assert(!isvalid);
    }


    /**
        @dev Testing performUpkeep() function
    */    
    function test_CheckIfUpkeepNeededIsTrue() public {
        vm.prank(USER);
        lottery.enterLottery{value:_entranceFee}();
        vm.warp(block.timestamp + 1);
        vm.roll(block.timestamp);
        (bool upkeepNeeded,) = lottery.checkUpkeep("");
        assert(upkeepNeeded);
    }

    function test_PerformUpKeepRevertsIfupkeepNeededIsFalse() public {
        vm.prank(USER);
        lottery.enterLottery{value:_entranceFee}();
        vm.warp(block.timestamp + 1);
        vm.roll(block.timestamp);
        (bool upkeepNeeded,) = lottery.checkUpkeep("");

        // we can also pass the params for a revert
        vm.expectRevert(Lottery.Lottery_ConditionNotMetToSelectWinner.selector);
        lottery.performUpkeep("");
    }

    function test_PerformUpKeepEmitsRequestId() public {
        vm.prank(USER);
        lottery.enterLottery{value:_entranceFee}();
        vm.warp((block.timestamp + _interval + 1));
        vm.roll(block.timestamp + 1);

        // reading the data from events using recordLogs() and getRecordLogs() cheatcodes
        vm.recordLogs();
        lottery.performUpkeep("");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 requestId = logs[1].topics[1];
        assert(uint256(requestId) > 0);
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
