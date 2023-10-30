import dotenv from "dotenv"
import { createWalletClient, http } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import { goerli,polygonMumbai } from 'viem/chains'

dotenv.config()

async function main() {
    const account = privateKeyToAccount(process.env.WALLET_PRIVATE_KEY as `0x${string}`);
    const deterministicDeployerFactory = "0x4e59b44847b379578588920ca78fbf26c0b4956c"
    
    const goerliClient = createWalletClient({ 
      account, 
      chain: goerli,
      transport: http()
    })

    const polygonMumbaiClient = createWalletClient({ 
        account, 
        chain: polygonMumbai,
        transport: http()
      })

    // contract: pragma solidity 0.5.8; contract Apple {function banana() external pure returns (uint8) {return 42;}}
    const BYTECODE="6080604052348015600f57600080fd5b5060848061001e6000396000f3fe6080604052348015600f57600080fd5b506004361060285760003560e01c8063c3cafc6f14602d575b600080fd5b6033604f565b604051808260ff1660ff16815260200191505060405180910390f35b6000602a90509056fea165627a7a72305820ab7651cb86b8c1487590004c2444f26ae30077a6b96c6bc62dda37f1328539250029"
    
    const goerliHash = await goerliClient.sendTransaction({
      account, 
      to: deterministicDeployerFactory,
      data:`0x0000000000000000000000000000000000000000000000000000000000000000${BYTECODE}`
    })

    console.log("goerliHash ",goerliHash)

    const polygonMumbaiHash = await polygonMumbaiClient.sendTransaction({
        account, 
        to: deterministicDeployerFactory,
        data:`0x0000000000000000000000000000000000000000000000000000000000000000${BYTECODE}`
      })

    console.log("polygonMumbaiHash ",polygonMumbaiHash)
}

main()