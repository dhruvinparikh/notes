import { Fixture } from 'ethereum-waffle'
import { ethers } from 'hardhat'
import { constants } from 'ethers'
import {
  UniswaperV3,
} from '../../typechain'

const completeFixture: Fixture<{
    uniswaperv3:UniswaperV3
}> = async () => {

  const uniswaperV3Factory = await ethers.getContractFactory("UniswaperV3");
  const uniswaperv3 = await uniswaperV3Factory.deploy({value:constants.WeiPerEther.mul(1000)});

  return {
    uniswaperv3
  }
}

export default completeFixture