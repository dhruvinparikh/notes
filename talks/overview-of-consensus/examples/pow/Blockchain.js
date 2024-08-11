const crypto = require("crypto");
const uuid = require("uuid");
const { MerkleTree } = require('merkletreejs')
const SHA256 = require('crypto-js/sha256')

/**
 * Block represents a block in the blockchain. It has the
 * following params:
 * @index represents its position in the blockchain
 * @timestamp shows when it was created
 * @transactions represents the data about transactions
 * added to the chain
 * @hash represents the hash of the previous block
 */
class Block {
  constructor(index, transactions, prevHash, nonce, hash,merkleRoot) {
    this.index = index;
    this.timestamp = Math.floor(Date.now() / 1000);
    this.transactions = transactions;
    this.prevHash = prevHash;
    this.hash = hash;
    this.nonce = nonce;
    this.merkleRoot = merkleRoot
  }
}

/**
 * A blockchain transaction. Has an amount, sender and a
 * recipient (not UTXO).
 */
class Transaction {
  constructor(amount, sender, recipient) {
    this.amount = amount;
    this.sender = sender;
    this.recipient = recipient;
    this.tx_id = uuid().split("-").join();
  }
}

/**
 * Blockchain represents the entire blockchain with the
 * ability to create transactions, mine and validate
 * all blocks.
 */
class Blockchain {
  constructor() {
    this.chain = [];
    this.pendingTransactions = [];
    this.addBlock("0","0");
    this.difficultyLevel = 3;
    this.difficultyIncreaseInterval = 5;
    this.blocksMinedAfterIncrease = 0;
  }

  /**
   * Creates a transaction on the blockchain
   */
  createTransaction(amount, sender, recipient) {
    this.pendingTransactions.push(new Transaction(amount, sender, recipient));
  }

  /**
   * Add a block to the blockchain
   */
  addBlock(nonce,merkleRoot) {
    let index = this.chain.length;
    let prevHash = this.chain.length !== 0 ? this.chain[this.chain.length - 1].hash : "0";
    let hash = this.getHash(prevHash, merkleRoot, nonce);
    let block = new Block(
      index,
      this.pendingTransactions,
      prevHash,
      nonce,
      hash,
      merkleRoot
    );

    // reset pending txs
    this.pendingTransactions = [];
    this.chain.push(block);

    //increases the difficulty level based blocks mined since last increase and interval value
    this.blocksMinedAfterIncrease++;

    if (this.blocksMinedAfterIncrease === this.difficultyIncreaseInterval) {
      this.difficultyLevel++;
      this.blocksMinedAfterIncrease = 0;
    }
  }

  /**
   * Gets the hash of a block.
   * takes previous block hash , merkle root of block to be added and nonce which is guessed 
   */
  getHash(prevHash, merkleRoot, nonce) {
    var encrypt = prevHash + merkleRoot + nonce;
    var hash = crypto
      .createHmac("sha256", "secret")
      .update(encrypt)
      .digest("hex");
    return hash;
  }

  //calculates diff b/w  next block generation
  //returns diff in timestamps in seconds
  calculateBlockTime(timestamp1, timestamp2) {
    const diffInSeconds = (timestamp2 - timestamp1) / 1000;
    return diffInSeconds;
  }

  
  //calculate the average hash rate 
  //return the average hash rate of the chain in seconds
  calculateAverageHashRate() {

    let blockTimes = []
    let timestamps = []
    let blockCount =  this.chain.length
    for (let i = 0; i < this.chain.length ; i++) {
        if(i == 0){
            blockTimes[i] = 1
        }else{
            blockTimes[i] = this.calculateBlockTime(this.chain[i-1].timestamp, this.chain[i].timestamp)
        }
        timestamps[i] = this.chain[i].timestamp;
    }

    if (timestamps.length !== blockCount || blockTimes.length !== blockCount) {
      throw new Error('Invalid input data: timestamps and blockTimes must be of length blockCount.');
    }
  
    let totalMiningTime = 0;
    for (let i = 0; i < blockCount; i++) {
      totalMiningTime += blockTimes[i];
    }
    
    const averageMiningTime = totalMiningTime / blockCount;
    const averageHashRate = (blockCount * 1000) / (averageMiningTime * timestamps[blockCount - 1]);
  
    return averageHashRate;
  }

