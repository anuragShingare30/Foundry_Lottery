// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Lottery} from "src/Lottery.sol";
import {LinkToken} from "test/mock/LinkToken.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {Script, console} from "../lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

/** 
    @dev Here, will create the CreateSubscription , AddConsumers and FundSubscription.
    contract to get our subscription Id for our RGF
 */

contract CreateSubscription is Script {
    function createSubscription()
        public
        returns (uint subId, address s_vrfCoordinator)
    {
        console.log("creating subscription at : ", block.chainid);
        HelperConfig helperConfig = new HelperConfig();
        address s_vrfCoordinator = helperConfig.getConfig().VRFCoordinator;

        vm.startBroadcast();
        uint subId = VRFCoordinatorV2_5Mock(s_vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console.log("The subId is : ", subId);
        return (subId, s_vrfCoordinator);
    }

    function run() external {
        createSubscription();
    }
}


// fund subscription
contract FundSubscription is Script {
    uint internal FUND_AMOUNT = 3 ether;
    uint public constant LOCAL_CHAIN_ID = 31337;

    function fundsubscription(
        uint256 subId,
        address s_vrfCoordinator,
        address linkToken
    ) public {
        console.log("VRF_Coordinator :", s_vrfCoordinator);
        console.log("Subscription ID :", subId);
        console.log("Block chain id :", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(s_vrfCoordinator).fundSubscription(
                subId,
                FUND_AMOUNT
            );

            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(
                address(s_vrfCoordinator),
                FUND_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        }
    }

    function fundSubscriptionWithConfig() public {
        uint amount = 3 ether;
        HelperConfig helperConfig = new HelperConfig();
        address s_vrfCoordinator = helperConfig.getConfig().VRFCoordinator;
        uint subId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;

        fundsubscription(subId, s_vrfCoordinator, linkToken);
    }

    function run() public {
        return fundSubscriptionWithConfig();
    }
}

// add consumer
contract AddConsumer is Script {
    function addConsumerWithConfig(address contractAddress) public {
        HelperConfig helperConfig = new HelperConfig();
        uint subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getConfig().VRFCoordinator;

        addConsumer(subId, contractAddress, vrfCoordinator);
    }

    function addConsumer(
        uint subId,
        address contractAddress,
        address vrfCoordinator
    ) public {
        console.log("Subscription ID :", subId);
        console.log("Block chain id :", block.chainid);

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
            subId,
            contractAddress
        );
        vm.stopBroadcast();
    }

    function run() public {
        // This will give us the contract address for our recent deployed contract
        address contractAddress = DevOpsTools.get_most_recent_deployment(
            "Lottery",
            block.chainid
        );
        addConsumerWithConfig(contractAddress);
    }
}
