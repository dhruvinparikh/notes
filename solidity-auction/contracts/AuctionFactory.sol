// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;

import './Auction.sol';

contract AuctionFactory {
    address[] public auctions;

    event AuctionCreated(address auctionContract, address owner, uint numAuctions, address[] allAuctions);

    constructor() public {
    }

    function createAuction(uint bidIncrement, uint startBlock, uint endBlock, string memory ipfsHash) public {
        Auction newAuction = new Auction(msg.sender, bidIncrement, startBlock, endBlock, ipfsHash);
        auctions.push(address(newAuction));

        emit AuctionCreated(address(newAuction), msg.sender, auctions.length, auctions);
    }

    function allAuctions() public view returns (address[] memory) {
        return auctions;
    }
}
