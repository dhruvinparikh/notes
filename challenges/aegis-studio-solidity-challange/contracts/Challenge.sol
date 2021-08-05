// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// References
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L26
// https://etherscan.io/tx/0x23af5f011ffd934e25f3714673081911364940e41d5da74f0d46e2b63a4c89ba
// https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol#L18
// https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol#L11

////////////////////////////////////
/// DO NOT USE IN PRODUCTION!!! ///
///////////////////////////////////

////////////////////////////
/// GENERAL INSTRUCTIONS ///
////////////////////////////

// 1. AT THE TOP OF EACH CONTRACT FILE, PLEASE LIST GITHUB LINKS TO ANY AND ALL REPOS YOU BORROW FROM THAT YOU DO NOT EXPLICITLY IMPORT FROM ETC.
// 2. PLEASE WRITE AS MUCH OR AS LITTLE CODE AS YOU THINK IS NEEDED TO COMPLETE THE TASK
// 3. LIBRARIES AND UTILITY CONTRACTS (SUCH AS THOSE FROM OPENZEPPELIN) ARE FAIR GAME

//////////////////////////////
/// CHALLENGE INSTRUCTIONS ///
//////////////////////////////

// 1. Fill in the contract's functions so that the unit tests pass in tests/Challenge.spec.ts
// 2. Please be overly explicit with your code comments
// 3. Since unit tests are prewritten, please do not rename functions or variables

contract Challenge {
    // The storage slot of Challenge contract should match
    // with that of the Incrementor contract

    uint256 public x;
    uint256 public y;
    uint256 public z;

    /// @dev delegate incrementX to the Incrementor contract below
    /// @param inc address to delegate increment call to
    function incrementX(address inc) external {
        // the delegate call to incrementX() will x
        (bool success,) = inc.delegatecall(abi.encodeWithSignature("incrementX()"));
        require(success);
    }

    /// @dev delegate incrementY to the Incrementor contract below
    /// @param inc address to delegate increment call to
    function incrementY(address inc) external {
        // the delegate call to incrementY() will y
        (bool success,) = inc.delegatecall(abi.encodeWithSignature("incrementY()"));
        require(success);
    }

    /// @dev delegate incrementZ to the Incrementor contract below
    /// @param inc address to delegate increment call to
    function incrementZ(address inc) external {
        // the delegate call to incrementZ() will z
        (bool success,) = inc.delegatecall(abi.encodeWithSignature("incrementZ()"));
        require(success);
    }

    /// @dev determines if argument account is a contract or not
    /// @param account address to evaluate
    /// @return bool if account is contract or not
    function isContract(address account) external view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // retrieve the size of the code, this needs assembly
            size := extcodesize(account)
        }
        return size > 0;
    }

    /// @dev converts address to uint256
    /// @param account address to convert
    /// @return uint256
    function addressToUint256(address account) external pure returns (uint256) {
        // address cannot be directed converted to uint256
        // because address is 20 bytes and uint256 is 32 bytes long
        // however address can be converted into uint160 both being
        // 20 bytes long. Finally, a uint160 type value can be 
        // conveniently converted into uint256 type
        return uint256(uint160(account));
    }

    /// @dev converts uint256 to address
    /// @param num uint256 number to convert
    /// @return address
    function uint256ToAddress(uint256 num) external pure returns (address) {
        // uint256 cannot be directed converted to address
        // because address is 20 bytes and uint256 is 32 bytes long
        // however uint256 can be conveniently converted into uint160. 
        // Finally, a uint160 type value can be conveniently converted 
        // into address type as both being 20 bytes long
        return address(uint160(num));
    }

    /// @dev calculates the CREATE2 address for a pair without making any external calls
    /// @param token0 address of first token in pair
    /// @param token1 address of second token in pair
    /// @return address of pair
    function getUniswapV2PairAddress(address token0, address token1)
        external
        pure
        returns (address)
    {
        // the uniswapV2 factory contract address which creates token pair contracts
        address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        (address tokenA, address tokenB) = sortTokens(token0, token1);
        address pair = address(uint160(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(tokenA, tokenB)),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                    )
                )
            ))
        );
        return pair;
    }

    /// @dev sorts token addresses
    /// @param tokenA address of first token in pair
    /// @param tokenB address of second token in pair
    /// @return token0 and token1
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }
}

contract Incrementor {
    uint256 public x;
    uint256 public y;
    uint256 public z;

    function incrementX() external {
        x++;
    }

    function incrementY() external {
        y++;
    }

    function incrementZ() external {
        z++;
    }
}
