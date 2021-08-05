# Uniswaperv3

Challenge from https://decentlabs.io/ bootstrapped from https://github.com/paulrberg/solidity-template

### Description
The requirements for the codebase are as such:
* Implements an ERC20 token
* Creates its own Uniswap V3 pair with ETH
* Seeds that Uniswap pair with liquidity
* The above requirements should be implemented directly in the token contract
* Tests, deployment/migration scripts, and documentation would be appreciated.

## Usage

### Pre Requisites

Before running any command, make sure to install dependencies:

```sh
$ yarn install
```

### Compile

Compile the smart contracts with Hardhat:

```sh
$ yarn compile
```

### TypeChain

Compile the smart contracts and generate TypeChain artifacts:

```sh
$ yarn typechain
```

### Lint Solidity

Lint the Solidity code:

```sh
$ yarn lint:sol
```

### Lint TypeScript

Lint the TypeScript code:

```sh
$ yarn lint:ts
```

### Test

Run the Mocha tests:

```sh
$ yarn test
```

### Coverage

Generate the code coverage report:

```sh
$ yarn coverage
```

### Report Gas

See the gas usage per unit test and average gas per method call:

```sh
$ REPORT_GAS=true yarn test
```

### Clean

Delete the smart contract artifacts, the coverage reports and the Hardhat cache:

```sh
$ yarn clean
```

### Deploy

Deploy the contracts to Hardhat Network:

```sh
$ yarn deploy
```

Deploy the contracts to a specific network, such as the Ropsten testnet:

```sh
$ yarn deploy:network kovan
```
