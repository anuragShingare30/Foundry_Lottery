### FOUNDRY AND FORGE️‍ 🔥

- Foundry totally written on solidity and not on JS.

**Note : dependencies are added as git-submodules and not as npm or nodejs modules**

- **src folder** : All our main smart contracts
- **test folder** : All the test are written here.
- **scripts folder** : To interact with smart contract we will write scripting file in soilidity
- Project is configured using the **foundry.toml** file
- **lib folder** : Dependencies are stored as git-submodules in lib/

- After compiling/deploying the smart contract **abi array will be in out/ folder in contract name file**

#### INSTALLATION

```solidity
// only once
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc 
foundryup
// to initialize project
forge init ProjectName
forge install openzeppelin/openzeppelin-contracts
```

**forge** : the build, test, debug, deploy smart contracts
**anvil** :  the foundry equivalent of Ganache
**cast** : low level access to smart contracts (a bit of a truffle console equivalent)

#### Compile smart contract

```solidity
forge build
```

#### .env and foundry.toml file

```solidity
// .env
SEPOLIA_RPC_URL=
PRIVATE_KEY=
ETHERSCAN_API_KEY=


// foundry.toml
[rpc_endpoints]
sepolia = "${SEPOLIA_RPC_URL}"

[etherscan]
sepolia = { key = "${ETHERSCAN_API_KEY}"}


// This loads in the private key from our .env file
uint256 privateKey = vm.envUint("ANVIL_PRIVATE_KEY");
```



#### SOLIDITY SCRIPTING

- Written in solidity
- they are run on the fast Foundry EVM backend, **which provides dry-run capabilities.**
- **By default, scripts are executed by calling the function named `run`, our entrypoint.**

- Pass all the constructor params in contract instance.
- **We will use `HelperConfig.s.sol and Intraction.s.sol` file in our `Deploy.s.sol`**




#### DEPLOYING SMART CONTRACT (COMMMANDS)

```solidity
// Scripting with Arguments(Passing params from command line) OPTIONAL
forge script --chain sepolia script/Deploy.s.sol:MyScript "NFT tutorial" TUT baseUri --sig 'run(string,string,string)' --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv


// using anvil
anvil
forge script script/Deploy.s.sol:MyScript --fork-url http://localhost:8545 --broadcast
forge script script/Deploy.s.sol:MyScript --fork-url http://localhost:8545 --account <account_name> --sender <address> --broadcast


// on testnet sepolia
forge script script/Deploy.s.sol:MyScript --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
forge script script/Deploy.s.sol:MyScript --rpc-url $SEPOLIA_RPC_URL --account <account_name> --sender <address> --broadcast --verify -vvvv
forge script script/Deploy.s.sol:MyScript --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify -vvvv
```



##### STORE YOUR PRIVATE KEY IN KEYSTORE (CAST)

- Here, we will not store our private key in dotenv file. Rather, we will store it in **KeyStore** provided by foundry.
- Once we have stored it in keystore we can used it in any project.
**Note** : This is useful when we need to submit our private key in an terminal.

```solidity
cast wallet import privateKey --interactive
cast wallet list
```


##### DEPLOYING ON TESTNET, ANVIL and ROLLUPS BLOCKCHAIN

- deploy our Smart Contract using Foundry scripts.
- We will write the deploy code in the **script** folder in solidity.



**By default, scripts are executed by calling the function named run, our entrypoint.**

```solidity
// Just a 
// script/Deploy.s.sol

import {Script} from "forge-std/Script.sol";
import {TestContract} from "../src/Web3.sol";

contract MyScript is Script{
    
    // BY DEFAULT forge script EXECUTES THE 'run' FUNCTION DURING DEPLOYMENT
    function setUp() external returns(TestContract){
        // This loads in the private key from our .env file
        uint256 privateKey = vm.envUint("ANVIL_PRIVATE_KEY");

        // contract creations made by our main script contract.
        // private key is passed to instruct to use that key for signing the transactions. 
        vm.startBroadcast(privateKey);
        
        // If we have constructor then passed the value in the function as params.
        // CREATED A NEW CONTRACT INSTANCE.
        TestContract token = new TestContract("Token Name","ETH", "base_URL");

        vm.stopBroadcast();
        return token;
    }

    function run() external returns(TestContract){
        return setUp();
    }
}
```




#### DEPLOY SCRIPT CONTRACT || HELPERCONFIG FILE || INTERACTION FILE

