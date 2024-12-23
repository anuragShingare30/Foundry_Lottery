// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {Lottery} from "../src/Lottery.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract LotteryScript is Script {


    function setUp() public returns (Lottery, HelperConfig) {

        // CREATED NEW HELPERNETWORK CONFIG INSTANCE
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        uint256 _entranceFee = config.entranceFee;
        uint256 _interval = config.interval;
        address _VRFCoordinator = config.VRFCoordinator;
        bytes32 _gasLane = config.gasLane;
        uint256 _subscriptionId = config.subscriptionId;


        vm.startBroadcast();
        
        // CREATED NEW CONTRACT INSTANCE AND PASSED CONSTRUCTOR PARAMS
        Lottery lottery = new Lottery(
            _entranceFee,
            _interval,
            _VRFCoordinator,
            _gasLane,
            _subscriptionId
        );

        vm.stopBroadcast();

        return (lottery, helperConfig);
    }


    // BY DEFAULT forge script EXECUTES THE 'run' FUNCTION DURING DEPLOYMENT
    function run() external returns(Lottery,HelperConfig) {
        return setUp();
    }



}