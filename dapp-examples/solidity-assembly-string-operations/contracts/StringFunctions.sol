pragma solidity ^0.6.0;

contract StringFunctions {

    function concatenate(string memory A, string memory B) public pure returns (string memory) {
        //convert strings to bytes (have access to length and indexing)
        bytes memory _A = bytes(A);
        bytes memory _B = bytes(B);
        bytes memory output = new bytes(_A.length + _B.length); //preallcate output bytes array

        uint256 i;
        //iterate through all characters in first string and add them to output
        for (uint256 ii; ii < _A.length; ii++) {
            output[i] = _A[ii];
            i++;
        }

        //iterate through all characters in second string and add them to output
        for (uint256 jj; jj < _B.length; jj++) {
            output[i] = _B[jj];
            i++;
        }

        return string(output);
    }

    function charAt(string memory A, uint256 ii) public pure returns (string memory) {
        bytes memory _A = bytes(A); //convert string to bytes
        require(ii < _A.length, "index out of range"); //check index is valid

        bytes memory output = new bytes(1); //preallocate output
        output[0] = _A[ii]; //assign character from A to output
        return string(output);
        // return string(_A[ii]); //doesn't work - bytes1 not allowed to be converted to string memory
    }

    function replace(string memory A, uint256 ii, string memory B) public pure returns (string memory) {
        bytes memory _A = bytes(A); //convert to bytes
        require(ii < _A.length, "index out of range"); //checking index
        bytes memory _B = bytes(B); //convert to bytes
        require(_B.length == 1, "incorrect replacement size"); //validate single character
        _A[ii] = _B[0]; //assign to correct location
        return string(_A);
    }

    function length(string memory A) public pure returns (uint256) {
        bytes memory _A = bytes(A); //convert to bytes so length is available
        return _A.length;
    }

    function slice(string memory A, uint256 ii, uint256 jj) public pure returns (string memory) {
        require(ii < jj, "incorrect indices"); //validate by comparing indices
        bytes memory _A = bytes(A); //convert to bytes
        require(ii < _A.length, "first index out of range"); //validate index
        require(jj <= _A.length, "second index out of range");

        bytes memory output = new bytes(jj-ii); //allocate output bytes to correct length

        //for loop for inserting characters into output
        for (uint256 kk; kk < jj-ii; kk++){
            output[kk] = _A[kk+ii];
        }

        return string(output);
    }

    function slice(string memory A, uint256 ii) public pure returns (string memory) {
        return slice(A, ii, bytes(A).length); //call slice using length as 3rd parameter
    }
}
