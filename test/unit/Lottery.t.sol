// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {Lottery} from "src/Lottery.sol";
import {HelperConfig,CodeConstants} from "script/HelperConfig.s.sol";
import {LotteryScript} from "script/Deploy.s.sol";


contract CounterTest is Test {
    Lottery lottery;
    HelperConfig helperConfig;

    uint256 _entranceFee;
    uint256 _interval;
    address _VRFCoordinator;
    bytes32 _gasLane;
    uint256 _subscriptionId;

    function setUp() public {
        // here we will use our deploy script contract instance
        LotteryScript lotteryScript = new LotteryScript();
        (lottery,helperConfig) = lotteryScript.setUp();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId(block.chainid);
        _entranceFee = config.entranceFee;
        _interval = config.interval;
        _VRFCoordinator = config.VRFCoordinator;
        _gasLane = config.gasLane;
        _subscriptionId = config.subscriptionId;
    }

    function test_GetRaffleState() public {
        assert(lottery.getLotteryStatus() == Lottery.LotteryStatus.Open);
    }
    
    function test_CheckEntranceFee() public {
        assertEq(lottery.getEntryFeeAmount(), 0.01 ether);
    }
}
