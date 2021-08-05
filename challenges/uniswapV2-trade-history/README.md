# DeFi Technical Interview

We would like you to create a utility which will consume and output user’s **Uniswap V2** transactions in a human-readable format given their public ETH address. For this task, you are welcome to use any technology / tech-stack / tool that will produce accurate results.

- **_We suggest using a third-party API such as [BlockSet](https://blockset.com/docs/api/v1/transactions/list) or [Etherscan](https://etherscan.io/apis#transactions) to retrieve blockchain transactions_**

A command-line / file export is sufficient for the program’s output, we are only concerned with the reliability and accuracy of the results.

### Setup:

- Fork this repository

### Inputs:

Single public ETH address:

- **Test Address:** `0x299f770d90334c11f6ae65d770a7ce733f1154d7`

### Requirements:

- All of the wallet’s Uniswap V2 transactions will be retrieved from the ETH mainnet and outputted in a human-readable format.
- The output should classify each transaction type:
  - Adding Liquidity
  - Removing Liquidity
  - Swapping Coins
- Output should contain necessary accounting data for each transaction:
  - Transaction type
  - Assets transacted
    - ERC-20 Token address of tokens involved
  - Amounts transacted
  - **Transaction fees (gas & protocol fees)**
  - Transaction Ids
- The program should consider edge cases involved with each transaction such as failures
- The program should be created with extensibility in mind:
  - If we wanted, how could we extend this program to also read in all ETH transfers to and from the given wallet address?
  - If we wanted, how could this program handle importing and classifying transactions from other DeFi protocols?

## What we are looking for:

After the integration is wrapped up, our team will be looking at the following items in order to evaluate the technical interview:

- How well were the requirements followed?
- Correctness of the integration. Are there any logical errors or missing edge cases handled?
- How extensible was this implementation if we wanted to expand it to support all ETH transactions in the future?

## Submitting

Once you have completed implementing this task, open a pull request and send an email to lucas@cryptotrader.tax

## Testing Instructions

- `yarn`
- `yarn build`
- `node ./dist/index.js prepare --address 0x299f770d90334c11f6ae65d770a7ce733f1154d7 -k <etherscan-api-key> -l <alchemy-api-key>`
