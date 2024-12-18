// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Lottery} from "../src/Lottery.sol";

contract MyScript is Script {
    Lottery public lottery;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        

        vm.stopBroadcast();
    }
}
