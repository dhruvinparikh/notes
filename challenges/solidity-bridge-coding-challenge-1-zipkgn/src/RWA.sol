// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "solmate/tokens/ERC20.sol";
import {AccessControlDefaultAdminRules} from "openzeppelin-contracts/contracts/access/AccessControlDefaultAdminRules.sol";

contract RWA is ERC20, AccessControlDefaultAdminRules {
    // Roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _admin,
        uint48 _initialDelay
    )
        AccessControlDefaultAdminRules(_initialDelay, _admin)
        ERC20(_name, _symbol,_decimals)
    {
    }


    function mint(address _to, uint256 _amount) external onlyRole(MINTER_ROLE) {
        _mint(_to, _amount);
    }

    function burn(address _to, uint256 _amount) external onlyRole(BURNER_ROLE) {
        _burn(_to, _amount);
    }
}
