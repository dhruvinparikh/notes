# Solidity String Operations

### High-Level Design
Using assembly to implement various string operations that are not possible in normal solidity.

Five functions: ([discussed here](https://hackernoon.com/working-with-strings-in-solidity-c4ff6d5f8008))
- Determining the string’s length
- Reading the character at a given location in the string
- Changing the character at a given location in the string
- Joining two strings
- Extracting part of a string

### Implementation Details
_(see detailed implementation in contract comments)_

Two methods of implementation for gas cost comparison:
- String operations implemented using standard Solidity commands and type conversions
- String operations implemented using Solidity assembly commands

String operation functions:
- `concatenate` - combine two strings into one string
- `charAt` - return character at specific index of string
- `replace` - replace character at specific index of string
- `length` - return the length of the string
- `slice` - basic implementation of the JavaScript `slice()` command with function overloading to handle different input parameters

[Implementation without assembly:](./contracts/StringFunctions.sol)
- Typically involved converting the `string memory` type to `bytes memory` because `bytes` has access to more functions such as length, indexing, etc
- Loops were used when multiple bytes need to be assigned to a `bytes` array

[Implementation with assembly:](./contracts/StringFunctionsAssembly.sol)
- Typically involved bitwise operations to manipulate strings and then storing them in memory to be output as strings

### Gas Cost Optimizations
The gas optimization is based on a comparison between the without assembly and with assembly implementations.
- Avoiding loops when using assembly, using bitwise operators instead
- Assembly commands are written in a single line rather than assigned to variables (pushes less information to the stack)

### Security Considerations
Overall, these functions do not have many security needs because they do not access storage and are restricted to `pure`.

However, there are always possible exploitation:
- Memory overflow - if the strings were larger than 32 bytes, the user may be able to access other parts of memory

### Current Limitations
For assembly implementation:
- Strings must be less than 32 bytes (total) for some functions

### Additional/Possible Implementations
- Converting the contracts to libraries and being able to use it with other contracts.
  - _Not Implemented_
  - Not necessary in this use case. It would be more inefficient to need to create an additional contract to test the functions.
- [Test cases](./test/contractTesting.js) for comparing functionality between JavaScript, the contract without assembly, and the contract with assembly
  - _Implemented_
  - Using `truffle test`
    ```
    Contract: StringFunctions + StringFunctionsAssembly
        Assembly: 634491 Non-Assembly: 864574
      ✓ deployment gas optimization correct (295ms)
      ✓ concatenate() functions correctly (315ms)
      ✓ charAt() functions correctly (216ms)
      ✓ replace() functions correctly (281ms)
      ✓ length() functions correctly (358ms)
      ✓ slice() with 3 inputs functions correctly (125ms)
      ✓ slice() with 2 inputs functions correctly (405ms)

      7 passing (2s)
      ```
  - Using `truffle run coverage`

    ```
    ------------------------------|----------|----------|----------|----------|----------------|
    File                          |  % Stmts | % Branch |  % Funcs |  % Lines |Uncovered Lines |
    ------------------------------|----------|----------|----------|----------|----------------|
     contracts/                   |      100 |      100 |      100 |      100 |                |
      StringFunctions.sol         |      100 |      100 |      100 |      100 |                |
      StringFunctionsAssembly.sol |      100 |      100 |      100 |      100 |                |
    ------------------------------|----------|----------|----------|----------|----------------|
    All files                     |      100 |      100 |      100 |      100 |                |
    ------------------------------|----------|----------|----------|----------|----------------|
    ```
- CI/CD in Github for automatically running test cases
  - _Implemented_
  - Using `truffle run coverage` (contains basic run of `truffle test`)
  - See [nodejs.yml](./.github/workflows/nodejs.yml)

### Resources
- [Solidity assembly](https://solidity.readthedocs.io/en/v0.5.12/assembly.html)
- [Bitwise operators](https://medium.com/@imolfar/bitwise-operations-and-bit-manipulation-in-solidity-ethereum-1751f3d2e216)
- [bytes32 to bytes](https://ethereum.stackexchange.com/questions/40920/convert-bytes32-to-bytes)
