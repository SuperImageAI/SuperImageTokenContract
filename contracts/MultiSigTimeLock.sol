// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract MultiSigTimeLock is Initializable, UUPSUpgradeable {
    struct Proposal {
        address target; //only for normal proposal
        bytes data; // only for normal proposal
        uint256 canExecuteAfterTimestamp;
        uint256 canVoteBeforeTimestamp;
        bool executed;
        ProposalType proposalType;
        address newSigner; //only for addSigner/remove signer proposals
        uint256 minDelaySeconds; // only for update min delay seconds proposal
        address canUpgradeAddress; //only for upgradeContract proposal

    }

    address[] public signers;
    uint256 public requiredApproveCount;
    uint256 public minDelaySeconds;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public approvals;
    uint256 public proposalCount;

    event ProposalCreated(
        uint256 indexed proposalId
    );

    enum ProposalType {Normal, UpgradeContract, AddSigner, RemoveSigner, UpdateMinDelaySeconds, DisableContractUpgrade}
    bool public disableUpgrade;
    address public canUpgradeAddress;

    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalApproved(uint256 indexed proposalId, address indexed signer);
    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);
    event RequiredSignaturesUpdated(uint256 newRequiredSignatures);
    event MinDelayUpdated(uint256 newMinDelaySeconds);
    event AuthorizedUpgradeSelf(address indexed canUpgradeAddress);
    event DisableContractUpgrade(uint256 timestamp);

    modifier onlySigner() {
        require(isSigner(msg.sender), "Not a signer");
        _;
    }

    function initialize(
        address[] memory _signers,
        uint256 _requiredApproveCount,
        uint256 _minDelaySeconds
    ) public initializer {
        require(_signers.length > 0, "Signers should not be empty");
        require(_requiredApproveCount == _signers.length/2 + 1, "Required signatures must be = signers/2 + 1");
        require(_minDelaySeconds > 0, "Min delay should be > 0");
        for (uint256 i = 0; i < _signers.length; i++) {
            require(_signers[i] != address(0), "Invalid signer address");
            for (uint256 j = i + 1; j < _signers.length; j++) {
                require(_signers[i] != _signers[j], "Duplicate signer address");
            }
        }

        signers = _signers;
        requiredApproveCount = _requiredApproveCount;
        minDelaySeconds = _minDelaySeconds;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function disableContractUpgrade() internal  {
        disableUpgrade = true;
        emit DisableContractUpgrade(block.timestamp);
    }

    function _authorizeUpgrade(address newImplementation) internal override  {
        require(msg.sender == canUpgradeAddress, "Only canUpgradeAddress can upgrade");
        require(newImplementation != address(0), "Invalid implementation address");
        canUpgradeAddress = address(0);
    }

    function isSigner(address account) public view returns (bool) {
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == account) {
                return true;
            }
        }
        return false;
    }

    function createProposal(
        address target,
        bytes memory data
    ) external onlySigner {
        uint256 _canVoteBeforeTimestamp = block.timestamp + minDelaySeconds;
        uint256 _canExecuteAfterTimestamp = _canVoteBeforeTimestamp + minDelaySeconds;
        require(target != address(0), "Invalid target address");

        proposals[proposalCount] = Proposal({
            target: target,
            data: data,
            canExecuteAfterTimestamp: _canExecuteAfterTimestamp,
            canVoteBeforeTimestamp: _canVoteBeforeTimestamp,
            executed: false,
            proposalType: ProposalType.Normal,
            newSigner: address(0),
            minDelaySeconds: 0,
            canUpgradeAddress:address(0)
        });

        emit ProposalCreated(proposalCount);
        approvals[proposalCount][msg.sender] = true;
        emit ProposalApproved(proposalCount, msg.sender);
        proposalCount++;
    }

    function createUpgradeContractProposal(address _canUpgradeAddress) external onlySigner {
        require(disableUpgrade == false, "Contract upgrade is disabled");
        uint256 _canVoteBeforeTimestamp = block.timestamp + minDelaySeconds;
        uint256 _canExecuteAfterTimestamp = _canVoteBeforeTimestamp + minDelaySeconds;

        proposals[proposalCount] = Proposal({
            target: address(0),
            data: "",
            canExecuteAfterTimestamp: _canExecuteAfterTimestamp,
            executed: false,
            proposalType: ProposalType.UpgradeContract,
            newSigner: address(0),
            canVoteBeforeTimestamp: _canVoteBeforeTimestamp,
            minDelaySeconds: 0,
            canUpgradeAddress:_canUpgradeAddress
        });

        emit ProposalCreated(proposalCount);
        proposalCount++;
    }

    function createUpdateMinDelaySecondsProposal(uint256 newMinDelaySeconds) external onlySigner {
        require(newMinDelaySeconds >0, "minDelaySeconds should be > 0");

        uint256 _canVoteBeforeTimestamp = block.timestamp + minDelaySeconds;
        uint256 _canExecuteAfterTimestamp = _canVoteBeforeTimestamp + minDelaySeconds;

        proposals[proposalCount] = Proposal({
            target: address(0),
            data: "",
            canExecuteAfterTimestamp: _canExecuteAfterTimestamp,
            executed: false,
            proposalType: ProposalType.UpdateMinDelaySeconds,
            newSigner: address(0),
            canVoteBeforeTimestamp: _canVoteBeforeTimestamp,
            minDelaySeconds: newMinDelaySeconds,
            canUpgradeAddress:address(0)
        });

        emit ProposalCreated(proposalCount);
        proposalCount++;
    }

    function createAddSignerProposal(address signer) external onlySigner {
        require(signer != address(0), "Invalid signer address");

        uint256 _canVoteBeforeTimestamp = block.timestamp + minDelaySeconds;
        uint256 _canExecuteAfterTimestamp = _canVoteBeforeTimestamp + minDelaySeconds;

        proposals[proposalCount] = Proposal({
            target: address(0),
            data: "",
            canExecuteAfterTimestamp: _canExecuteAfterTimestamp,
            executed: false,
            proposalType: ProposalType.AddSigner,
            newSigner: signer,
            canVoteBeforeTimestamp: _canVoteBeforeTimestamp,
            minDelaySeconds: 0,
            canUpgradeAddress:address(0)
        });

        emit ProposalCreated(proposalCount);
        proposalCount++;
    }

    function createRemoveSignerProposal(address signer) external onlySigner {
        require(signer != address(0), "Invalid signer address");

        uint256 _canVoteBeforeTimestamp = block.timestamp + minDelaySeconds;
        uint256 _canExecuteAfterTimestamp = _canVoteBeforeTimestamp + minDelaySeconds;

        proposals[proposalCount] = Proposal({
            target: address(0),
            data: "",
            canExecuteAfterTimestamp: _canExecuteAfterTimestamp,
            executed: false,
            proposalType: ProposalType.RemoveSigner,
            newSigner: signer,
            canVoteBeforeTimestamp: _canVoteBeforeTimestamp,
            minDelaySeconds: 0,
            canUpgradeAddress:address(0)
        });

        emit ProposalCreated(proposalCount);
        proposalCount++;
    }

    function approveProposal(uint256 proposalId) external onlySigner {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp <= proposal.canVoteBeforeTimestamp, "Vote period passed");
        require(!proposal.executed, "Proposal already executed");

        if (proposal.proposalType == ProposalType.Normal) {
            require(proposals[proposalId].target != address(0), "Invalid proposal");
        }
        else if (proposal.proposalType == ProposalType.AddSigner|| proposal.proposalType ==ProposalType.RemoveSigner) {
            require(proposal.newSigner != address(0), "Invalid new signer address");
        }
        else if (proposal.proposalType == ProposalType.UpdateMinDelaySeconds) {
            require(proposal.minDelaySeconds > 0, "Min delay should be > 0");
        }
        else if(proposal.proposalType == ProposalType.UpgradeContract){
        }

        require(!approvals[proposalId][msg.sender], "Already approved");

        approvals[proposalId][msg.sender] = true;

        emit ProposalApproved(proposalId, msg.sender);
    }

    function revokeApproveProposal(uint256 proposalId) external onlySigner {
        Proposal storage proposal = proposals[proposalId];

        require(block.timestamp <= proposal.canVoteBeforeTimestamp, "Vote period passed");
        require(!proposal.executed, "Proposal already executed");
        require(proposals[proposalId].target != address(0), "Invalid proposal");
        require(approvals[proposalId][msg.sender], "Not approved yet");

        approvals[proposalId][msg.sender] = false;
        emit ProposalApproved(proposalId, msg.sender);
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.canExecuteAfterTimestamp, "Delay not passed");
        require(!proposal.executed, "Proposal already executed");

        uint256 approvalCount = 0;
        for (uint256 i = 0; i < signers.length; i++) {
            if (approvals[proposalId][signers[i]]) {
                approvalCount++;
            }
        }
        require(approvalCount >= requiredApproveCount, "Insufficient approvals");

        proposal.executed = true;

        if (proposal.proposalType == ProposalType.UpgradeContract) {
            canUpgradeAddress = proposal.canUpgradeAddress;
            emit AuthorizedUpgradeSelf(proposal.canUpgradeAddress);

        } else if (proposal.proposalType == ProposalType.AddSigner) {
            addSigner(proposal.newSigner);
        } else if (proposal.proposalType == ProposalType.RemoveSigner) {
            removeSigner(proposal.newSigner);
        }else if (proposal.proposalType == ProposalType.UpdateMinDelaySeconds){
            updateMinDelaySeconds(proposal.minDelaySeconds);
        }else if (proposal.proposalType == ProposalType.Normal){
            (bool success, ) = proposal.target.call{value: 0}(proposal.data);
            require(success, "Execution failed");
        }else if (proposal.proposalType == ProposalType.DisableContractUpgrade){
            disableContractUpgrade();
        }

        emit ProposalExecuted(proposalId);
    }

    function addSigner(address newSigner) internal {
        require(newSigner != address(0), "Invalid signer address");

        signers.push(newSigner);
        requiredApproveCount = signers.length/2 +1;

        emit SignerAdded(newSigner);
    }

    function removeSigner(address signer) internal  {
        require(signer != address(0), "Invalid signer address");

        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == signer) {
                signers[i] = signers[signers.length - 1];
                signers.pop();
                emit SignerRemoved(signer);
                break;
            }
        }
        requiredApproveCount = signers.length/2 + 1;
    }

    function updateMinDelaySeconds(uint256 newMinDelaySeconds) internal {
        require(newMinDelaySeconds > 0, "Min delay should be > 0");
        minDelaySeconds = newMinDelaySeconds;
        emit MinDelayUpdated(newMinDelaySeconds);
    }

    function getProposal(uint256 proposalId)
    external
    view
    returns (
        Proposal memory
    )
    {
        Proposal memory proposal = proposals[proposalId];
        return proposal;
    }

    function getApprovalStatus(uint256 proposalId, address signer) external view returns (bool) {
        return approvals[proposalId][signer];
    }

    function createDisableUpgradeForCurrentContractProposal() external onlySigner {

        uint256 _canVoteBeforeTimestamp = block.timestamp + minDelaySeconds;
        uint256 _canExecuteAfterTimestamp = _canVoteBeforeTimestamp + minDelaySeconds;

        proposals[proposalCount] = Proposal({
            target: address(0),
            data: "",
            canExecuteAfterTimestamp: _canExecuteAfterTimestamp,
            executed: false,
            proposalType: ProposalType.DisableContractUpgrade,
            newSigner: address(0),
            canVoteBeforeTimestamp: _canVoteBeforeTimestamp,
            minDelaySeconds: 0,
            canUpgradeAddress:address(0)
        });

        emit ProposalCreated(proposalCount);
        proposalCount++;
    }

    function version() external pure returns (int256)  {
        return 0;
    }
}
