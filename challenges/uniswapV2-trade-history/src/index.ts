import { Command } from "commander";
import Etherscan from "etherscan-api";
import { getAddress } from "@ethersproject/address";
import { decodeLogs, addABI } from "abi-decoder";
import { BigNumber } from "@ethersproject/bignumber";
import { formatEther, formatUnits } from "@ethersproject/units";
import { ethers } from "ethers";
import { Contract } from "@ethersproject/contracts";
import uniswapv2RouterABI from "./abi/uniswapv2Router.json";
import erc20ABI from "./abi/erc20.json";
import uniswapv2pairABI from "./abi/uniswapv2pair.json";
import wethABI from "./abi/weth.json";
// import uniswapv2stakingrewards from "./abi/uniswapv2stakingRewards.json";
import fs from "fs";

const SWAP = "swapping coins";
const MINT = "adding liquidity";
const BURN = "removing liquidity";
const WETH = getAddress("0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2");
const UNISWAPV2_ROUTER = getAddress("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D");
// const TETHER_LIQUIDITY_MINING_POOL = getAddress("0x6C3e4cb2E96B01F4b866965A91ed4437839A121a");
// const USDC_MINING_POOL = getAddress("0x7FBa4B8Dc5E7616e59622806932DBea72537A56b");
// const DAI_MINING_POOL = getAddress("0xa1484C3aa22a66C62b77E0AE78E15258bd0cB711");
// const WBTC_MINING_POOL = getAddress("0xCA35e32e7926b96A9988f61d510E038108d8068e");
addABI(erc20ABI);
addABI(wethABI);
addABI(uniswapv2RouterABI);
addABI(uniswapv2pairABI);
// addABI(uniswapv2stakingrewards);

type txType = {
  blockNumber: number;
  timeStamp: number;
  hash: string;
  nonce: number;
  blockHash: string;
  transactionIndex: number;
  from: string;
  to: string;
  value: number;
  gas: number;
  gasPrice: number;
  isError: string;
  txreceipt_status: number;
  input: string;
  contractAddress: string;
  cumulativeGasUsed: number;
  gasUsed: number;
  confirmations: number;
};

type event = {
  name: string;
  type: string;
  value: string;
};

type logType = {
  name: string;
  events: event[];
  address: string;
};

function getTransactionType(logs: any) {
  if (logs.findIndex((ele: any) => ele.name == "Swap") != -1) {
    return SWAP;
  } else if (logs.findIndex((ele: any) => ele.name == "Mint") != -1) {
    return MINT;
  } else if (logs.findIndex((ele: any) => ele.name == "Burn") != -1) {
    return BURN;
  } else {
    return "undefined";
  }
}

async function getTransactedAssets(logs: logType[], testAddress: string, erc20: Contract, type: string, tx: txType) {
  const res = [];
  if (tx.value > 0) {
    const bigEth = BigNumber.from(tx.value);
    const feesInEth =
      type != MINT && type != BURN ? bigEth.mul(BigNumber.from(3)).div(BigNumber.from(1000)) : BigNumber.from(0);
    res.push({
      address: "0x",
      name: "Ethers",
      symbol: "ETH",
      amount: `- ${formatEther(bigEth)} ETH`,
      fees: `${formatEther(feesInEth)} ETH`,
      actual_amount: `${formatEther(bigEth.sub(feesInEth))} ETH`,
    });
  }

  for (const log of logs) {
    if (log.name === "Transfer") {
      const fromAddress = getAddress(log.events[0].value);
      const toAddress = getAddress(log.events[1].value);
      if (fromAddress == testAddress || toAddress == testAddress) {
        const instance = erc20.attach(log.address);
        const decimals = await instance.decimals();
        const symbol = await instance.symbol();
        const fees =
          type != MINT && type != BURN && fromAddress == testAddress
            ? BigNumber.from(log.events[2].value).mul(BigNumber.from(3)).div(BigNumber.from(1000))
            : BigNumber.from(0);
        const amount = BigNumber.from(log.events[2].value);
        res.push({
          address: log.address,
          name: await instance.name(),
          symbol,
          amount: `${fromAddress == testAddress ? "-" : "+"} ${formatUnits(amount, decimals)}`,
          fees: `${formatUnits(fees, decimals)} ${symbol}`,
          actual_amount: `${formatUnits(amount.sub(fees), decimals)} ${symbol}`,
        });
      }
    } else if (
      log.name === "Withdrawal" &&
      getAddress(log.events[0].value) == UNISWAPV2_ROUTER &&
      getAddress(log.address) == WETH
    ) {
      res.push({
        address: "0x",
        name: "Ethers",
        symbol: "ETH",
        amount: `+ ${formatEther(BigNumber.from(log.events[1].value))} ETH`,
        fees: `0 ETH`,
        actual_amount: `${formatEther(BigNumber.from(log.events[1].value))} ETH`,
      });
    }
  }
  return res;
}

function sleep(ms: number) {
  return new Promise(resolve => {
    setTimeout(resolve, ms);
  });
}

const program = new Command();
program.version("0.0.1");
program
  .command("prepare")
  .description(
    "Takes an Ethereum account address and generates JSON file of historical transactions execute on Ethereum",
  )
  .requiredOption("-a, --address <string>", "The Ethereum account address")
  .requiredOption("-k, --etherscan-api-key <string>", "Etherscan API key")
  .requiredOption("-l, --alchemy-api-key <string>", "Alchemy API key")
  .option("-n, --network <string>", "Name of the network. E.g. Mainnet, rinkeby, ropsten", "mainnet")
  .action(async command => {
    const provider = new ethers.providers.AlchemyProvider("homestead", command.alchemyApiKey);
    const erc20 = new ethers.Contract("0x6b175474e89094c44da98b954eedeac495271d0f", erc20ABI, provider);
    const api = Etherscan.init(command.etherscanApiKey);
    const testAddress = getAddress(command.address);
    let txlist = await api.account.txlist(testAddress, 1, "latest");
    if (txlist.status == 1 && txlist.message == "OK") {
      txlist = txlist.result.filter((tx: txType) => {
        const toAddress = getAddress(tx.to);
        if (
          toAddress == UNISWAPV2_ROUTER
          //    ||
          //   toAddress == TETHER_LIQUIDITY_MINING_POOL ||
          //   toAddress == USDC_MINING_POOL ||
          //   toAddress == DAI_MINING_POOL ||
          //   toAddress == WBTC_MINING_POOL
        ) {
          return true;
        }
        return false;
      });
      const transactions = [];
      for (const tx of txlist) {
        const txReceipt = await api.proxy.eth_getTransactionReceipt(tx.hash);
        await sleep(500);
        const decodedLogs = decodeLogs(txReceipt.result.logs);
        const success = tx.isError === "1" ? false : true;
        const type = getTransactionType(decodedLogs);
        transactions.push({
          exchange: "UniswapV2",
          account: testAddress,
          type,
          date: new Date(tx.timeStamp * 1000).toDateString(),
          time: new Date(tx.timeStamp * 1000).toTimeString(),
          assets: success ? await getTransactedAssets(decodedLogs, testAddress, erc20, type, tx) : [],
          transaction_fees: `${formatEther(BigNumber.from(tx.gasUsed).mul(BigNumber.from(tx.gasPrice)))} ETH`,
          id: tx.nonce,
          success,
        });
      }
      fs.writeFileSync("transactions.json", JSON.stringify(transactions));
    }
  });

program.parse(process.argv);
