// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {Lottery} from "src/Lottery.sol";
import {HelperConfig,CodeConstants} from "script/HelperConfig.s.sol";
import {LotteryScript} from "script/Deploy.s.sol";

/**
 * @title A testing lottery smart contract
 * @author anurag shingare
 * @notice Here, we are writing test smart contract for our lottery contract
 * @dev We will work with Helperconfig and Deploy script contract to extract our main contract.
 */


contract LotteryTest is Test {
    Lottery lottery;
    HelperConfig helperConfig;

  
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

        vm.prank(USER);
        vm.expectRevert(Lottery.Lottery_LotteryIsClosed.selector);
        lottery.enterLottery{value:0.01 ether}();
    }

}
