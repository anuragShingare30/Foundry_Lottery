// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {Lottery} from "../src/Lottery.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription} from "./Interaction.s.sol";


contract LotteryScript is Script {


    function setUp() public returns (Lottery, HelperConfig) {

        // CREATED NEW HELPERNETWORK CONFIG INSTANCE
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        
        if(config.subscriptionId == 0){
            // create subscription and get the subscriptionId
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId,config.VRFCoordinator) = createSubscription.createSubscription();


            // fund subscription
            

            // add consumers

        }

        vm.startBroadcast();
        
        // CREATED NEW CONTRACT INSTANCE AND PASSED CONSTRUCTOR PARAMS
        Lottery lottery = new Lottery(
            config.entranceFee,
            config.interval,
            config.VRFCoordinator,
            config.gasLane,
            config.subscriptionId
        );

        vm.stopBroadcast();

        return (lottery, helperConfig);
    }


    // BY DEFAULT forge script EXECUTES THE 'run' FUNCTION DURING DEPLOYMENT
    function run() external returns(Lottery,HelperConfig) {
        return setUp();
    }



}