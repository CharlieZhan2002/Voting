// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
        bool voteFor;  // 表示投票赞成还是反对
    }

    struct Proposal {
        uint256 id;
        string description;
        uint256 voteForCount;
        uint256 voteAgainstCount;
    }

    bool public votingStarted;
    uint256 public proposalCount;
    address[] public voterAddresses; // 存储所有已注册的投票者地址
    mapping(address => Voter) public voters;
    mapping(uint256 => Proposal) public proposals;

    event VoterRegistered(address voter);
    event ProposalAdded(uint256 proposalId, string description);
    event VoteCasted(address voter, uint256 proposalId, bool voteFor);
    event VotingStarted();
    event VotingEnded();

    modifier onlyRegisteredVoter() {
        require(voters[msg.sender].isRegistered, "You must be a registered voter");
        _;
    }

    modifier whenVotingNotStarted() {
        require(!votingStarted, "Voting has already started");
        _;
    }

    modifier whenVotingStarted() {
        require(votingStarted, "Voting has not started yet");
        _;
    }

    constructor() {
        votingStarted = false;
        proposalCount = 0;
    }

    // 允许任何人注册自己为投票者
    function registerVoter() public whenVotingNotStarted {
        require(!voters[msg.sender].isRegistered, "You are already registered");
        voters[msg.sender] = Voter(true, false, 0, false);
        voterAddresses.push(msg.sender); // 保存投票者地址
        emit VoterRegistered(msg.sender);
    }

    // 允许任何人添加提案
    function addProposal(string memory _description) public whenVotingNotStarted {
        proposalCount++;
        proposals[proposalCount] = Proposal(proposalCount, _description, 0, 0);
        emit ProposalAdded(proposalCount, _description);
    }

    // 允许任何人开始投票
    function startVoting() public whenVotingNotStarted {
        votingStarted = true;
        emit VotingStarted();
    }

    // 允许任何人结束投票并重置所有投票者的状态
    function endVoting() public whenVotingStarted {
        votingStarted = false;
        emit VotingEnded();

        // 重置所有投票者的状态，允许他们在下一轮投票前重新注册
        for (uint256 i = 0; i < voterAddresses.length; i++) {
            voters[voterAddresses[i]].hasVoted = false;
        }
    }

    // 投票
    function vote(uint256 _proposalId, bool _voteFor) public onlyRegisteredVoter whenVotingStarted {
        Voter storage sender = voters[msg.sender];
        
        // 检查是否已经投过票
        require(!sender.hasVoted, "You have already voted");
        
        // 检查提案ID是否有效
        require(proposals[_proposalId].id != 0, "Invalid proposal ID");
        
        // 记录投票状态
        sender.hasVoted = true;
        sender.votedProposalId = _proposalId;
        sender.voteFor = _voteFor;

        // 更新提案的投票计数
        if (_voteFor) {
            proposals[_proposalId].voteForCount++;
        } else {
            proposals[_proposalId].voteAgainstCount++;
        }

        // 触发事件，记录投票信息
        emit VoteCasted(msg.sender, _proposalId, _voteFor);
    }

    // 结算提案
    function settleProposal(uint256 _proposalId) public view returns (string memory result) {
        require(proposals[_proposalId].id != 0, "Invalid proposal ID");

        if (proposals[_proposalId].voteForCount > proposals[_proposalId].voteAgainstCount) {
            return "Proposal Passed";
        } else if (proposals[_proposalId].voteAgainstCount > proposals[_proposalId].voteForCount) {
            return "Proposal Failed";
        } else {
            return "Tie";
        }
    }

    // 获取提案详情
    function getProposal(uint256 _proposalId) public view returns (uint256 id, string memory description, uint256 voteForCount, uint256 voteAgainstCount) {
        require(proposals[_proposalId].id != 0, "Invalid proposal ID");
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.id, proposal.description, proposal.voteForCount, proposal.voteAgainstCount);
    }
}
