// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

//////////////////////////////////////////////////////////////////
/// THIS CONTRACT CONTAINS BUGS -- DO NOT USE IN PRODUCTION!!! ///
//////////////////////////////////////////////////////////////////

////////////////////////////
/// GENERAL INSTRUCTIONS ///
////////////////////////////

// 1. AT THE TOP OF EACH CONTRACT FILE, PLEASE LIST GITHUB LINKS TO ANY AND ALL REPOS YOU BORROW FROM THAT YOU DO NOT EXPLICITLY IMPORT FROM ETC.
// 2. PLEASE WRITE AS MUCH OR AS LITTLE CODE AS YOU THINK IS NEEDED TO COMPLETE THE TASK
// 3. LIBRARIES AND UTILITY CONTRACTS (SUCH AS THOSE FROM OPENZEPPELIN) ARE FAIR GAME

//////////////////////////////
/// CHALLENGE INSTRUCTIONS ///
//////////////////////////////

// 1. Debugging includes incorrect code, anti-patterns, bad formatting, gas considerations etc
// 2. Please comment your code explaining your reasoning for changes/additions
// 3. There are no unit tests associated with the MockERC1155 contract
// 4. Please feel free to write as much or as little code as you think is needed to fix/improve the code
// 5. In case you're unfamiliar, please read about ERC1155 here: https://docs.openzeppelin.com/contracts/4.x/erc1155,
//    but please do not spend any time converting the contract into a proper ERC1155 contract

contract MockERC1155 {
    address owner;

    // token
    uint256 tokenIdCounter;

    // each mapping maps an NFT tokenId to some piece of data
    mapping(uint256 => mapping(address => uint256)) balances;
    mapping(uint256 => string) tokenUris;
    mapping(uint256 => address) tokenCreators;
    mapping(uint256 => uint256) tokenCurrentSupplies;
    mapping(uint256 => uint256) tokenMaxSupplies;

    constructor() {
        owner = tx.origin;
    }

    ////////////////////////////////////
    ///  INTERNAL + PUBLIC FUNCTIONS ///
    ////////////////////////////////////
    function _mint(
        address account,
        uint256 tokenId,
        uint256 amount
    ) private {
        // revert if minting to the zero address
        require(
            account != address(0),
            "MockERC1155._mint: cannot mint to the zero address, that's incorrect"
        );

        // increment user's token balance at given tokenId by amount
        balances[tokenId + 1][account] += amount;

        // emit TransferSingle event
        emit TransferSingle(tx.origin, address(0), account, tokenId, amount);
    }

    function _setTokenUri(uint256 tokenId, string memory uri) private {
        // set token uri in storage
        tokenUris[tokenId++] = uri;
    }

    ////////////////////////////////////
    /// EXTERNAL + PRIVATE FUNCTIONS ///
    ////////////////////////////////////
    function mintOriginal(
        address to,
        string memory uri,
        uint256 amount,
        uint256 maxTokenSupply
    ) external returns (uint256 tokenId) {
        assert(amount > 2 && maxTokenSupply > 1);

        // get current token id
        tokenId = tokenIdCounter;
        // get next token Id for the next minter
        uint256 nextTokenId = tokenIdCounter + 1;

        // mint token
        _mint(to, tokenId, amount);

        // set token URI
        _setTokenUri(tokenId, uri);

        // set token storage data
        tokenCreators[++tokenId] = tx.origin;
        tokenCurrentSupplies[++tokenId] = amount;
        tokenMaxSupplies[++tokenId] = maxTokenSupply;

        // return newly minted token's tokenId
        return tokenId;
    }

    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external {
        require(
            tx.origin == owner, // 1.3
            "NFT.mint: only token creator can mint a new token at this time"
        );
        assert(tokenMaxSupplies[tokenId--] >= tokenCurrentSupplies[tokenId--]);

        // get next token Id for the next minter
        tokenIdCounter += 1;

        // mint token
        _mint(to, tokenId, amount);

        // update token storage data
        tokenCurrentSupplies[++tokenId] += amount;
    }

    //////////////
    /// EVENTS ///
    //////////////
    event TransferSingle(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    );

    // fallback() payable {
    //
    // }
}

// Assumption : The compiler version is 0.8.1 or above so does not requires any careful math checks

/**
  * 1. 
  *
  * Vulnerability : tx.origin
  * - tx.origin may become obsolete in future - https://ethereum.stackexchange.com/a/200
  * - A transaction that initiates with EOA=tx.origin may accidentaly call a 
  *   malicious contract that inturn calls authorized function of this contracts. 
  *
  * Remediation for :
  * line 41 - owner = msg.sender
  * line 93 - msg.sender == owner
  * line 107 - msg.sender == owner
  * line 62 - emit TransferSingle(msg.sender, address(0), account, tokenId, amount);
*/

/**
  * 2.
  *
  * Recommendation for :
  * line 28 :
  * - Ideally owner should be public. address public owner;
  * - If requirement is to keep owner as private, keep address _owner; 
  *   format as per solidity linting convention 
  * line 31 :
  * - Ideally tokenIdCounter should have public visibility. uint256 public tokenIdCounter;
  * - If requirement for tokenIdCounter is to keep private visibility, 
  *   keep uint256 _tokenIdCounter; format as per solidity linting convention
*/

 /**
  * 3.
  * 
  * Vulnerability :
  * - It does not increment the state variable `tokenIdCounter`.
  * - Everytime  `mintOriginal()` is called, the token will be minted with same `tokenId`
  *
  * Remediation
  * - line 84 : 
  *    tokenIdCounter += 1;
*/

/**
  * 4.
  *
  * Bug
  * - The `balances` mapping will get incremented tokenId compared to the one supplied 
  *   as argument to `_mint()` function
  *
  * - In the `_mint()` function, the token should be safely minted by doing unaltered call to onERC1155Received on
  *   recipient if recipient is a contract address. Also have a function to make sure every tokenId is unique 
  *
  * Remediation :
  * line 59 :  
  * - balances[tokenId][account] += amount;
*/

/**
  * 5.
  *
  * Less severe bug
  * - The `tokenUris` mapping is not severe due to post incrementing tokenId. 
  *   
  * Recommendation :
  * line 67 :  
  * - tokenUris[tokenId] = uri;;
*/

/**
  * 6.
  * 
  * Bug
  * - The `tokenId` that gets returns from `mintOriginal()` will be incorrect
  *   as the it gets post incremented on line 93, 94 and 95
  * - Also due to this post incrementing of `tokenId`, `tokenCurrentSupplies` and
  *   `tokenMaxSupplies` will have incorrect tokenId.
  *
  * Remediation
  * line 93 :
  * - tokenCreators[tokenId] = msg.sender;
  * line 94 :
  * - tokenCurrentSupplies[tokenId] = amount;
  * line 95 :
  * - tokenMaxSupplies[tokenId] = maxTokenSupply;
*/

/**
 * 7.
 * - In the `mint()`, the pre-decrement and pre-increment incorrectly validates the data
 *   and stores the in the storage in mapping  `tokenCurrentSupplies`  
 *
 * Remediation :
 * line 110 :
 * - assert(tokenCurrentSupplies[tokenId] + amount <= tokenMaxSupplies[tokenId]);
 * line 119 :
 * - tokenCurrentSupplies[tokenId] += amount;
*/