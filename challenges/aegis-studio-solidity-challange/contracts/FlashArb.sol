// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./aave/interfaces/ILendingPool.sol";

// References
// https://github.com/aave/flashloan-box
// https://uniswap.org/docs/v2/smart-contracts/router02/
// https://docs.aave.com/developers/deployed-contracts/deployed-contracts
// https://uniswap.org/docs/v2/smart-contracts/router02/
// https://uniswap.org/docs/v2/smart-contracts/factory/
// https://dev.sushi.com/sushiswap/contracts#sushiv-2-router02
// https://dev.sushi.com/sushiswap/contracts#sushiv-2-factory
// https://github.com/aave/protocol-v2/blob/master/contracts/flashloan/interfaces/IFlashLoanReceiver.sol

////////////////////////////
/// GENERAL INSTRUCTIONS ///
////////////////////////////

// 1. AT THE TOP OF EACH CONTRACT FILE, PLEASE LIST GITHUB LINKS TO ANY AND ALL REPOS YOU BORROW FROM THAT YOU DO NOT EXPLICITLY IMPORT FROM ETC.
// 2. PLEASE WRITE AS MUCH OR AS LITTLE CODE AS YOU THINK IS NEEDED TO COMPLETE THE TASK
// 3. LIBRARIES AND UTILITY CONTRACTS (SUCH AS THOSE FROM OPENZEPPELIN) ARE FAIR GAME

//////////////////////////////
/// CHALLENGE INSTRUCTIONS ///
//////////////////////////////

// 1. Initiates a flash loan from Aave V2
// 2. Uses the loaned tokens to perform an arbitrage trade between UniswapV2 and Sushiswap
// 3. Write as much code as you deem necessary to complete the task
// 4. Bonus: Optimize dex arbitrage trade for profit
// 5. Please feel free to use any code/packages from the following Github Organizations and Docs:
//      Aave Org: https://github.com/aave
//      Aave Docs: https://docs.aave.com/developers/
//      Uniswap Org: https://github.com/uniswap
//      UniswapV2 Docs: https://uniswap.org/docs/v2/
//      Sushiswap Org: https://github.com/sushiswap
//      Sushiswap Docs: https://dev.sushi.com/

