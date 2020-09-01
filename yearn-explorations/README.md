# [yearn.finance](https://yearn.finance)

- [Explain how Zap and Earn work](#Explain-how-Zap-and-Earn-work)
- [Explain y tokens](#explain-y-tokens)
- [Explain y.curve.fi, y.busd.fi](#explain-ycurvefi-ybusdfi)
- [Explain how the interest rate is calculated, how Yearn determines where to deposit user funds and how interest is calculated.](#explain-how-the-interest-rate-is-calculated-how-Yearn-determines-where-to-deposit-user-funds-and-how-interest-is-calculated) 

## Explain how Zap and Earn work

### [Zaps](https://yearn.finance/zap)

#### What is a Zap?
- Zap allows users to convert supported tokens with just one contract interaction to reduce transaction costs
- Zaps were made by DefiZap which is now [Zapper.fi](https://zapper.fi) as a type of all in one defi routing service. 

#### Why use a Zap?
- "Zaps allow you get into a DeFi position in one transaction—it’s called zapping in." - [How to use Zaps guide](https://defitutorials.substack.com/p/how-to-use-defizap)
    - Note that this is an old article and [Zapper](https://zapper.fi) was formed as a result of DeFiSnap + DeFiZap coming together to create the ultimate hub for Decentralized Finance aka #DeFi. So some of the stuff in the article above is out of date, but you can still use Zaps on Zapper.fi

#### So what can I do with Zaps on yearn?
- With as zap you can take your DAI, for example, and get yCurve with it in one transaction. Normally, to turn DAI in to yCRV, you would have to go to earn, deposit DAI and receive yDAI, then go to [Curve.fi - Yearn pool](https://www.curve.fi/iearn/deposit) and deposit your yDAI and then you would get yCRV. This is alot to do so instead you can do it in one transaction!

#### That sounds awesome, what's the downside?
- Well, it does take a lot of gas and could be costly, even more so than doing it yourself manually, but if you have a big transaction and are in a rush it is a great method to get into a DeFi position or liquidity pool fast.

### [Earn](https://yearn.finance/earn)
- Yield aggregator for lending platforms that rebalances for highest yield during contract interaction.
- Deposit DAI, USDC, USDT, TUSD, or sUSD and it will auto lend to the highest lending rate on these platforms [Compound](https://compound.finance/), [Dydx](https://dydx.exchange/), or [Aave](https://app.aave.com/home) (Ddex and Fulcrum are currently disabled)
- Info on this can be found in the [Yearn Docs](https://docs.yearn.finance/yearn.finance/yearn)
- Profit switching lender to optimize lending yields (live)

## Explain y tokens

Mainnet address : [0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e](https://etherscan.io/address/0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e)


## Explain [y.curve.fi](https://y.curve.fi), [y.busd.fi](https://y.busd.fi)
## Explain how the interest rate is calculated, how Yearn determines where to deposit user funds and how interest is calculated.