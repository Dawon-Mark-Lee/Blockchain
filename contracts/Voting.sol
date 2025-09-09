// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Voting {
    address public admin;
    enum ElectionStatus { NotStarted, Open, Closed, Archived }
    struct Election {
        string name;
        string ipfsMetaHash;
        string[] candidates;
        ElectionStatus status;
        mapping(string => uint256) votes;
        mapping(address => bool) voted;
        bool exists;
    }

    mapping(uint256 => Election) public elections;
    uint256 public electionCount;

    event ElectionCreated(uint256 electionId, string name, string ipfsMetaHash, string[] candidates);
    event ElectionStatusChanged(uint256 electionId, ElectionStatus status);
    event Voted(uint256 indexed electionId, string candidate, address voter);

    modifier onlyAdmin() { require(msg.sender == admin, "Only admin can call this function"); }

    constructor() { admin = msg.sender; }

    function createElection(
        string memory _name,
        string memory _ipfsMetaHash,
        string[] memory _candidates
    ) public onlyAdmin {
        require(_candidates.length > 0, "Candidates required");
        Election storage e = elections[electionCount];
        e.name = _name;
        e.ipfsMetaHash = _ipfsMetaHash;
        for (uint i = 0; i < _candidates.length; i++) {
            e.candidates.push(_candidates[i]);
        }
        e.status = ElectionStatus.NotStarted;
        e.exists = true;
        emit ElectionCreated(electionCount, _name, _ipfsMetaHash, _candidates);
        electionCount++;
    }

    function openElection(uint256 _electionId) public onlyAdmin {
        Election storage e = elections[_electionId];
        require(e.exists, "Election does not exist");
        e.status = ElectionStatus.Open;
        emit ElectionStatusChanged(_electionId, ElectionStatus.Open);
    }

    function closeElection(uint256 _electionId) public onlyAdmin {
        Election storage e = elections[_electionId];
        require(e.exists, "Election does not exist");
        e.status = ElectionStatus.Closed;
        emit ElectionStatusChanged(_electionId, ElectionStatus.Closed);
    }

    function vote(uint256 _electionId, string memory _candidate) public {
        Election storage e = elections[_electionId];
        require(e.exists, "Election does not exist");
        require(e.status == ElectionStatus.Open, "Election not open");
        require(!e.voted[msg.sender], "Already voted");
        bool validCandidate = false;
        for (uint i = 0; i < e.candidates.length; i++) {
            if (keccak256(bytes(e.candidates[i])) == keccak256(bytes(_candidate))) {
                validCandidate = true;
            }
        }
        require(validCandidate, "Invalid candidate");
        e.votes[_candidate++;
        e.voted[msg.sender] = true;
        emit Voted(_electionId, _candidate, msg.sender);
    }

    function getVotes(uint256 _electionId, string memory _candidate) public view returns (uint256) {
        Election storage e = elections[_electionId];
        require(e.exists, "Election does not exist");
        return e.votes[_candidate];
    }

    function getCandidates(uint256 _electionId) public view returns (string[] memory) {
        Election storage e = elections[_electionId];
        require(e.exists, "Election does not exist");
        return e.candidates;
    }

    function getElection(uint256 _electionId) public view returns (
        string memory name, string memory ipfsMetaHash, ElectionStatus status, string[] memory candidates
    ) {
        Election storage e = elections[_electionId];
        require(e.exists, "Election does not exist");
        return (e.name, e.ipfsMetaHash, e.status, e.candidates);
    }

    function getAllVotes(uint256 _electionId) public view returns (string[] memory candidateNames, uint256[] memory candidateVotes) {
        Election storage e = elections[_electionId];
        require(e.exists, "Election does not exist");
        uint total = e.candidates.length;
        candidateNames = new string[](total);
        candidateVotes = new uint256[](total);
        for (uint i = 0; i < total; i++) {
            candidateNames[i] = e.candidates[i];
            candidateVotes[i] = e.votes[e.candidates[i]];
        }
        return (candidateNames, candidateVotes);
    }
}