// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // HypeCoin ERC 20
  const HypeCoin = await hre.ethers.getContractFactory("HypeCoin");
  const hypeCoin = await HypeCoin.deploy();

  await hypeCoin.deployed();

  console.log("HypeCoin deployed to:", hypeCoin.address);
  console.log("HypeCoin owner wallet:", hypeCoin.deployTransaction.from);

  // HypeNFT ERC 721
  const HypeNFT = await hre.ethers.getContractFactory("HypeNFT");
  const hypeNFT = await HypeNFT.deploy();

  await hypeNFT.deployed();

  console.log("HypeNFT deployed to:", hypeNFT.address);
  console.log("HypeNFT owner wallet:", hypeNFT.deployTransaction.from);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
