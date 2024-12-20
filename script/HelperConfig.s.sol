// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Lottery} from "../src/Lottery.sol";


abstract contract CodeConstants {
    
    // CHAIN IDS
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}


contract HelperConfig is Script,CodeConstants{    

    // ERROR
    error HelperConfig__InvalidChainId();

    // TYPES
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address VRFCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
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

    function getConfigByChainId(uint256 chainId) public view returns(NetworkConfig memory){
        if(chainId == ETH_SEPOLIA_CHAIN_ID){
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
            subscriptionId:4145
        });
    }

    function getL2ChainConfig() public view returns(NetworkConfig memory){}


    // LOCAL CONFIG
    function getAnvilETHConfig() public view returns(NetworkConfig memory){}
}