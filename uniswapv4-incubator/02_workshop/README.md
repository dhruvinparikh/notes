# Workshop 1
Course Introduction, Tecnical Introduction, Ticks & Q64.96 Sqrt Price

* Uniswap was originally named as Uni-peg
* Alan Lu -> Martin Koppelman -> Vitalik Buterin -> Hayden Adams
* Worth reading Vitalik's Post : https://vitalik.eth.limo/general/2017/06/22/marketmakers.html
* UniswapV1 -> Direct Swap Path
* UniswapV2 -> Custom Router Path
* UniswapV3 -> Concentrated Liquidity. Liquidity can be injected for a particular Swap fee.

## Use Cases
* Ordebooks
* Custom Curves
* Reducing toxic MEV
* ... [TODO]

## Q&A

* **Uniswapv4 still infinite price pool right? but concentrated?**

```
They are not inifinite price pool technically. They have starting point and ending point unlike V2
```

* **Can you suggest a website that allows to quantify the usage of V2 and V3? From my experience most of the volume happen on V2, but I might be biased**

```
defilama, dune

https://dune.com/salva/uniswap-tvl
```

* **If I am LPing into UniV3, what is the best way to decide what fee tier should be selected?**
```
you can simulate on historical data.

Or assume some model of price movwement and simulate it.

I think there are websites that do it
```

* **Ok quick question: now people are saying that Uniswap V1 is shitty because we always required to swap to ETH but even now, we know in order to get the best price, it’s better to swap to WETH as intermediary…so what’s the final agenda with this?**
```
This is because how liquidity is spread, not by protocol design tho

why would it be better to swap with intermediary? often its possible to swap without intermediary when using V2/V3 right?

generally if you compare the output as number of tokens, you’ll get the best prices when using WETH as intermediary because in most causes, you’ll have more liquidity with WETH/USDT

solution to this is protocols providing huge liq, not a change in protocol design. -> no solution to this 😄

```


* **UniV4 in nutshell**

```
https://www.linkedin.com/posts/choudharyakshit_ethereum-defi-uniswap-activity-7074401959377518593-dNbG
```

* **How is Uniswap going to manage freaking moving the whole current asset list from separate pools into one single contract?**

```
Manual. V2 -> V3
```

## Technical Introduction
* High level arch of V4
* ERC6909 - Flash Accounting
