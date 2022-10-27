Hype Coin
============================

A solidity problem set for Hypotenuse Labs' pair programming interview.

For this exercise, you will
- build your own ERC 20 (HypeCoin) and ERC 721 (HypeNFT) tokens.
- implement the stubbed mocha tests for HypeNFT and HypeCoin

There are 2 types of tasks, **implementation** and **discussion**. Try to work on a little bit of both.

There is a list of frequently encountered errors at the bottom of the README, there may be a solution to your error listed below.

# Setup

1. Install Metamask extension (https://metamask.io) for your browser.

2. Install dependencies and run the web app.
```bash
npm install
npm start
```

3. Open http://localhost:3000 to view it in your browser. The page will reload when you make changes. You may also see any lint errors in the console.

4. Run the blockchain locally. You will need `npx` to do so. If you don't have it installed, do `npm install -g npx`.
```bash
npm run node
```

5. Add a few wallets listed from running the local blockchain to Metamask.

### To compile the contracts, do
```bash
npm run compile
```

### To deploy the contracts, do
```bash
npm run deploy localhost
```

# Implementation Tasks
The tasks and requirements below are only guidelines, so feel free to take this in whatever direction you both find interesting or most practical!

Don't worry about finishing all the questions - that could take quite a while! What we're looking for is a good technical discussion, a little bit of code, and lots of collaboration with your partner.

## Task 1 - Implement Smart Contract for Hype Coin
Requirements:
- Hype Coin is an ERC 20 token with a total supply of 1 million tokens and 18 decimal places.
- When the contract is deployed, it should mint the total supply of tokens to the wallet that deployed the contract.
- Users should be able to call a function `buy` with an amount to buy Hype Coin tokens using ETH. Each Hype Coins (HC) costs 0.01 ETH. The function should do error checking then transfer the amount of HC token from the contract owner's wallet to the user's wallet. You should not mint new HC tokens.
- Add a function `claim` that allows the owner to claim ETH funds in the contract.

## Task 2 - Implement stubbed mocha tests for Hype Coin
Requirements:
- sets up storage vars
- transfers 5 tokens to the caller
- allows the contract owner to withdraw ETH funds

## Task 3 - Implement Smart Contract for Hype NFT
Requirements:
- Hype NFT is an ERC 721 token with no maximum supply.
- Users should be able to call a function `mint` with an amount to mint multiple Hype NFT tokens at once using ETH. 0.1 ETH = 1 Hype NFT. Minting starts at ID 1 and increment by 1 for each NFT minted. The function should do error checking then mint the next batch of available NFTs to the user's wallet. The function also immediately transfers the ETH value sent by the caller to the contract owner.
- Add a view function `getNextTokenId` that allows anyone to view the next available NFT ID to be minted.
- Add enumerable functionality (ex: list all of the NFT IDs owned by a particular wallet)

## Task 4 - Implement stubbed mocha tests for Hype NFT
Requirements:
- sets up storage vars
- mints 5 tokens for the caller, with tokenIds 1...5
- funds the contract owner's wallet with ETH on successful mints

# Discussion Tasks

Feel free to talk about them in any order. No implementation is needed.

## Task 5 - Add functionality to mint Hype NFT with Hype Coin
Discuss changes needed to add a function `mintWithHypeCoin` to the HypeNFT contract that allows users to mint a Hype NFT using 5 Hype Coins.

Things to consider:
- How can the contract make sure payment is received in Hype Coin?
- Are there additional function call(s) needed before calling `mintWithHypeCoin`?

## Task 6 - Re-entrancy attack, audit prep
Discuss what a re-entrancy attack on a smart contract looks like, and what are the general ways to protect against it.

If we were preparing for a technical audit of the smart contracts, what are some things we would do to prepare?

## Task 7 - Supporting meta-transactions (ie: gasless)
Suppose we didn't want our users to pay for gas when minting HypeNFT or buying HypeCoin. What EIP do we need to support, and what changes need to be made to the smart contract?

## Task 8 - Guess random number exploit
Discuss potential exploit to the guess a random number contract.

Go to `./contracts/GuessRandomNum.sol`, this is a contract that allows any user to call the `guess` function with a number. If the user calls it with a number equal to the "random" number, the user gets 1 ETH. How can this contract be exploited to guess the right number all the time?

## Task 9 - Add functionality to collect Hype Coin by holding Hype NFT
Discuss changes needed to add a function `collect` to the HypeNFT contract that allows users to collect Hype Coins based on the amount of time they held the Hype NFT.

Suppose each NFT held by the user earns 1 HC token per day. If the time held is less than 1 day then the user has not earned the token. The user calls `collect()` and x HC tokens are sent to their wallet.

Things to consider:
- User can have multiple NFTs
- User can transfer NFT to a different wallet
- How do you calculate how many HC tokens can be collected?
- What data structure would you use?
- What functions would you need to override to add additional logic?
- What error checking is needed?

## Task 10 - Guess password exploit
Discuss potential exploit to the guess password contract.

Go to `./contracts/GuessPassword.sol`, when this contract is deployed, the owner specifies a 256 bits number. This is stored in the contract as private data. Any user can call the `guess` function with a number. If the user calls it with a number equal to the secret number, the user gets 1 ETH. How can this contract be exploited to guess the right number on the first try?

# Frequently Encountered Errors
## Failed transaction, Nonce too high
This happens when you restart the local blockchain after the wallet has made some transactions. If you are getting transaction failed from metamask with message `nonce too high`, try resetting the wallet on metamask. Click on the icon at the top right corner, then Settings > Advanced > Reset Account button.
