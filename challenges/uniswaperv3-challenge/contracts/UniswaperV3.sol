// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

interface IWETH9 is IERC20 {
    function deposit() external payable;
}

contract UniswaperV3 is ERC20 {
    using SafeMath for uint256;

    string private TOKEN_NAME = "Mock DAI";
    string private TOKEN_SYMBOL = "mDAI";

    uint8 private constant TOKEN_DECIMALS = 18;
    uint256 private constant TOTAL_SUPPLY = type(uint256).max / 2;

    IWETH9 public weth9 = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IUniswapV3Factory public uniswapV3Factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    INonfungiblePositionManager public nonFungiblePositionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    uint24 public constant LOW = 500;
    uint24 public constant MEDIUM = 3000;
    uint24 public constant HIGH = 10000;

    IUniswapV3Pool public currentPool;

    constructor() payable ERC20(TOKEN_NAME, TOKEN_SYMBOL) {
        _setupDecimals(TOKEN_DECIMALS);
        _mint(address(this), TOTAL_SUPPLY);
        weth9.deposit{ value: msg.value }();
        weth9.approve(address(nonFungiblePositionManager), uint256(-1));
        approve(address(nonFungiblePositionManager), uint256(-1));
    }

    function createAndInitializeV3() external {
        currentPool = IUniswapV3Pool(uniswapV3Factory.createPool(address(weth9), address(this), MEDIUM));
        currentPool.initialize(uint160(2**96));
        weth9.approve(address(currentPool), uint256(-1));
        approve(address(currentPool), uint256(-1));
    }

    function addInitialLiquidityV3(uint128 _initialLiquidity) external {
        (int24 _currentLowerTick, int24 _currentUpperTick) = (-887220, 887220);
        IUniswapV3Pool _currentPool = currentPool;

        _currentPool.mint(
            address(this),
            _currentLowerTick,
            _currentUpperTick,
            _initialLiquidity,
            abi.encode(address(this))
        );
    }

    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external {
        require(msg.sender == address(currentPool));

        address sender = abi.decode(data, (address));

        require(sender == address(this), "!this");

        if (amount0Owed > 0) {
            _transfer(address(this), msg.sender, amount0Owed);
        }
        if (amount1Owed > 0) {
            weth9.transfer(msg.sender, amount1Owed);
        }
    }

    function getERC20Balance(address _erc20Token, address _holder) public view returns (uint256) {
        return IERC20(_erc20Token).balanceOf(_holder);
    }
}
