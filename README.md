### FOUNDRY AND FORGE️‍ 🔥

- Foundry totally depends on solidity and not on JS.

**Note : dependencies are added as git-submodules and not as npm or nodejs modules** 

- **src folder** : All our main smart contracts
- **test folder** : All the test are written here.
- **scripts folder** : To interact with smart contract we will write scripting file in soilidity
- Project is configured using the **foundry.toml** file


#### INSTALLATION

```solidity
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc 
// 
foundryup
forge init ProjectName
forge install openzeppelin/openzeppelin-contracts
```

**forge** : the build, test, debug, deploy smart contracts
**anvil** :  the foundry equivalent of Ganache
**cast** : low level access to smart contracts (a bit of a truffle console equivalent)




#### DEPLOYING SC USING FOUNDRY

```solidity
// using anvil
anvil
forge script script/Deploy.s.sol:MyScript --fork-url http://localhost:8545 --broadcast
forge script script/Deploy.s.sol:MyScript --fork-url http://localhost:8545 --account <account_name> --sender <address> --broadcast


// on testnet seolia
forge script script/Deploy.s.sol:MyScript --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
forge script script/Deploy.s.sol:MyScript --rpc-url $SEPOLIA_RPC_URL --account <account_name> --sender <address> --broadcast --verify -vvvv
forge script script/Deploy.s.sol:MyScript --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify -vvvv
```

##### STORE YOUR PRIVATE KEY IN KEYSTORE BY FOUNDRY

- Here, we will not store our private key in dotenv file. Rather, we will store it in **KeyStore** provided by foundry.
- Once we have stored it in keystore we can used it in any project.
**Note** : This is useful when we need to submit our private key in an terminal.

```solidity
cast wallet import privateKey --interactive
cast wallet list
```

##### DEPLOYING ON TESTNET AND ANVIL

- deploy our Smart Contract using Foundry scripts.
- We will write the deploy code in the **script** folder in solidity.

```solidity
// script/Deploy.s.sol

import {Script} from "forge-std/Script.sol";
import {TestContract} from "../src/Web3.sol";

contract MyScript is Script{
    
    function run() external returns(TestContract){
        // This loads in the private key from our .env file
        uint256 privateKey = vm.envUint("ANVIL_PRIVATE_KEY");

        // a special cheatcode that records calls and contract creations made by our main script contract.
        vm.startBroadcast(privateKey);
        
        // If we have constructor then passed the value in the function as params.
        // CREATED A NEW CONTRACT INSTANCE.
        TestContract token = new TestContract();
        vm.stopBroadcast();
        return token;
    }
}
```

- change the **.env and foundry.toml file**

```js
// .env
# SEPOLIA TESTNET
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/{INFURA_KEY}
ETHERSCAN_API_KEY=
PRIVATE_KEY=

# ANVIL LOCALLY
LOCALLY_RPC_URL=http://localhost:8545
ANVIL_PRIVATE_KEY=
```

```js
// foundry.toml
fs_permissions = [{ access = "read", path = "./"}]
[rpc_endpoints]
sepolia = "${SEPOLIA_RPC_URL}"

[etherscan]
sepolia = { key = "${ETHERSCAN_API_KEY}" }
```



#### INTERACTING WITH SC USING CAST

- After deploying sc we can interact (send/call) the functions using **cast**

```solidity
cast send <address> "setName(string)" "anurag" --rpc-url <rpc_url> --private-key <private_key>
cast call <address> "getName()"
cast to-base 0x7717 dec
```


#### TO USE L2, ROLLUPS BLOCKCHAIN TECH. (EX: ZKSYNC)

```js
// to use vanilla-foundry
foundryup

// to use L2/ROLLUPS
foundry-zksync
```

- For L2 and rollups you can refer there docs for more clearance
- **--zksync** refers that we are running on L2/rollups blockchain



#### TESTING IN FOUNDRY

- The tests in Foundry are written in Solidity.
- If the test function reverts, the test fails, otherwise it passes.
- We will use **VM Cheatcodes.**

- Forge Standard Library -> forge-std

1. **UNIT TESTING** - TESTING A SPECIFIC PART OF OUR CODE.
2. **INTEGRATION TEST** - INTEGRATING SC A TESTING SPECIFIC PORTION.
3. **FORKED TEST** - TESTING OUR CODE ON A SIMULATED REAL ENVIRONMENT.
4. **STAGING TEST** - TESTING OUR CODE IN TESTNET/MAINNET. EX:- SEPOLIA, ANVIL LOCAL TESTING


#### Forge Standard Library

- **Vm.sol**: Up-to-date cheatcodes interface
- **console.sol and console2.sol**: Hardhat-style logging functionality
- **Script.sol**: Basic utilities for Solidity scripting
- **Test.sol**: A superset of DSTest containing standard libraries, a cheatcodes instance (vm), and Hardhat console


#### FOUNDRY CHEATCODES FOR TESTING

1. **vm.prank(address(0))** - simulate a TNX to be sent from specific address.

2. **vm.deal(address(this), 1 ether)** - Used to give the test contract Ether to work with.

3. **vm.expectRevert(bytes("Niche ka functions pass nahi hore!!!"))** - Verifies that a specific error message is returned when a transaction fails.


#### FORK TESTING

- Forge supports testing in a forked environment
- To run all tests in a forked environment, such as a forked Ethereum mainnet, pass an RPC URL via the --fork-url flag

- Sometimes we need to run test from scratch. Before running test again remove the **cache directory**/**forge clean**


```solidity
// TO LOAD THE .env CONTENT
source .env
echo $RPC_URL

// TESTING SC
forge test -vvv
forge test --fork-url $RPC_URL -vvvv

// TO RUN THE SINGLE TEST
forge test --mt testBalance -vvv --fork-url $RPC_URL

// CONVERGING SC -> This command displays which parts of your code are covered by tests.
forge converge --fork-url $RPC_URL   

// DEBUGGING SC
forge debug --debug src/Web3.sol:TestContract --sig "function(argu)" "arguValue"

// Forge can remap dependencies to make them easier to import. Forge will automatically try to deduce some remappings for you:
forge remappings

// Forge supports identifying contracts in a forked environment with Etherscan.
forge test --fork-url <your_rpc_url> --etherscan-api-key <your_etherscan_api_key>
```