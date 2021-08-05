import { waffle, ethers } from 'hardhat'
import { Fixture } from 'ethereum-waffle'
import {UniswaperV3} from "../typechain";
import { expect } from 'chai';
import completeFixture from "./shared/completeFixture"
import { computePoolAddress } from './shared/computePoolAddress'


describe('UniswaperV3', () => {
  const wallets = waffle.provider.getWallets()
  const [wallet, other] = wallets

  const uniswaperV3Fixture: Fixture<{
    uniswaperv3:UniswaperV3
  }> = async (wallets, provider) => {
    const { uniswaperv3 } = await completeFixture(wallets,provider)

    return {
      uniswaperv3
    }
  }

  let uniswaperv3:UniswaperV3
  let loadFixture: ReturnType<typeof waffle.createFixtureLoader>

  before('create fixture loader and load fixture', async () => {
    loadFixture = waffle.createFixtureLoader(wallets)
    ;({ uniswaperv3 } = await loadFixture(uniswaperV3Fixture))
  })

  it("symbol and name",async () => {
    expect(await uniswaperv3.name()).to.equal("Mock DAI")
    expect(await uniswaperv3.symbol()).to.equal("mDAI")
  })

  it("pool pair address", async () => {
    await uniswaperv3.createAndInitializeV3();
    const expectedAddress = computePoolAddress(
      await uniswaperv3.uniswapV3Factory(),
      [uniswaperv3.address, await uniswaperv3.weth9()],
      await uniswaperv3.MEDIUM()
    )
    expect(await uniswaperv3.currentPool()).to.equal(expectedAddress)
  })

  it("add liquidity", async () => {
    const pool = await uniswaperv3.currentPool();
    await uniswaperv3.addInitialLiquidityV3("1000");
    expect(await uniswaperv3.balanceOf(pool)).to.equal('1000');
    expect(await uniswaperv3.getERC20Balance(await uniswaperv3.weth9(),pool)).to.equal('1000');
  })
})