//SPDX-License-Identifier: mit
pragma solidity >= 0.6.2 < 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockDAI is ERC20 {
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
        _mint(msg.sender, _totalSupply);
    }

    
}