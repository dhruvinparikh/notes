## Deliverables

### Source Code
- tokenA - [MockaDAI.sol](./contracts/MockaDAI)
- tokenB - [MockcDAI.sol](./contracts/MockcDAI.sol)
- tokenC - [MockDAI.sol](./contracts/MockDAI.sol)
- Wrapper - [Stub.sol](./contracts/stub.sol)

### Deployed Address

#### Avalanche's Fuji testner

- [MockaDAI](./contracts/MockaDAI) : `0x8bD3317Ac7a8cF2441D4D2121CCed8Cc9D5b8881`
- [MockcDAI](./contracts/MockcDAI.sol) : `0x3FFBd96E742d02269Cc55931e1bbd0aEFd4D024F`
- [Stub](./contracts/stub.sol) : `0xC843262031a16957eca72D3cBcfad821851Df440`
- [MockDAI](./contracts/MockDAI.sol)(Deployed internally by Wrapper) : `0x13B05C598f9E22ea057A9a02aaf4d2AB4120E04F`
 

### Call sequence for Multitoken Wrapper
1. Deploy [MockaDAI()](./contracts/MockaDAI.sol) using Alice's account
2. Deploy [MockcDAI()](./contracts/MockcDAI.sol) using Bob's account
3. Deploy [Wrapper([MockaDAI,MockcDAI],"Mock DAI","mDAI")](./contracts/stub.sol) using Eve's account
4. Get the contract instance => `ABI = MockDAI`, `contractAddress = Wrapper.mockDAI()`
5. `MockDAI.balanceOf(Wrapper)` => `1000 mDAI`
6. `MockaDAI.approve(Wrapper,100 maDAI)` using Alice's account
7. `Wrapper.swap(MockaDAI, 100 maDAI)` using Alice's account
8. `MockDAI.balanceOf(Alice)` => `100 mDAI`
9. `MockcDAI.approve(Wrapper,50 mcDAI)` using Bob's account
10. `Wrapper.swap(MockcDAI, 50 mcDAI)` using Bob's account
11. `MockDAI.balanceOf(bob)` => `50 mDAI` 
12. `MockDAI.approve(Wrapper,50 mDAI)` using Alice's account
10. `Wrapper.unswap(MockcDAI, 50 mDAI)` using Alice's account
11. `MockDAI.balanceOf(Alice)` => `50 mDAI`
12. `MockcDAI.balanceOf(Alice)` => `50 mcDAI`

### Transfer 1000 of `maDAI` token to `0x808cE8deC9E10beD8d0892aCEEf9F1B8ec2F52Bd`
https://testnet.avascan.info/blockchain/c/tx/0x120071d287c5a44a746526bc76fac2e0974bb7bc0855bbed26305c9b11b04398

### Transfer 1000 of `mcDAI` token to `0x808cE8deC9E10beD8d0892aCEEf9F1B8ec2F52Bd`
https://testnet.avascan.info/blockchain/c/tx/0x89617ab16c5f097c742bea1150dbf1e547ee255af8c0f35338bfda0817228a42