contract FlashArb {
    /// @dev directive to attach the SafeMath to uint256
    using SafeMath for uint256;
    /// @dev assigning the ERC20 WETH token contract address to be used as flash asset to borrow from aave
    IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    /// @dev assigning contract address of aave lending pool address provider
    ILendingPoolAddressesProvider constant aaveAddressProvider =
        ILendingPoolAddressesProvider(
            0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5
        );
    /// @dev assigning the contract address of th uniswap's version 2.0, router 2.0
    IUniswapV2Router02 constant uniswapV2Router02 =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    /// @dev assigning the contract address of th uniswap's version 2.0, factory
    IUniswapV2Factory constant uniswapV2Factory =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    /// @dev assigning the contract address of th sushiswap's version 2.0, router 2.0
    IUniswapV2Router02 constant sushiswapV2Router02 =
        IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    /// @dev assigning the contract address of th sushiswap's version 2.0, factory
    IUniswapV2Factory constant sushiswapV2Factory =
        IUniswapV2Factory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);

    /// @dev the token that needs to be the swapped from DEX 
    address outputToken;
    /// @dev the amount of the borrowed token to used for swapping from DEX  
    uint256 tradeAmount;

    /// @dev trigger the flash loan from aave lending pool 
    /// @param  _borrowAssetAmount amount in of WETH tokens to flash loan from aave
    /// @param _outputToken to swap against the trade amount of WETH amount
    /// @param _tradeAmount in WETH token to be deposited into DEX 
    function flashloanAndArbitrage(
        uint256 _borrowAssetAmount,
        address _outputToken,
        uint256 _tradeAmount
    ) external {
        // whether the pair exists on uniswap V2 factory
        require(
            uniswapV2Factory.getPair(address(WETH), _outputToken) != address(0),
            "FlashArb: uniswapv2 pair does not exist"
        );
        // whether the pair exists on sushiswap V2 factory
        require(
            sushiswapV2Factory.getPair(address(WETH), _outputToken) !=
                address(0),
            "FlashArb: sushiswapv2 pair does not exist"
        );
        require(_outputToken != address(WETH), "borrow asset and output token cannot be same");
        address[] memory assets = new address[](2);
        assets[0] = address(WETH);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _borrowAssetAmount;
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0; // performs a flash loan without incurring debt
        outputToken = _outputToken;
        tradeAmount = _tradeAmount;
        // perform a flash loan from aave lending pool
        ILendingPool(aaveAddressProvider.getLendingPool()).flashLoan(
            address(this),
            assets,
            amounts,
            modes,
            address(0),
            "",
            uint16(0)
        );
        // send remaining amount back to caller
        WETH.transfer(msg.sender, WETH.balanceOf(address(this)));
        IERC20(_outputToken).transfer(
            msg.sender,
            IERC20(_outputToken).balanceOf(address(this))
        );
    }

    /// @dev This function is called after your contract has received the flash loaned amount
    /// @param assets that are borrowed from aave
    /// @param amounts that are borrowed
    /// @param premiums are the fees required to pay extra over borrowed assets amount
    /// @return return true after repaying the borrowed amount
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address,
        bytes calldata
    ) external returns (bool) {
        // The contract will now has the funds requested.
        // get estimated outputToken price from uniswap
        uint256 _maxOutputTokenAmountFromUniswap =
            getMaxOutputTokenAmount(uniswapV2Router02, tradeAmount, outputToken)[0];
        // get estimated outputToken price from sushiswap
        uint256 _maxOutputTokenAmountFromSushiswap =
            getMaxOutputTokenAmount(sushiswapV2Router02, tradeAmount, outputToken)[0];
        // 
        if (
            _maxOutputTokenAmountFromUniswap >
            _maxOutputTokenAmountFromSushiswap
        ) { 
            // have the uniswapV2Router02 as a spender for recently 
            // borrowed WETH token
            WETH.approve(address(uniswapV2Router02), tradeAmount);
            // swap the borrowed token with output token from uniswap
            // as the estimated amount from uniswap is more than sushiswap
            uniswapV2Router02.swapTokensForExactTokens(
                _maxOutputTokenAmountFromUniswap,
                tradeAmount,
                getWETHToTokenPath(outputToken),
                address(this),
                10 days
            );
            // have the sushiswapV2Router02 as a spender for recently 
            // swapped outputToken
            IERC20(outputToken).approve(
                address(sushiswapV2Router02),
                IERC20(outputToken).balanceOf(address(this))
            );
            // swap the output token with borrowed token from sushiswap
            sushiswapV2Router02.swapExactTokensForTokens(
                IERC20(outputToken).balanceOf(address(this)),
                getMaxWETHTokenAmount(sushiswapV2Router02, IERC20(outputToken).balanceOf(address(this)), outputToken)[0],
                getTokenToWETHPath(outputToken),
                address(this),
                10 days
            );
        } else {
            // have the sushiswapV2Router02 as a spender for recently 
            // borrowed WETH token
            WETH.approve(address(sushiswapV2Router02), tradeAmount);
            // swap the borrowed token with output token from sushiswap
            // as the estimated amount from sushiswap is more than uniswap
            sushiswapV2Router02.swapTokensForExactTokens(
                _maxOutputTokenAmountFromSushiswap,
                tradeAmount,
                getWETHToTokenPath(outputToken),
                address(this),
                10 days
            );
            // have the uniswapV2Router02 as a spender for recently 
            // swapped outputToken
            IERC20(outputToken).approve(
                address(uniswapV2Router02),
                IERC20(outputToken).balanceOf(address(this))
            );
            // swap the output token with borrowed token from uniswap
            uniswapV2Router02.swapExactTokensForTokens(
                IERC20(outputToken).balanceOf(address(this)),
                getMaxWETHTokenAmount(uniswapV2Router02, IERC20(outputToken).balanceOf(address(this)), outputToken)[0],
                getTokenToWETHPath(outputToken),
                address(this),
                10 days
            );
        }
        // repay the borrowToken
        WETH.approve(
            aaveAddressProvider.getLendingPool(),
            amounts[0].add(premiums[0])
        );
        return true;
    }

    /// @dev create a direct pair of WETH with _token
    /// @param _token to pair the path with WETH token
    /// @return the array of the WETH to token path 
    function getWETHToTokenPath(address _token) private view returns (address[] memory) {
        // note : this function is a workaround for stack too deep error in executeOperation()
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = _token;
        return path;
    }

    /// @dev create a direct pair of _token with WETH  
    /// @param create _token to WETH path
    /// @return the array of _token and WETH tokens path
    function getTokenToWETHPath(address _token) private view returns (address[] memory) {
        // note : this function is a workaround for stack too deep error in executeOperation()
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = address(WETH);
        return path;
    }

    /// @dev given an _tokenAmount of an _token asset and WETH, returns chained amount of assets
    /// @param the address of _iDEXRouter address
    /// @param the amount to _tokenAmount to be supplied
    /// @param the address of the _token 
    /// @return returns the chained amount calculations on _token paired with WETH 
    function getMaxOutputTokenAmount(IUniswapV2Router02 _iDEXRouter, uint _tokenAmount, address _token) public view returns (uint[] memory) {
        // note : this function is a workaround for stack too deep error in executeOperation()
        return _iDEXRouter.getAmountsOut(_tokenAmount, getWETHToTokenPath(_token));
    }

    /// @dev given an _tokenAmount of an _token asset and WETH, returns chained amount of assets
    /// @param the address of _iDEXRouter address
    /// @param the amount to _tokenAmount of output token
    /// @param the address of the _token 
    /// @return returns the chained amount calculations on WETH token paired with _token
    function getMaxWETHTokenAmount(IUniswapV2Router02 _iDEXRouter, uint _tokenAmount, address _token) public view returns (uint[] memory) {
        // note : this function is a workaround for stack too deep error in executeOperation()
        return _iDEXRouter.getAmountsOut(_tokenAmount, getTokenToWETHPath(_token));
    }
}