- In  **`HelperConfig.s.sol`** file we will declare all the `params, function and variables` we need to pass in constructor during deployment.


**HelperConfig.s.sol**
```solidity
contract HelperConfig is Script{
    // ERROR
    error HelperConfig__InvalidChainId();

    // TYPES (pass all the constructor params here)
    struct NetworkConfig {
        uint priceFeed;
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
        return NetworkConfig({priceFeed:200});
    }

    function getL2ChainConfig() public view returns(NetworkConfig memory){
        return NetworkConfig({priceFeed:200});
    }

    // LOCAL CONFIG (Local testing using a Mock contract)
    // Here, we will write the mock script smart contract on local network  
    function getAnvilETHConfig() public returns(NetworkConfig memory){
        // Check to see if we set an active network config
        if(localNetworkConfig.VRFCoordinator != address(0)){
            return localNetworkConfig;
        }

        // DEPLOY MOCK SMART CONTRACT
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock mockVRFcontract = new VRFCoordinatorV2_5Mock(MOCK_BASEPRICE);
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({priceFeed:200});
        return localNetworkConfig;
    }

}
```

- In `Interaction.s.sol` we will create functions from which our `on-chain data interacts with off-chain data`
- Example : chainlink VRF, chainlink automation, Data feeds and chainlink functions.




**Interaction.s.sol**
```solidity
import {Lottery} from "src/Lottery.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";


contract FundSubscription is Script{

    function fundSubscriptionWithConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        uint subId = helperConfig.getConfig().subscriptionId;
        fundSubscription(subId);
    }

    function fundSubscription(uint256 subId) public {
        uint amount = 0.01 ether;
        vm.startBroadcast();
        MockContract(contractAddress).topUpSubscription(amount);
        vm.stopBroadcast();
    }

    function run() public {
        fundSubscriptionWithConfig();
    }
}

contract AddConsumer is Script{

    function addConsumerWithConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        addConsumer();
    }

    function addConsumer() public {
        vm.startBroadcast();
        MockContract(contractAddress).addConsumers(address(0));
        vm.stopBroadcast();
    }

    function run() public {
        addConsumerWithConfig();
    }
}
```


- This is the basic structure of writing **HelperConfig and Interaction** file.



**By default, scripts are executed by calling the function named run, our entrypoint.**

- This is the `pattern and best practice` we should followed!!!


**Deploy.s.sol**
```solidity
import {Contract} from "../src/Contract.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {FundSubscription, AddConsumer} from "./Interaction.s.sol";

contract MyScript is Script {

    function setUp() public returns (Contract, HelperConfig){
        // CREATED NEW HELPERNETWORK CONFIG INSTANCE
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // If for some valid condition we need to call the interaction.s.sol
        if(condition){
            // funding subscription
            FundSubscription fundSubscription = new FundSubscription();

            // add consumer after deployment
            AddConsumer addConsumer = new AddConsumer();
        }


        vm.startBroadcast();
        // pass all the constructor params here...
        Contract token = new Contract(
            config.priceFedd,
            config.DataFeed,
        );
        vm.stopBroadcast();

        return {token,helperConfig};
    }

    // BY DEFAULT forge script EXECUTES THE 'run' FUNCTION DURING DEPLOYMENT
    function run() external returns(Contract,HelperConfig) {
        return setUp();
    }
}
```



**change the .env and foundry.toml file**

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
- contract name starting with **test** are considered as a good practice in foundry

- Forge Standard Library -> forge-std

1. **UNIT TESTING** - TESTING A SPECIFIC PART OF OUR CODE.
2. **INTEGRATION TEST** - INTEGRATING SC A TESTING SPECIFIC PORTION.
3. **FORKED TEST** - TESTING OUR CODE ON A SIMULATED REAL ENVIRONMENT.
4. **STAGING TEST** - TESTING OUR CODE IN TESTNET/MAINNET. EX:- SEPOLIA, ANVIL LOCAL TESTING



#### FORK TESTING/UNIT TESTING (COMMANDS)

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
forge test --mt testFunctionName
forge test --mt testBalance -vvv --fork-url $RPC_URL

// CONVERGING SC -> This command displays which parts of your code are covered by tests.
forge converge --fork-url $RPC_URL   

// DEBUGGING SC
forge debug --debug src/Web3.sol:TestContract --sig "function(argu)" "arguValue"


