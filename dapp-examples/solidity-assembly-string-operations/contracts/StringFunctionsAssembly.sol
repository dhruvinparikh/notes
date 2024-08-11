pragma solidity ^0.6.0;

contract StringFunctionsAssembly {

    function concatenate(string memory A, string memory B) public pure returns (string memory output) {
        assembly{
            if gt(add(mload(A), mload(B)), 32) {revert(0,0)} //can't handle more than 32 bytes for total
            let size := add(mload(A), mload(B)) //calculate total size
            output := mload(0x40)

            //calculate required size + padding
            //allocate at the available memory slot marked at 0x40
            mstore(0x40, add(output, and(add(add(size, 0x20), 0x1f), not(0x1f))))

            //store size in first part of data slot
            mstore(output, size)

            //get data stored at 0xa0 (string A) and at 0xe0 (string B)
            //shift bytes for B over by the length of A, and then add them together to combine strings
            //store in slot shifted by 0x20 to preserve size data
            mstore(add(output, 0x20), add(mload(0xa0), div(mload(0xe0), exp(2,mul(mload(A), 8)))))
        }
    }


    function charAt(string memory A, uint256 ii) public pure returns (string memory output) {
        assembly {
            if gt(mload(A), 32) {revert(0,0)} //can't handle more than 32 bytes for total
            if gt(ii, sub(mload(A), 1)) {revert(0,0)} //index must be valid

            output := mload(0x40)
            //preallocate memory slot for single character
            mstore(0x40, add(output, and(add(add(1, 0x20), 0x1f), not(0x1f))))
            mstore(output, 1)

            // math used to shift bits over to trim characters in front
            // shift right and multiply to trim off characters afterward (not the most efficient)
            // store in memory slot
            mstore(add(output, 0x20), mul(shr(0xf8, mload(add(0xa0, ii))), exp(2, sub(256, 8))))
        }
    }

    function replace(string memory A, uint256 ii, string memory B) public pure returns (string memory output){
        assembly {
            if gt(mload(A), 32) {revert(0,0)} //can't handle more than 32 bytes for total
            if gt(ii, sub(mload(A), 1)) {revert(0,0)} //index must be valid
            if eq(1, mod(1, mload(B))) {revert(0,0)} //check that B is single character -> 1 == (1 % B.length) -> true if B.length > 1

            //preallocate memory slot
            output := mload(0x40)
            mstore(0x40, add(output, and(add(add(mload(A), 0x20), 0x1f), not(0x1f))))
            mstore(output, mload(A))

            // get mark all bits for 1 byte, shift to correct index position
            // invert and mask data stored at 0xa0
            // shift single character to correct position and add together
            // store in memory slot
            mstore(add(output, 0x20), add(and(mload(0xa0), not(shl(sub(256, mul(8, add(ii, 1))), sub(exp(2, 8), 1)))), shr(mul(8, ii), mload(0xe0))))
        }
    }


    function length(string memory A) public pure returns (uint256 strlen) {
        assembly {
           strlen := mload(A) //return length
        }
    }

    function slice(string memory A, uint256 ii, uint256 jj) public pure returns (string memory output) {
        assembly {
            if gt(ii, jj) {revert(0,0)} // check if indicess are valid
            let len := mload(A)
            if gt(ii, sub(len, 1)) {revert(0,0)}
            if gt(jj, len) {revert(0,0)}

            //preallocate memory
            output := mload(0x40)
            mstore(0x40, add(output, and(add(add(sub(jj,ii), 0x20), 0x1f), not(0x1f))))
            mstore(output, sub(jj,ii))

            //mload a shifted version (by ii bytes) of string to trim front characters
            //create bits for remaining required characters (jj-ii bytes), and shift to the propery position at front of bytes string
            //mask the shifted string and bits together to get output
            //store in memory slot
            mstore(add(output, 0x20), and(mload(add(0xa0, ii)), shl(sub(256, mul(8, sub(jj,ii))), sub(exp(2, mul(8, sub(jj, ii))), 1))))
        }
    }

    function slice(string memory A, uint256 ii) public pure returns (string memory) {
        return slice(A, ii, bytes(A).length); //use slice with total length as 3rd parameter
    }
}
