const { expect } = require('chai');
const { BigNumber } = require('ethers');
const { parseEther } = require('ethers/lib/utils');
const { ethers } = require('hardhat');

describe('HypeCoin', () => {
  let nft;
  let deployer, user;
  let contractInstance;

  beforeEach(async () => {
    deployer = (await ethers.getSigners())[0]
    user  = (await ethers.getSigners())[1]
    const contractFactory = await ethers.getContractFactory("HypeCoin")
    contractInstance = await contractFactory.deploy("HypeCoin","HYP")
  });

  it('sets up storage vars', async () => {
    expect(await contractInstance.TOTAL_SUPPLY()).eq(parseEther("1000000"))
    expect(await contractInstance.owner()).eq(deployer.address)
    expect(await contractInstance.balanceOf(deployer.address)).eq(parseEther("1000000"))
  });

  it('transfers 5 tokens to the caller', async () => {
    const tx = await contractInstance.connect(deployer).approve(contractInstance.address,parseEther("1000000"))
    await tx.wait(1) 
    const totalCost = BigNumber.from("5").mul(await contractInstance.PRICE_PER_TOKEN())
    const tx1 = await contractInstance.connect(user).buy(5,{value:totalCost})
    await tx1.wait()
    expect(await contractInstance.balanceOf(user.address)).eq(parseEther("5"))
  });

  it('allows the contract owner to withdraw ETH funds', async () => {
  });
});
