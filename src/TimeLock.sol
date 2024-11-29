// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Timelock
/// @author Tiznah
/// @notice Lock ERC20 tokens for a certain amount of blocks and then claim.
/// @dev Version 1 using only onchain data, single token, future upgrades will use oracles and support multiple tokens.

contract TimeLock is Ownable{
 
    // Custom errors
    error MustBeGreaterThanZero();
    error TokensNotUnlocked();
    error TransferFailed();
    error TokensAlreadyUnlocked();

    // Events
    event LockCreated(uint256 indexed _lockTime, address indexed _tokenAddress, uint256 indexed endingTime);
    event DepositCreated(uint256 indexed _amount);
    event WithdrawCreated(uint256 indexed _amount);

    // immutable variables since they don't change after being defined
    uint256 immutable startingTime;
    uint256 immutable lockTime;
    uint256 immutable endingTime;
    IERC20 public immutable token;

    // @param _lockTime is the amount of time (in seconds) the token will be locked for
    // @param _tokenAddress is the address of the chosen token for the timelock
    // @notice only the owner can deposit, withdraw and it can only be used with the chosen token
    constructor(uint256 _lockTime, address _tokenAddress) Ownable(msg.sender) {
        token = IERC20(_tokenAddress);
        lockTime = _lockTime;
        startingTime = block.timestamp;
        endingTime = block.timestamp + _lockTime;
        emit LockCreated(_lockTime, _tokenAddress, endingTime);
    }

    // Deposit tokens into the contract as long as the lock has not passed.
    function deposit(uint256 _amount) public onlyOwner{
        require(block.timestamp <= endingTime, TokensAlreadyUnlocked());
        require(_amount > 0, MustBeGreaterThanZero());
        require(token.transferFrom(msg.sender,address(this),_amount), TransferFailed());
        emit DepositCreated(_amount);
    }

    // Withdraw tokens into the contract as long as the lock has already passed.
    function withdraw(uint256 _amount) public onlyOwner {
        require(block.timestamp >=  endingTime, TokensNotUnlocked());
        require(_amount > 0, MustBeGreaterThanZero());
        require(token.transfer(msg.sender,_amount), TransferFailed());
        emit WithdrawCreated(_amount);
    }

}
 