  /**
   * Find nonce that satisfies our proof of work.
   * @param merkleRoot - merkle root of tree connstructed using pending transactions
   */
  proofOfWork(merkleRoot) {

    //Number of zeros in the begining of hash
    let nzeros = new Array(this.difficultyLevel + 1).join("0");

    //length of random striing for nonce
    let nonceLength = 5;

    //initializing nounce to empty
    let nonce = "";

    //previous block hash
    let prevHash = this.chain.length !== 0 ? this.chain[this.chain.length - 1].hash : "0";


    

    //this loop runs until we find nonce that matches difficulty level (as per if condition)
    while (true) {
      //generates the hash value based on blockdata + nounce
      let hash_value = this.getHash(prevHash, merkleRoot, nonce);

      //difficulty level conidtion
      if (hash_value.slice(0, this.difficultyLevel) == nzeros) {
        return nonce;
      } else {
        //gets new random string of length 5
        nonce = this.getRandomString(nonceLength);
      }
    }
  }

  /**
   *
   * generates random string of given length
   * from defined chars in the method
   * @param length length of random string to return
   * return random sring of given length.
   */

  getRandomString(length) {
    var chars ="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    var result = "";
    //gets random characters from chars array for given length
    for (var i = length; i > 0; --i) {
      result += chars[Math.floor(Math.random() * chars.length)];
    }
    return result;
  }

  /**
   * Mine a block and add it to the chain.
   * constrcuts merkle tree and uses the root while creating block to 
   * generate block hash
   */
  mine() {
    let tree = constructMerkleTree(this.pendingTransactions)
    let merkleRoot = tree.getRoot().toString('hex')
    let nonce = this.proofOfWork(merkleRoot);
    this.addBlock(nonce,merkleRoot);
  }

  /**
   * Check if the chain is valid by going through all blocks and comparing their stored
   * hash with the computed hash.
   * 
   * verifies if the transaction belongs to particular block or 
   * not using merkle tree proof and verify methods from merkle tree js library
   */
  chainIsValid() {
    for (var i = 0; i < this.chain.length; i++) {

      const transactions = this.chain[i].transactions
      let goodTree = constructMerkleTree(transactions);
      const merkleRoot = goodTree.getRoot().toString('hex')

      if (i == 0) {
        let hash  =   this.getHash("0", "0","0")
        if(this.chain[i].hash !== hash){
          return false;
        }
      }
      else{
        let hash1  =   this.getHash(this.chain[i - 1].hash, merkleRoot, this.chain[i].nonce)
        if(this.chain[i].hash !== hash1){
          return false;
        }
        const itemProved = Math.floor(Math.random() * transactions.length);
        const goodItem = SHA256(JSON.stringify(transactions[itemProved]))
        const goodProof = goodTree.getProof(goodItem)

        let badTransactions = Array.from(transactions)
        //currupting transaction data 
        badTransactions[itemProved] = new Transaction("000", "XXX", "XXX");
        const badItem = SHA256(JSON.stringify(badTransactions[itemProved]))
        let badTree = constructMerkleTree(badTransactions);
        const badProof = badTree.getProof(badItem)


        let needsToBeTrue = goodTree.verify(goodProof, goodItem, merkleRoot)
        let needsToBeFalse = badTree.verify(badProof, badItem, merkleRoot)

        if(!needsToBeTrue || needsToBeFalse){
          return false
        }

        // Used in case of merkle tree construction implementation - not using merkletree js library
        /**
         * 
         * let hashArray = getHashedTransactions(this.chain[i].transactions);
          const itemProved = 3
          const proof = getMerkleProof(hashArray, itemProved)
          verifyMerkleProof(merkleRoot, hashArray[itemProved], proof)}`)
          verifyMerkleProof(merkleRoot, hashArray[itemProved ^ 2], proof)}`)
         * 
         * 
         */
      }
      if (i > 0 && this.chain[i].prevHash !== this.chain[i - 1].hash) {
        return false;
      }
    }
    return true;
  }
}

