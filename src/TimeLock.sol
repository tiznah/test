// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Timelock.
/// @author Tiznah.
/// @notice Lock ERC20 tokens for a certain amount of blocks and then claim.
/// @dev Version 2 using only onchain data, single token, multiple users each with their own lockup time.

contract TimeLock {
    // Custom errors.
    error MustBeGreaterThanZero();
    error TokensNotUnlocked();
    error TransferFailed();
    error TokensAlreadyUnlocked();
    error CanOnlyHaveOneActiveLock();
    error NoActiveLocks();
    error MustHaveAnActiveLock();

    // Structs
    // Struct to keep track of the user address, amount deposited and block.timestamp in which their tokens will unlock.
    struct Deposit {
        address user;
        uint256 amount;
        uint256 endingTime;
    }

    // Arrays.
    Deposit[] public deposits;

    // Events.
    event LockCreated(address indexed _tokenAddress);
    event DepositCreated(address indexed user, uint256 indexed _amount, uint256 indexed endingTime);
    event WithdrawCreated(uint256 indexed _amount);

    // immutable variables since they don't change after being defined.
    IERC20 public immutable token;

    // @param _tokenAddress is the address of the ERC20 token the contract will lock.
    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
        emit LockCreated(_tokenAddress);
    }

    // makeDeposit function lets a user deposit their tokens for a chosen amount of time.
    // @param _lockTime is the amount of time in seconds that specific deposit will last.
    // @param _amount is the amount of tokens will be locked up in the deposit.
    function makeDeposit(uint256 _lockTime, uint256 _amount) external {
        require(_amount > 0, MustBeGreaterThanZero());
        uint256 _endingTime = block.timestamp + _lockTime; // Calcualte the time when the tokens should unlock

        uint256 index = getDepositIndex(); // Get the index in the deposits array from the msg.sender
        if (index == type(uint256).max) {
            // if there are no active timelocks push a new deposit struct into the array
            require(token.transferFrom(msg.sender, address(this), _amount), TransferFailed());
            deposits.push(Deposit(msg.sender, _amount, _endingTime));
            emit DepositCreated(msg.sender, _amount, _endingTime);
        } else {
            // if there is an active or past timelock ensure the user has withdrawn before making another deposit
            require(deposits[index].amount == 0, CanOnlyHaveOneActiveLock());
            deposits[index].amount = _amount;
            deposits[index].endingTime = _endingTime;
            emit DepositCreated(msg.sender, _amount, _endingTime);
        }
    }

    // Withdraw function lets users withdraw their deposit if the lock time has passed.
    function withdraw() external {
        uint256 index = getDepositIndex(); // Get the index in the deposits array from the msg.sender
        require(index != type(uint256).max, NoActiveLocks());
        Deposit storage _deposit = deposits[index];
        require(_deposit.amount != 0, MustHaveAnActiveLock()); // if the deposited amount is zero there are no tokens to withdraw
        require(block.timestamp >= _deposit.endingTime, TokensNotUnlocked());
        require(token.transfer(msg.sender, _deposit.amount), TransferFailed());
        deposits[index].amount = 0; // change amount for that deposit to zero to indicate it has been withdrawn
        emit WithdrawCreated(_deposit.amount);
    }

    // Helper functions
    function getDepositIndex() public view returns (uint256) {
        for (uint256 i = 0; i < deposits.length; i++) {
            if (deposits[i].user == msg.sender) {
                return i;
            }
        }
        return type(uint256).max; // if the user was not found return the max uint256
    }
}