// Forge supports identifying contracts in a forked environment with Etherscan.
forge test --fork-url <your_rpc_url> --etherscan-api-key <your_etherscan_api_key>
```




#### Forge Standard Library

- **Vm.sol**: Up-to-date cheatcodes interface
- **console.sol and console2.sol**: Hardhat-style logging functionality
- **Script.sol**: Basic utilities for Solidity scripting
- **Test.sol**: A superset of DSTest containing standard libraries, a cheatcodes instance (vm), and Hardhat console



#### Some best practices to followed when writing the tests

1. **`vm.prank(address(0))`** 
   - simulate a TNX to be sent from given specific address.

2. **`vm.deal(address(this), 1 ether)`** 
   - Used to give the test contract Ether to work with.

3. **`vm.expectRevert()`**
   - Agar mera call/send function revert ho gaya, Toh mera test pass ho jayega.
   - Else, test fail ho jayega.

4. **`vm.expectRevert(Contract.CustomError.selector)`**    
   - import the error from contract with 'selector'

5. **`vm.expectRevert(abi.enocodeSelector(Contract.CustomError.selector, params1, params2))`**

6. **test_FunctionName**
   - Functions prefixed with 'test' are run as a test case by forge.

7. **For, testFail** 
   - A good practice is to use the pattern **test_Revert[If|When]_Condition** in combination with the **expectRevert** cheatcode

    ```solidity
        function test_RevertCannotSubtract43() public {
            vm.expectRevert(stdError.arithmeticError);
            testNumber -= 43;
        }
    ```

8. **Test functions must have either **external or public** visibility.**


9. **type aliases(enum, struct, array,errors,events) can be call using main contract(Lottery) only.**
    ```solidity
    function test_GetRaffleState() public view {
        assert(lottery.getLotteryStatus() == Lottery.LotteryStatus.Open);
    }
    ```


10.  **functions(call/send) can be called by our instance(lottery)**
    ```solidity
    function test_CheckEntranceFee() public view {
        assertEq(lottery.getEntryFeeAmount(), 0.01 ether);
    }
    ```


11.  **To Transfer some value during calling or Transact eth to SC**

    ```solidity
    function test_LotteryCheckIfUserIsAdded() external {
        vm.prank(USER);
        // by this method we pass some eth to our user.
        lottery.enterLottery{value:_entranceFee}();
        }
    ```


12. **`vm.expectEmit()`** : 
    -  a specific log is emitted during the next call.

    ```solidity
    function test_LotteryEntranceFeeEvents() external{
        vm.prank(USER);
        // for indexed params we will set it true 
        vm.expectEmit(true, false, false,false , address(lottery));
        emit EnteredUser(USER);
        lottery.enterLottery{value:_entranceFee}();
    }
    ```



13. **`vm.warp() || vm.roll()`**
    - Sets block.timestamp.
    - Sets block.timestamp.

    ```solidity
    function test_UserNotAllowedToEnterLotteryWhenClosed() external {
        vm.prank(USER);
        lottery.enterLottery{value:_entranceFee}();
        vm.warp(block.timestamp + _interval + 1);
        vm.roll(block.timestamp + 1);
    }
    ``` 


14. **`vm.recordLogs() || vm.getRecordedLogs()`**
    - Tells the VM to start recording all the emitted events.
    - To access them, use `getRecordedLogs`  

    ```solidity
    function test_GetEventsLogs() public {
        vm.recordLogs();
        lottery.performUpkeep("");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 value = logs[1].topics[1];
        assert(uint256(value) > 0);
    }
    ``` 



#### WRITING UNIT/FORK TEST

- For, advance testing we will use `HelperConfig, Contract and Deploy` file.
- Follow, `Best practices and vm cheatcodes above for advance and better testing`.


**Contract.t.sol**
```solidity
import {Contract} from "src/Contract.sol";
import {ContractScript} from "script/Deploy.s.sol";
import {HelperConfig,CodeConstants} from "script/HelperConfig.s.sol";


