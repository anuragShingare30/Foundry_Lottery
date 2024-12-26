// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
/**
    @dev Here, will create the CreateSubscription , AddConsumers and FundSubscription.
    contract to get our subscription Id for our RGF
 */


contract CreateSubscription is Script,HelperConfig {

    function createSubscription() public returns(uint subId, address s_vrfCoordinator){
        console.log("creating subscription at : ", block.chainid);
        HelperConfig helperConfig = new HelperConfig();
        address s_vrfCoordinator = helperConfig.getConfig().VRFCoordinator; 

        vm.startBroadcast();
        uint subId = VRFCoordinatorV2_5Mock(s_vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("The subId is : ", subId);
        return(subId,s_vrfCoordinator);
    }

    function run() external {
        createSubscription();
    }
}


contract FundSubscription is Script,HelperConfig{

    function fundSubscription(uint256 _subId, uint256 _amount,address s_vrfCoordinator) public {
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(s_vrfCoordinator).fundSubscription(_subId, _amount);
        vm.stopBroadcast();
    }

    function fundSubscriptionWithConfig() public {
        uint amount = 3 ether;
        HelperConfig helperConfig = new HelperConfig();
        address s_vrfCoordinator = helperConfig.getConfig().VRFCoordinator; 
        uint subId = helperConfig.getConfig().subscriptionId;

        fundSubscription(subId, amount,s_vrfCoordinator);
    }

    function run() public {
        return fundSubscriptionWithConfig();
    }
}



