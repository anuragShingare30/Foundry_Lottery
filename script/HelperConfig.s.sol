// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {Lottery} from "../src/Lottery.sol";
import {VRFCoordinatorV2_5Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mock/LinkToken.sol";
import {CreateSubscription} from "./Interaction.s.sol";

contract CodeConstants {
    // MOCK CONTRACT VALUES
    uint96 public constant MOCK_BASEPRICE = 100000000000000000;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1000000000;
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 0.004 ether; // 4e15


    // CHAIN IDS
    uint public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint public constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint public constant LOCAL_CHAIN_ID = 31337;
}


contract HelperConfig is Script,CodeConstants{    

    // ERROR
    error HelperConfig__InvalidChainId();

    // TYPES (pass all the constructor params here)
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address VRFCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        address link;
        address account;
    }

    // STATE VARIABLES
    // Local network state variables
    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    // FUNCTIONS
    constructor(){
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaETHConfig();
        networkConfigs[ZKSYNC_SEPOLIA_CHAIN_ID] = getL2ChainConfig();
        networkConfigs[LOCAL_CHAIN_ID] = getAnvilETHConfig();
    }

    function getConfig() public view returns(NetworkConfig memory){
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public view returns(NetworkConfig memory){
        if(networkConfigs[chainId].VRFCoordinator != address(0)){
            return networkConfigs[chainId];
        } else if(chainId == LOCAL_CHAIN_ID){
            return networkConfigs[chainId];
        }else{
            revert HelperConfig__InvalidChainId();
        }
    }


    // CONFIGS FOR SEPOLIA AND L2 CHAINS
    function getSepoliaETHConfig() public pure returns(NetworkConfig memory){
        return NetworkConfig({
            entranceFee: 0.01 ether, // 1e16
            interval: 30 seconds,
            VRFCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            // If left as 0, our scripts will create one!
            subscriptionId:71716803254548191292977688998513370311600037443031150854831013200610616480019,
            link:0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account:0x5377CC01A598CBf84F6ffa9007Bdfb33cB741273
        });
    }

    function getL2ChainConfig() public view returns(NetworkConfig memory){}


    // LOCAL CONFIG (Local testing using a Mock contract)
    function getAnvilETHConfig() public returns(NetworkConfig memory){
        // Check to see if we set an active network config
        if(localNetworkConfig.VRFCoordinator != address(0)){
            return localNetworkConfig;
        }

        // DEPLOY MOCK SMART CONTRACT
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock mockVRFcontract = new VRFCoordinatorV2_5Mock(MOCK_BASEPRICE,MOCK_GAS_PRICE_LINK,MOCK_WEI_PER_UNIT_LINK);
        LinkToken linkToken = new LinkToken();
        uint subscriptionId;
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether, // 1e16
            interval: 30 seconds,
            VRFCoordinator: address(mockVRFcontract),
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            // If left as 0, our scripts will create one!
            subscriptionId:0,
            link:address(linkToken),
            account:0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
        });
        return localNetworkConfig;
    }


    
}