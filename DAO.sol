//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DAO {
    
    // Variables
    address public owner;
    mapping(address => bool) public members;
    uint public totalShares;
    mapping(address => uint) public shares;
    uint VotingPeriod = 7 days;

    // Events
    event MemberAdded(address member);
    event MemberRemoved(address member);
    event SharesBought(address buyer, uint amount);
    event SharesSold(address seller, uint amount);
    event ProposalSubmitted(address proposer, string proposal);
    event Voted(address voter, uint proposalId, bool inFavor);
    event ProposalExecuted(address executor, uint proposalId);

    // Structs
    struct Proposal {
        address proposer;
        string description;
        uint votesFor;
        uint votesAgainst;
        bool executed;
        bool isApproved;
        mapping(address => bool)hasVoted;
    }

    // Mapping Method
    mapping(uint => Proposal) proposals;
    uint proposalId;

    //Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can call this function");
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender;
        members[msg.sender] = true;
        totalShares = 100;
        shares[msg.sender] = 100;
    }

    // Functions
    function addMember(address _member) public onlyOwner {
        require(!members[_member], "Member already exists");
        members[_member] = true;
        totalShares++;
        shares[_member] = 1;
        emit MemberAdded(_member);
    }

    function removeMember(address _member) public onlyOwner {
        require(members[_member], "Member does not exist");
        require(_member != owner, "Cannot remove Owner");
        members[_member] = false;
        totalShares--;
        shares[_member] = 0;
        emit MemberRemoved(_member);
    }

    function buyShares(uint _amount) public payable onlyMember {
        require(_amount <= (totalShares - shares[msg.sender]), "Not enough shares available");

        uint cost = _amount * 1 ether;
        require(msg.value == cost, "Incorrect value sent");

        shares[msg.sender] += _amount;
        totalShares += _amount;

        emit SharesBought(msg.sender, _amount);
    }

    function sellShares(uint _amount) public onlyMember {
        require(shares[msg.sender] >= _amount, "Not enough shares owned");

        shares[msg.sender] -= _amount;
        totalShares -= _amount;

        payable(msg.sender).transfer(_amount * 1 ether);
        emit SharesSold(msg.sender, _amount);
    }

    function submitProposal(string memory _description) public onlyMember {
        proposalId++;
        Proposal storage proposal = proposals[proposalId];
        proposal.proposer = msg.sender;
        proposal.description = _description;
        proposal.votesFor = 0;
        proposal.votesAgainst = 0;
        proposal.executed = false;
        proposal.isApproved = false;
        proposal.hasVoted[msg.sender] = false;
        emit ProposalSubmitted(msg.sender, _description);
    }

    // Nice Functionality
    function vote(uint _proposalId, bool _inFavor) public onlyMember {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal Already executed");
        require(!proposal.hasVoted[msg.sender], "Already voted on proposal");

        if(_inFavor) {
            proposal.votesFor += shares[msg.sender];
        }
        else {
            proposal.votesAgainst += shares[msg.sender];
        }

        proposal.hasVoted[msg.sender] = true;
        emit Voted(msg.sender, _proposalId, _inFavor);

    
    }

    function executeProposal(uint _proposalId) public onlyMember {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal Already executed");
        require(block.timestamp > VotingPeriod, "Voting period has not expired");

        if(proposal.votesFor > proposal.votesAgainst) {
            proposal.executed = true;
            proposal.isApproved = true;

            emit ProposalExecuted(msg.sender, _proposalId);
        }
        else if(proposal.votesAgainst > proposal.votesFor) {
            proposal.executed = true;
            proposal.isApproved = false;

            emit ProposalExecuted(msg.sender, _proposalId);
        }
        
    }
}
