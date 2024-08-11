# [curve.finance](https://curve.finance)

- [Explain how different pools work.](#explain-how-different-pools-work)
- [Explain how APY is calculated for each pool.](#explain-how-apy-is-calculated-for-each-pool)
- [Create a simple UI that either connects to Defi Wallet like MetaMask (preferred) or Wallet Address is hard-coded.](#create-a-simple-ui-that-either-connects-to-defi-wallet-like-metamask-or-wallet-address-is-hard-coded)
- [The UI lets user deposit 1 Dai (or any currency) into Curve pool and withdraw same token.](#the-ui-lets-user-deposit-1-dai-or-any-currency-into-curve-pool-and-withdraw-same-token)
- [Explain how profit was calculated](#explain-how-profit-was-calculated)

## Explain how different pools work

- Currently, there are 7 Curve pools: Compound, PAX, Y, BUSD, sUSD, ren, and sBTC which support a swaps for wide variety of stablecoins and assets. 
  - lending protocols
    - Compound
    - PAX 
    - Y
    - BUSD
  - tokenized Bitcoin pools
    - ren
    - sBTC

## Explain how APY is calculated for each pool

- APR stands for Annual Percentage rate

## Create a simple UI that either connects to DeFi Wallet like MetaMask or Wallet address is hard-coded
## The UI lets user deposit 1 DAI (or any currency) into Curve pool and withdraw same token
## Explain how profit was calculated

### AMM math
```js
// The AMM math works in the form of the ratio of two tokens
// The ratio of tokens is calculated through an equation like x * y = k (constant)

// Main aim of AMM is to supply equal amount of quantities to each tokens

// if we supply equal amount of ETH and DAI say 1000 quantity  and  say // 1 ETH = $100 and 1 DAI = $1, then
// ETH         DAI
// $100        $1
//  X     x    Y       =      k
// 10     x    1000    =    10000
// price of ETH = y/x = 1000/10 = 100
// price of DAI = x/y = 10/1000 = 0.01
// When someone will trade, they will send some quantity of A token and 
// receive another B token from the pool.

// if someone wants to buy ETH from the pool => it means giving DAI to 
// pool and getting ETH in return. Remember the total supply of ETH is 
// $10 and DAI is $1000. DAI will get added to total supply and 1 ETH 
// will get subtracted from  total supply
// (10-1)  x   (1000 + X)  = 10000
// Solving the above equation yields in  x ~ 111.11 
// This happened because the ratio of ETH to DAI changed. Also this is 
// not the real price which means somebody would advantage and bring the 
// price back to what it should be. 

// substituting value of x in the above gives 
// 9  x 1111.11 ~ 10000 (9999.99)
// For e.g. say the price is still $100 on coinbase, but price here is 
// $111.11 , so someone will get the ETH from coinbase and sell it back 
// to AMM and make $11 profit.
// (9+1) x (1111.11 - x) = 100000 yields x ~ 111 (111.11)
// Thus the equation with which we started 10 x 1000 = 10000 satisfies

// Summarizing the above the explanation
// Alice bought bought ETH by sending DAIs that changes the ratio.
// Bob realized this is incorrect price and hence got ETH from coinbase 
// and sold it back to pool and made $11 profit and eventually it bought 
// the price back to its original.
// AMM works on a/b or arbitraging.So by finding the profit 
// opportunities , it will bring the price back to original.
```

![](./assets/images/curve-graph.svg)

```js
// Order Book Depth
// if the expression for the pool is 10 x 1000 = 10000. Sending 1 ETH to 
// the pool means the price of pool is changed by 10%.
// if the expression for the pool is 1000 x 100000 = 100000000. Sending 
// 1 ETH to the pool means the price of pool is changed by 0.1% (< 1%). 
// That what is order book depth. Deeper the order book, lesser the 
// price change as you buy larger quantity of tokens. This makes AMM 
// powerful because all we need to do is give two quantity of tokens to 
// the smart contract. It will inturn set correct price and make sure 
// that the we can consistently make money by providing this liquidity.

// Each trade on AMM comes with a fee usually in range of 0.1% to 0.3%. 
// So everytime we buy and take tokens from this curve we will be paying 
// little fee. So the liquidity provider gets incentivised by giving 
// little bit of ETH and little bit of DAI. 

// That is what we call market maker.

// In a nutshell
// We have traditional orderbooks are constant negotiation between buyers and sellers.
// The problem with order book is constant update to smart contract which is slow and expensive.
// AMM has no orderbooks. The smart contract calculates price-ratio. 
// It calculates the price by determining the ratio of two tokens using equation X x Y = k where one side of equation will have chaneg in the value and the solving the equation gives us new price of ETH. So shift in the price opens the door for arbitrages to restore the price by selling back to the pool (reversing the trade). Calculation's explanation is shown above. 
// Deeper the orderbook, less change in the price.
// If we will provide X and/or Y to the pool, we will earn the fee as we are providing services to other users.
```

## Explain CRV

- CRV is the governance token for the curve finance.