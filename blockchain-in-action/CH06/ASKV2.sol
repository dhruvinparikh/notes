pragma solidity ^0.5.2;
    contract Airlines  {
    address chairperson;
    struct reqStruc{
        uint reqID;
        uint fID;
        uint numSeats;
        uint passengerID;
        address toAirln;
    }
   struct respStruc{
        uint reqID;
        bool status;
        address fromAirline;
        }
    mapping (address=>uint) public escrow;
    mapping (address=>uint) membership;
    mapping (address=>reqStruc) reqs;
    mapping (address=>respStruc) reps;
    mapping (address=>uint) settledReqID;
    //modifier or rules
    modifier onlyChairperson{
        require(msg.sender==chairperson);
        _;
    }
    modifier onlyMember{
        require(membership[msg.sender]==1);
        _;
    }
    // constructor function
    constructor () public payable  {
        chairperson = msg.sender;
        membership[msg.sender] = 1; // automatically registered
        escrow[msg.sender] = msg.value;
    }
    function register ( ) public payable{
        address AirlineA = msg.sender;
        membership[AirlineA] = 1;
        escrow[msg.sender] = msg.value;
    }
   function unregister (address payable AirlineZ) public onlyChairperson {
        if(chairperson!=msg.sender){
            revert();
        }
        membership[AirlineZ] = 0;
        //return escrow to leaving airline: other consitions may be verified
        AirlineZ.transfer(escrow[AirlineZ]);
        escrow[AirlineZ] = 0;
    }
    function ASKrequest (uint reqID, uint flightID, uint numSeats, uint custID, address toAirline) public  onlyMember {
        /*if(membership[toAirline]!=1){
            revert();}  */
        require(membership[toAirline]==1);
        reqs[msg.sender] = reqStruc(reqID, flightID, numSeats, custID, toAirline);
    }
    function  ASKresponse (uint reqID, bool success, address fromAirline) public onlyMember {
        if(membership[fromAirline]!=1){
            revert();
        }
        reps[msg.sender].status = success;
        reps[msg.sender].fromAirline = fromAirline;
        reps[msg.sender].reqID = reqID;
    }
    function settlePayment  (uint reqID, address payable toAirline, uint numSeats) public onlyMember  payable{
        //before calling this, it will update ASK view table
        address fromAirline = msg.sender;
        //asseume 1 unit of escrow for each seat
        //this is the consortium account transfer you want to do
        escrow[toAirline] = escrow[toAirline] + numSeats;
        escrow[fromAirline] = escrow[fromAirline] - numSeats;
        settledReqID[msg.sender] = reqID;
    }
    function replenishEscrow() public payable
    {
        escrow[msg.sender] = escrow[msg.sender] + msg.value;
    }
}