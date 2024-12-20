// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Lottery} from "../src/Lottery.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract MyScript is Script {

    function setUp() public returns (Lottery, HelperConfig) {
        // CREATED NEW NETWORK CONFIG INSTANCE
        HelperConfig helperConfig = new HelperConfig();
        uint256 _entranceFee = helperConfig.getConfigByChainId(block.chainid).entranceFee;
        uint256 _interval = helperConfig.getConfigByChainId(block.chainid).interval;
        address _VRFCoordinator = helperConfig.getConfigByChainId(block.chainid).VRFCoordinator;
        bytes32 _gasLane = helperConfig.getConfigByChainId(block.chainid).gasLane;
        uint256 _subscriptionId = helperConfig.getConfigByChainId(block.chainid).subscriptionId;


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


    // BY DEFAULT forge script EXECUTES THE UN FUNCTION DURING DEPLOYMENT
    function run() external returns(Lottery,HelperConfig) {
        return setUp();
    }



}