//SPDX-License-Identifier: mit
pragma solidity >= 0.6.2 < 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MockDAI} from "./MockDAI.sol"; 

contract Wrapper {

    mapping(address => bool) public inputTokens;
    MockDAI public mockDAI;

    constructor(IERC20[] memory _inputTokens, string memory _name, string memory symbol) {
        for(uint8 _i = 0 ; _i < uint8(_inputTokens.length); _i++) {
            inputTokens[address(_inputTokens[_i])]=true;
        }
        mockDAI = new MockDAI(_name,symbol,18,1000 * (10**18));
    }


    /**
     * Convert an amount of input token_ to an equivalent amount of the output token
     *
     * @param token_ address of token to swap
     * @param amount amount of token to swap/receive
     */
    function swap(address token_, uint amount) external {
        require(inputTokens[token_],"Wrapper:token not listed");
        require(IERC20(token_).allowance(msg.sender,address(this)) >= amount,"token_ allowance is too low");
        require(mockDAI.balanceOf(address(this)) >= amount,"output token balance is not enough");
        IERC20(token_).transferFrom(msg.sender, address(this), amount);
        mockDAI.transfer(msg.sender, amount);
    }

    /**
     * Convert an amount of the output token to an equivalent amount of input token_
     *
     * @param token_ address of token to receive
     * @param amount amount of token to swap/receive
     */
    function unswap(address token_, uint amount) external {
        require(inputTokens[token_],"Wrapper:token not listed");
        require(mockDAI.allowance(msg.sender,address(this)) >= amount,"token_ allowance is too low");
        mockDAI.transferFrom(msg.sender, address(this), amount);
        IERC20(token_).transfer(msg.sender, amount);
    }
}
