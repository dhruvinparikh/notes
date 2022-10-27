//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// Task 8
contract GuessPassword {
    uint256 private secretNum;

    constructor(uint256 _secretNum) payable {
        secretNum = _secretNum;
    }

    function guess(uint256 _guess) public payable{
        require(msg.value >= 0.1 ether, "Not enough payment");

        if (_guess == secretNum) {
            (bool sent, ) = msg.sender.call{value: 1 ether}("");
            require(sent, "Failed to send Ether");
        }
    }
}
