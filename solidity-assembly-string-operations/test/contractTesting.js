const StringFunctions = artifacts.require("StringFunctions");
const StringFunctionsAssembly = artifacts.require("StringFunctionsAssembly");
const truffleAssert = require("truffle-assertions");

//console log with padding in the front
const logOutput = (...params) => {
  console.log("     ", ...params);
};

//https://stackoverflow.com/questions/1349404/generate-random-string-characters-in-javascript
const randomString = () => {
  //generates two random strings with a maximum combined length of 32 bytes

  const lengths = [Math.ceil(Math.random() * 32)]; //calculate first length
  lengths.push(Math.ceil(Math.random() * (32 - lengths[0]))); //calculate the second length based on first length
  const result = ["", ""]; //preallocation for result array
  const characters =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"; //list of available characters
  for (var i = 0; i < lengths.length; i++) { //iterate through the number of lenghts
    for (var j = 0; j < lengths[i]; j++) { //iterate through the length
      result[i] += characters.charAt( //save to corresponding result
        Math.floor(Math.random() * characters.length) //get random character
      );
    }
  }
  return result;
};

const longString = new Array(100).fill("A").join(""); //a really long string

contract("StringFunctions + StringFunctionsAssembly", accounts => {
  //preallocate contract variables
  let stringFunc;
  let stringAssem;

  before(async () => {
    //deploy contracts to variables
    stringFunc = await StringFunctions.deployed();
    stringAssem = await StringFunctionsAssembly.deployed();
  });

  it("deployment gas optimization correct", async () => {
    //test that the assembly code costs less gas than the non-assembly code
    //https://ethereum.stackexchange.com/questions/36270/how-can-i-get-the-gas-cost-of-contract-creation-within-truffle-migrations-tes

    //deploy contracts
    const funcGas = await StringFunctions.new();
    const assemGas = await StringFunctionsAssembly.new();

    //get transaction receipts
    const funcReceipt = await web3.eth.getTransactionReceipt(
      funcGas.transactionHash
    );
    const assemReceipt = await web3.eth.getTransactionReceipt(
      assemGas.transactionHash
    );

    //print gas costs
    logOutput(
      "Assembly:",
      assemReceipt.gasUsed,
      "Non-Assembly:",
      funcReceipt.gasUsed
    );
    assert.isBelow(
      assemReceipt.gasUsed,
      funcReceipt.gasUsed,
      "deployment gas consumption is less for assembly"
    );
  });

  it("concatenate() functions correctly", async () => {
    let str = randomString(); //get two random strings
    while (str[0].length == 32) { //makes sure that the string is not 32 bytes (re-runs string generation if true)
      str = randomString();
    }

    //three methods for concatenation (JS, Solidity - no assembly, Solidity - assembly)
    const comb0 = str[0].concat(str[1]);
    const comb1 = await stringFunc.concatenate(str[0], str[1]);
    const comb2 = await stringAssem.concatenate(str[0], str[1]);

    assert.equal(comb0, comb1, "JS concatenate = concatenate (no assembly)");
    assert.equal(comb0, comb2, "JS concatenate = concatenate (assembly)");

    //double check that transaction reverts if string longer than 32 bytes
    truffleAssert.reverts(
      stringAssem.concatenate(comb1, comb2),
      null,
      "maximum 32 bytes"
    );
  });

  it("charAt() functions correctly", async () => {
    //get random string and random valid index
    const str = randomString();
    const ind = Math.floor(Math.random() * str[0].length);

    //test charAt using 3 different methods
    const char0 = str[0][ind];
    const char1 = await stringFunc.charAt(str[0], ind);
    const char2 = await stringAssem.charAt(str[0], ind);

    assert.equal(char0, char1, "JS charAt = charAt (no assembly)");
    assert.equal(char0, char2, "JS charAt = charAt (assembly)");

    //test reverts if index is too large or string longer than 32 bytes
    truffleAssert.reverts(
      stringFunc.charAt(str[0], str[0].length),
      null,
      "(func) indice is too large"
    );
    truffleAssert.reverts(
      stringAssem.charAt(longString, ind),
      null,
      "maximum 32 bytes"
    );
    truffleAssert.reverts(
      stringAssem.charAt(str[0], str[0].length),
      null,
      "(assem) indice is too large"
    );
  });

  it("replace() functions correctly", async () => {
    //get random string, index, and character
    const str = randomString();
    const ind = Math.floor(Math.random() * str[0].length);
    const letter = str[1][0] || "A"; //handles if second string is length 0

    //replace implemented using 3 methods
    let str0 = str[0].split("");
    str0[ind] = letter;
    str0 = str0.join("");
    const str1 = await stringFunc.replace(str[0], ind, letter);
    const str2 = await stringAssem.replace(str[0], ind, letter);

    assert.equal(str0, str1, "JS replace = replace (no assembly)");
    assert.equal(str0, str2, "JS replace = replace (assembly)");

    //test reverts for greater than 32 bytes, index too large, replace character is not a single character
    truffleAssert.reverts(
      stringFunc.replace(str[0], str[0].length, letter),
      null,
      "(func) indice is too large"
    );
    truffleAssert.reverts(
      stringFunc.replace(str[0], ind, "AB"),
      null,
      "(func) character is not single byte"
    );
    truffleAssert.reverts(
      stringAssem.replace(longString, ind, letter),
      null,
      "maximum 32 bytes"
    );
    truffleAssert.reverts(
      stringAssem.replace(str[0], str[0].length, letter),
      null,
      "(assem) indice is too large"
    );
    truffleAssert.reverts(
      stringAssem.replace(str[0], ind, "AB"),
      null,
      "(assem) character is not single byte"
    );
  });

  it("length() functions correctly", async () => {
    const str = randomString(); //get random string

    //get length using three methods
    const len0 = str[0].length;
    const len1 = await stringFunc.length(str[0]);
    const len2 = await stringAssem.length(str[0]);

    assert.equal(len0, len1, "JS length = length (no assembly)");
    assert.equal(len0, len2, "JS length = length (assembly)");
  });

  it("slice() with 3 inputs functions correctly", async () => {
    //get random string and two indices
    const str = randomString();
    const ind = [Math.floor(Math.random() * str[0].length)];
    ind.push(Math.ceil(Math.random() * (str[0].length - ind[0]) + ind[0]));

    //test slice using three different implemntations
    const slice0 = str[0].slice(ind[0], ind[1]);
    const slice1 = await stringFunc.methods["slice(string,uint256,uint256)"](
      str[0],
      ind[0],
      ind[1]
    );
    const slice2 = await stringAssem.methods["slice(string,uint256,uint256)"](
      str[0],
      ind[0],
      ind[1]
    );

    assert.equal(slice0, slice1, "JS slice = slice (no assembly)");
    assert.equal(slice0, slice2, "JS slice = slice (assembly)");

    //checking reverts for first indice > second indice, first indice incorrect, second indice incorrect
    truffleAssert.reverts(
      stringFunc.methods["slice(string,uint256,uint256)"](
        str[0],
        ind[1] + 1,
        ind[1]
      ),
      null,
      "(func) incorrect indices"
    );

    truffleAssert.reverts(
      stringFunc.methods["slice(string,uint256,uint256)"](
        str[0],
        str[0].length,
        str[0].length + 2
      ),
      null,
      "(func) first index out of range"
    );

    truffleAssert.reverts(
      stringFunc.methods["slice(string,uint256,uint256)"](
        str[0],
        ind[0],
        str[0].length + 2
      ),
      null,
      "(func) second index out of range"
    );
    truffleAssert.reverts(
      stringAssem.methods["slice(string,uint256,uint256)"](
        str[0],
        ind[1] + 1,
        ind[1]
      ),
      null,
      "(assem) incorrect indices"
    );

    truffleAssert.reverts(
      stringAssem.methods["slice(string,uint256,uint256)"](
        str[0],
        str[0].length,
        str[0].length + 2
      ),
      null,
      "(assem) first index out of range"
    );

    truffleAssert.reverts(
      stringAssem.methods["slice(string,uint256,uint256)"](
        str[0],
        ind[0],
        str[0].length + 2
      ),
      null,
      "(assem) second index out of range"
    );
  });

  it("slice() with 2 inputs functions correctly", async () => {
    //testing function overloading for slice
    // using random string + index
    const str = randomString();
    const ind = Math.floor(Math.random() * str[0].length);

    //slice tested with three equivalent methods
    const slice0 = str[0].slice(ind);
    const slice1 = await stringFunc.methods["slice(string,uint256)"](
      str[0],
      ind
    );
    const slice2 = await stringAssem.methods["slice(string,uint256)"](
      str[0],
      ind
    );

    assert.equal(slice0, slice1, "JS slice = slice (no assembly)");
    assert.equal(slice0, slice2, "JS slice = slice (assembly)");
  });
});
