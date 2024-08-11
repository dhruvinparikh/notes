pragma solidity 0.4.19;

contract HelloWorld {
  uint private simpleInt;

  function GetValue() public view returns (uint) {
     return simpleInt;
  }

  function SetValue(uint _value) public {
    simpleInt = _value; 
  }
}

contract client {

  address obj ;

  function setObject(address _obj) external {
    obj = _obj;
  } 

  function UseExistingAddress() public returns {
     HelloWorld myObj = new HelloWorld(obj);
     myObj.SetValue(10);
     return myObj.GetValue();
  }
}