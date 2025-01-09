// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MultiSigWallet {
    // Events
    event TransactionSubmitted(uint256 txId, address indexed proposer);
    event TransactionApproved(uint256 txId, address indexed approver);
    event TransactionRevoked(uint256 txId, address indexed revoker);
    event TransactionExecuted(uint256 txId);
    event SignerAdded(address indexed newSigner);
    event SignerRemoved(address indexed removedSigner);
    event DebugLog(address to, uint256 value, uint256 balance);

    // Constants
    uint256 public constant MIN_SIGNERS = 3;
    uint256 public constant REQUIRED_APPROVALS = 2;

    // State variables
    address[] public signers;
    mapping(address => bool) public isSigner;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 approvals;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public approvals;

    // Modifiers
    modifier onlySigner() {
        require(isSigner[msg.sender], "Not a signer");
        _;
    }

    modifier txExists(uint256 txId) {
        require(txId < transactions.length, "Transaction does not exist");
        _;
    }

    modifier notExecuted(uint256 txId) {
        require(!transactions[txId].executed, "Transaction already executed");
        _;
    }

    modifier notApproved(uint256 txId) {
        require(!approvals[txId][msg.sender], "Transaction already approved");
        _;
    }

    // Constructor
    constructor(address[] memory initialSigners) {
        require(initialSigners.length >= MIN_SIGNERS, "Not enough initial signers");
        for (uint256 i = 0; i < initialSigners.length; i++) {
            address signer = initialSigners[i];
            require(signer != address(0), "Invalid signer address");
            require(!isSigner[signer], "Signer not unique");

            isSigner[signer] = true;
            signers.push(signer);
        }
    }

    // Functions

    // Submit a transaction
    function submitTransaction(address to, uint256 value, bytes memory data) external onlySigner {
        transactions.push(Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            approvals: 0
        }));

        emit TransactionSubmitted(transactions.length - 1, msg.sender);
    }

    // Approve a transaction
    function approveTransaction(uint256 txId) 
        external 
        onlySigner 
        txExists(txId) 
        notExecuted(txId) 
        notApproved(txId) 
    {
        approvals[txId][msg.sender] = true;
        transactions[txId].approvals++;

        emit TransactionApproved(txId, msg.sender);
    }

    // Revoke approval
    function revokeApproval(uint256 txId) 
        external 
        onlySigner 
        txExists(txId) 
        notExecuted(txId) 
    {
        require(approvals[txId][msg.sender], "Transaction not approved");
        approvals[txId][msg.sender] = false;
        transactions[txId].approvals--;

        emit TransactionRevoked(txId, msg.sender);
    }

    // Execute a transaction
    function executeTransaction(uint256 txId) 
        external 
        onlySigner 
        txExists(txId) 
        notExecuted(txId) 
    {
        require(transactions[txId].approvals >= REQUIRED_APPROVALS, "Not enough approvals");

        Transaction storage txn = transactions[txId];
        txn.executed = true;

        // Émet des logs pour déboguer
        emit DebugLog(txn.to, txn.value, address(this).balance);

        (bool success, ) = txn.to.call(abi.encodeWithSignature("getData()"));
        require(success, "Transaction failed");

        emit TransactionExecuted(txId);
    }

    // Add a new signer
    function addSigner(address newSigner) external onlySigner {
        require(newSigner != address(0), "Invalid address");
        require(!isSigner[newSigner], "Already a signer");

        signers.push(newSigner);
        isSigner[newSigner] = true;

        emit SignerAdded(newSigner);
    }

    // Remove an existing signer
    function removeSigner(address signer) external onlySigner {
        require(isSigner[signer], "Not a signer");
        require(signers.length > MIN_SIGNERS, "Cannot have less than 3 signers");

        isSigner[signer] = false;

        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == signer) {
                signers[i] = signers[signers.length - 1];
                signers.pop();
                break;
            }
        }

        emit SignerRemoved(signer);
    }

    // Get all signers
    function getSigners() external view returns (address[] memory) {
        return signers;
    }
}