contract ContractTest is Test {
    Contract contracts;
    HelperConfig helperConfig;

    // all constructor params and used variables
    uint params1;
    uint params2;
    uint params3;

    // events : Copy all events from contract to be used

    /**
       * here we will use our deploy script contract instance
       * our deploy script setUp() returns 'Main contract' and 'HelperConfig contract'
       * provide some eth to user for testing
    */

    function setUp() public {
        ContractScript contractScript = new ContractScript();
        (contracts,helperConfig) = contractScript.setUp();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        _param1 = config.param1;
        _param2 = config.param2;
        _param3 = config.param3;

        // provide some eth to user for testing
        vm.deal(address(0),1e18);
    }

    function test_GetContractStatus() public {
        assert(contracts.getStatus() == Open);
    }

    function test_SomeChecks() external {
        assert(contracts.getSomeVar() == 1 ether);
    }

}
```






#### Remapping dependencies

- Before running the forge remapping command we need to store the path in **toml**

```js
remapping = ['@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts']
```

- **@chainlink/contracts** now is equal to the actual path of contract

```solidity
// Forge can remap dependencies to make them easier to import. Forge will automatically try to deduce some remappings for you:
forge remappings
```




### FOUNDRY COVERAGE

- Displays which parts of your code are covered by tests.

```solidity
// View summarized coverage:
forge coverage

// Create lcov file with coverage data:
forge coverage --report lcov

// This will create a .txt file that will give us the :
forge coverage --report debug > coverage.txt
```




### FOUNDRY-DEVOPS

# foundry-devops

A repo to get the most recent deployment from a given environment in foundry. This way, you can do scripting off previous deployments in solidity.

It will look through your `broadcast` folder at your most recent deployment.

## Features

- Get the most recent deployment of a contract in foundry
- Checking if you're on a zkSync based chain

# Getting Started

## Installation

- Update forge-std to use newer FS cheatcodes

```bash
forge install Cyfrin/foundry-devops --no-commit

forge install foundry-rs/forge-std@v1.8.2 --no-commit
```

#### Usage - Getting the most recent deployment

**1. Update your `foundry.toml` to have read permissions on the `broadcast` folder.**

```solidity
fs_permissions = [
    { access = "read", path = "./broadcast" },
    { access = "read", path = "./reports" },
]
```

2. **Import the package, and call `DevOpsTools.get_most_recent_deployment("MyContract", chainid);`**

ie:

```solidity
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {MyContract} from "my-contract/MyContract.sol";
.
.
.
function interactWithPreviouslyDeployedContracts() public {
    address contractAddress = DevOpsTools.get_most_recent_deployment("MyContract", block.chainid);
    MyContract myContract = MyContract(contractAddress);
    myContract.doSomething();
}
```

## Usage - zkSync Checker

### Prerequisites

- [foundry-zksync](https://github.com/matter-labs/foundry-zksync)
  - You'll know you did it right if you can run `foundryup-zksync --help` and you see a response like:

```
The installer for Foundry-zksync.

Update or revert to a specific Foundry-zksync version with ease.
.
.
.
```

### Usage - ZkSyncChainChecker

In your contract, you can import and inherit the abstract contract `ZkSyncChainChecker` to check if you are on a zkSync based chain. And add the `skipZkSync` modifier to any function you want to skip if you are on a zkSync based chain.

It will check both the precompiles or the `chainid` to determine if you are on a zkSync based chain.

```javascript
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";

contract MyContract is ZkSyncChainChecker {

  function doStuff() skipZkSync {
```

### ZkSyncChainChecker modifiers

- `skipZkSync`: Skips the function if you are on a zkSync based chain.
- `onlyZkSync`: Only allows the function if you are on a zkSync based chain.
  
### ZkSyncChainChecker Functions

- `isZkSyncChain()`: Returns true if you are on a zkSync based chain.
- `isOnZkSyncPrecompiles()`: Returns true if you are on a zkSync based chain using the precompiles.
- `isOnZkSyncChainId()`: Returns true if you are on a zkSync based chain using the chainid.

### Usage - FoundryZkSyncChecker

In your contract, you can import and inherit the abstract contract `FoundryZkSyncChecker` to check if you are on the `foundry-zksync` fork of `foundry`.

> !Important: Functions and modifiers in `FoundryZkSyncChecker` are only available if you run `foundry-zksync` with the `--zksync` flag.

```javascript
import {FoundryZkSyncChecker} from "lib/foundry-devops/src/FoundryZkSyncChecker.sol";

contract MyContract is FoundryZkSyncChecker {

  function doStuff() onlyFoundryZkSync {
```

You must also add `ffi = true` to your `foundry.toml` to use this feature.

### FoundryZkSync modifiers

- `onlyFoundryZkSync`: Only allows the function if you are on `foundry-zksync`
- `onlyVanillaFoundry`: Only allows the function if you are on `foundry`

### FoundryZkSync Functions

- `is_foundry_zksync`: Returns true if you are on `foundry-zksync`




