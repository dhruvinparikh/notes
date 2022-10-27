//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// Import any library you like
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Inherit any classes you like
contract HypeCoin is ERC20{
    // Task 1, fill in code here.

    // Constructor that mints token to wallet that deploys the contract
    uint256 public constant TOTAL_SUPPLY = 1000000 * 1e18;

    uint256 public constant PRICE_PER_TOKEN = 0.01 ether;

    address public owner;

    constructor(string memory _name, string memory _symbol) ERC20(_name,_symbol) {
        owner = msg.sender;
      _mint(owner,TOTAL_SUPPLY);
    }

    function totalSupply() public pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    // buy function

    function buy(uint256 _amount) payable external {
      uint256 _requiredEth = _amount * PRICE_PER_TOKEN;

      require(msg.value == _requiredEth, "Not enough eth");

    _spendAllowance(owner, address(this), _amount*1e18);

      _transfer(owner,msg.sender,_amount*1e18);
    }

    // claim function

    function claim() external {
        require(msg.sender == owner,"not an owner");
        payable(msg.sender).transfer(address(this).balance);
    }
}

// checks 
// effect
// interaction