// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleTimelock is Ownable {
    uint256 public delay;

    struct QueuedTx {
        address target;
        uint256 value;
        bytes data;
        uint256 executeAfter;
    }

    mapping(bytes32 => QueuedTx) public queue;

    event Queued(bytes32 txHash, address target, uint256 value, bytes data, uint256 executeAfter);
    event Executed(bytes32 txHash, address target, uint256 value);

    constructor(uint256 _delay) {
        require(_delay >= 1 hours, "Delay too short");
        delay = _delay;
        transferOwnership(msg.sender); // 必要，因為 Ownable 沒自動設置 owner
    }

    function queueTx(address target, uint256 value, bytes calldata data) external onlyOwner returns (bytes32) {
        uint256 eta = block.timestamp + delay;
        bytes32 txHash = keccak256(abi.encode(target, value, data, eta));
        queue[txHash] = QueuedTx(target, value, data, eta);
        emit Queued(txHash, target, value, data, eta);
        return txHash;
    }

    function executeTx(bytes32 txHash) external onlyOwner {
        QueuedTx memory txn = queue[txHash];
        require(txn.executeAfter > 0 && block.timestamp >= txn.executeAfter, "Not ready");
        delete queue[txHash];
        (bool success, ) = txn.target.call{value: txn.value}(txn.data);
        require(success, "Call failed");
        emit Executed(txHash, txn.target, txn.value);
    }
}
