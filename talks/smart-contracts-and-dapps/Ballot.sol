// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Ballot {

    // attributes of voter
    struct Voter {
        uint weight; // how much value a vote has? 1,2,?
        bool voted;  // whether voted or not
        uint vote;   // which proposal index has received vote
    }

    // attributes of proposal
    struct Proposal {
        uint voteCount;
    }
    
    // person who conducts election
    address public chairperson; // Ethereum address is 20 bytes long = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    
    // voters list
    mapping(address => Voter) public voters;
    // {
    //     "0xabcd.1234" => {weight,voted,vote},
    //     "0xab12..def2" => {weight, voted,vote}
    // }
    // syntax for mapping and it is used to represent JSON structure in solidity
    // mapping( keyType => valueType ) public variable_name ;   
    // list of Proposals
    Proposal[] public proposals;
    
    // election takes place in phases
    enum Phase {Init, Regs, Vote, Done}
    //            0 ,  1,    2,   3
    
    // intial phase would be Init
    Phase public state = Phase.Init;

    constructor (uint numProposals) {
        chairperson = msg.sender;
        voters[chairperson].weight = 2;
        for(uint prop = 0 ; prop < numProposals ; prop++){
            // Proposal memory p;
            // p.voteCount = 0;
            // OR
            // Proposal memory p = Proposal(0);
            // proposals.push(p);
            // OR
            proposals.push(Proposal(0));
        }
        state = Phase.Regs;
    }
    
    modifier onlyChair() {
        require(msg.sender  == chairperson,"!chairperson");
        _;
    }
    
    modifier validPhase(Phase reqPhase) {
        require(state == reqPhase);
        _;
    }
    
    function changeState(Phase x) public onlyChair {
        require(x > state);
        state = x;
    }
    
    function register(address voter) public validPhase(Phase.Regs) onlyChair {
        require(voters[voter].voted == false);
        voters[voter].weight = 1;
    }
    
    function vote(uint toProposal) public validPhase(Phase.Vote) {
        Voter memory sender = voters[msg.sender];
        
        require(sender.voted == false);
        
        require(toProposal < proposals.length);
        
        voters[msg.sender].voted = true;
        voters[msg.sender].vote = toProposal;
        proposals[toProposal].voteCount += sender.weight;
    }
    
    function reqWinner() public validPhase(Phase.Done) view returns(uint) {
        uint winningVoteCount = 0;
        uint winningProposal = 0;
        for(uint prop = 0 ; prop < proposals.length ; prop++){
            if(proposals[prop].voteCount > winningVoteCount) {
                winningVoteCount = proposals[prop].voteCount;
                winningProposal = prop;
            }
        }
        assert(winningVoteCount >= 3);
        return winningProposal;
    }
}