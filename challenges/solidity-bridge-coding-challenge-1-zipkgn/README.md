# ERC20 Bridges
Scroll down to  "Solidity Coding Challenge" section for the challenge.

## Getting Started

* install Foundry using this [Guide](https://book.getfoundry.sh/getting-started/installation)
* clone the repo
* Navigate inside repo `cd ./solidity-bridge-coding-challenge-1-zipkgn`
* Run `forge install` to install smart contract libraries
* Run `yarn` to install node dependencies
* Create `.env` similar to `env.example` file. Fill in the secrets in `.env` file
* To compile run `forge compile`
* To run tests `forge test`

## LayerZero Bridge

### References
* [OFT Reference implementation](https://github.com/LayerZero-Labs/wrapped-asset-bridge/blob/13c8582fc6492ff78966647c6ebd5913c192d602/contracts/WrappedTokenBridge.sol)
* [LZ integration checklist](https://layerzero.gitbook.io/docs/evm-guides/layerzero-integration-checklist)
* [Mainnet official end points](https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids)
* [Bucket Level rate limit and Daily Rate limit](https://github.com/omni/tokenbridge-contracts/blob/908a48107919d4ab127f9af07d44d47eac91547e/contracts/upgradeable_contracts/erc20_to_native/ForeignBridgeErcToNative.sol#L64)

## Axelar Network Bridge

* The inter chain tokens can be realised using 
 * calling `sendToken` on chain's gateway contract. Prior to that call `deployToken` on gateway contract
 * deposit address using the AxelarJS SDK
 * Building own interchain token
 * Using general purpose message passing using callContract 

### References
* [Axelar Gateway Mock testing](https://github.com/axelarnetwork/axelar-examples/blob/b844030a5cdcf63085bc95def3bd1d5217b48de1/scripts/libs/execute.js)
* [Axelar inter chain token protocol Implementation Reference](https://github.com/axelarnetwork/axelar-examples/blob/b844030a5cdcf63085bc95def3bd1d5217b48de1/examples/evm/cross-chain-token/ERC20CrossChain.sol)
* [Bucket Level rate limit and Daily Rate limit](https://github.com/omni/tokenbridge-contracts/blob/908a48107919d4ab127f9af07d44d47eac91547e/contracts/upgradeable_contracts/erc20_to_native/ForeignBridgeErcToNative.sol#L64)


## Deterministic deployment

# Solidity Coding Challenge

## Scenario

We want to develop a bridge for our RWA tokens utilising the approach of mint and burn. Meaning, RWA tokens will be burned on source chains and minted on destination chain. To do this, we want to use other protocols like Axelar, Layerzero, and Wormhole since we do not want to develop the ability to pass messages across several chains.

## Constraints

- Use at least 2 message passing protocols from {Axelar, Layerzero, Wormhole}.
- Implement thresholds on destination bridge such that arbitrary thresholds can be set based on amounts, e.g., 100K bridge transfer needs 2 approvers (where a message delivered on destination chain by a message passing protocol is considered an approver, like Axelar).
- Admin must have the ability to define arbitrary thresholds.
- The bridge must have the ability to be paused if needed.
- The bridge must support multiple RWA ERC-20 tokens.
- The bridge must have a daily rate limit where no more tokens are minted if this limit is met.
- There should be extensive tests for the bridge.

## Assumptions

- Issuer can solely mint tokens.
- RWA tokens are simple ERC20 tokens with mint and burn.

## Nice to Have

- Use all 3 message passing protocols.
- Implement bucket level rate limiting based on source<>destination chain.
- Implement upgradability.
- Make all contracts have the same addresses on all EVM compatible chains.
- Require manual approver for certain thresholds (where a multisig of the issuer approves each transaction in that threshold).

## Extra

- Make the bridge work on Solana.

## Development

Use Foundry or Hardhat for development.

### Evaluation Criteria

Code quality, unit tests, documentation, and readme will be assessed.

### Useful Links
- https://github.com/foundry-rs/foundry
- https://hardhat.org/ 


Have fun coding! 🚀