/**
 *  if not using merkletree js library, this function is used to generate hashes of transaction arra
 * return hash array
 * 
 * @param transactions - array of pending transactions
 * @returns - array of hashed transactions
 */
function getHashedTransactions(transactions) {

      let dataArray = []
      transactions.forEach(element => {
        const hash = crypto.createHash('sha256').update(JSON.stringify(element)).digest('hex');
        dataArray.push(hash)
      });
      return dataArray;
}

/**
 * 
 * takes 2 hash values and gives resultant hash 
 * @param - 2 hashes
 * @returns - return combined hash
 */
const pairHash = (a,b) => {
  return  crypto.createHash('sha256').update(JSON.stringify(a+b)).digest('hex')
}
     

/**
 * Calculate one level up the tree of a hash array by taking the hash of 
 * each pair in sequence
 * @param : takes hashed array 
 * @returns hash for that particular level
 */
const oneLevelUp = inputArray => {
    var result = []
    var inp = [...inputArray] 
    if (inp.length % 2 === 1)
        inp.push(inp[inp.length -1]) //adding extra elemenets if array is not containing 2^n elements 
    for(var i=0; i<inp.length; i+=2)
        result.push(pairHash(inp[i],inp[i+1]))

    return result
}   

/* Used if we are not using merkletree js library
A merkle proof consists of the value of the list of entries to 
hash with. Because we use a symmetrical hash function, we don't
need the item's location to verify, only to create the proof.
*/
const getMerkleProof_old = (inputArray, n) => {
    var result = [], currentLayer = [...inputArray], currentN = n

    // Until we reach the top
    while (currentLayer.length > 1) {
        // No odd length layers
        if (currentLayer.length % 2)
            currentLayer.push(empty)

        result.push(currentN % 2    
               // If currentN is odd, add the value before it
            ? currentLayer[currentN-1] 
               // If it is even, add the value after it
            : currentLayer[currentN+1])

        // Move to the next layer up
        currentN = Math.floor(currentN/2)
        currentLayer = oneLevelUp(currentLayer)
    }   // while currentLayer.length > 1

    return result
}   



// Verify a merkle proof that nValueHash is in the merkle tree, for 
// a given merkle root. This code needs to be run by the contract, so we'll 
// translate it to Solidity.
const verifyMerkleProof = (root, nValueHash, proof) => {
    var hashVal = nValueHash // The hash for this layer

    // For every tree layer
    for(layer=0; layer<proof.length; layer++)
        hashVal = pairHash(proof[layer],hashVal)

    return root === hashVal
} 



/** 
 *  takes transactions array as input and converts them to hashes then we get leaf nodes level
 then we will use merkletree method from merkletree js to generate complete merkle tree
 @param transactions - pending transactions array
 returns :  complete merkle tree
*/
function constructMerkleTree(transactions){
  
    const leaves = transactions.map(x => SHA256(JSON.stringify(x)))
    const tree = new MerkleTree(leaves, SHA256)
    return tree;
}

/**
 * This function is useful when implementing merkle tree from scratch
 * without using merkletree js 
 * @param  transactions - pending transactions array
 * @returns - merkle root
 */

function constructMerkleTree_old(transactions) {

  let txnHashArray = getHashedTransactions(transactions);

  if(txnHashArray.length == 0){
    return "0";
  }
  var result

  result = [...txnHashArray]
  while(result.length > 1){
        result = oneLevelUp(result)
  }

  return result[0]

}

function simulateChain(blockchain, numTxs, numBlocks) {
  for (let i = 0; i < numBlocks; i++) {
    let numTxsRand = Math.floor(Math.random() * Math.floor(numTxs));
    for (let j = 0; j < numTxsRand; j++) {
      let sender = uuid().substr(0, 5);
      let receiver = uuid().substr(0, 5);
      blockchain.createTransaction(
        sender,
        receiver,
        Math.floor(Math.random() * Math.floor(1000))
      );
    }
    blockchain.mine();
  }
}

const BChain = new Blockchain();
//simulateChain(BChain, 5, 3);

module.exports = Blockchain;

// uncomment these to run a simulation
// console.dir(BChain,{depth:null});
// console.log("******** Validity of this blockchain: ", BChain.chainIsValid());
