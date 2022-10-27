//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// Task 6
contract GuessRandomNum {
    constructor() payable {}

    function guess(uint _guess) public payable {
        require(msg.value >= 0.1 ether, "Not enough payment");
        uint randomNum = uint(
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
        );

        if (_guess == randomNum) {
            (bool sent, ) = msg.sender.call{value: 1 ether}("");
            require(sent, "Failed to send Ether");
        }
    }
}
