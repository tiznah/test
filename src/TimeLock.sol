// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

using SafeERC20 for IERC20;
/// @title Timelock.
/// @author Tiznah.
/// @notice Lock ERC20 tokens for a certain amount of blocks and then claim.
/// @dev Version 2 using only onchain data, single token, multiple users can choose their own lock time.

contract TimeLock {
    // Custom errors.
    error MustBeGreaterThanZero();
    error TokensNotUnlocked();
    error TransferFailed();
    error TokensAlreadyUnlocked();
    error CanOnlyHaveOneActiveLock();
    error NoActiveLocks();
    error MustHaveAnActiveLock();

    // Structs.
    struct Deposit {
        uint256 amount;
        uint256 endingTime;
    }

    // Mappings.
    mapping(address => Deposit[]) public userDeposits;

    // Events.
    event LockCreated(address indexed _tokenAddress);
    event DepositCreated(address indexed user, uint256 indexed _amount, uint256 indexed endingTime);
    event WithdrawCreated(uint256 indexed _amount);

    // immutable variables since they don't change after being defined.
    IERC20 public immutable token;

    // @param _tokenAddress is the address of the ERC20 token the contract will lock, using only one for simplicity.
    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
        emit LockCreated(_tokenAddress);
    }

    // Function to deposit token into the contract.
    // @param _lockTime is the time in seconds the user will lock the tokens for.
    // @param _amount is the amount of tokens that will be locked.
    function makeDeposit(uint256 _lockTime, uint256 _amount) external {
        if (_amount == 0) revert MustBeGreaterThanZero();
        uint256 _endingTime = block.timestamp + _lockTime; // calculate the time when the tokens should unlock by adding the current timestamp

        // Access user's deposit array
        Deposit[] storage deposits = userDeposits[msg.sender];
        bool hasActiveDeposit = false;

        // Checking for active deposits by the user.
        for (uint256 i = 0; i < deposits.length; i++) {
            if (deposits[i].endingTime > block.timestamp) {
                hasActiveDeposit = true;
                break;
            }
        }
        if (hasActiveDeposit) {
            revert CanOnlyHaveOneActiveLock();
        } else {
            deposits.push(Deposit(_amount, _endingTime)); // Here we don't store user since it's already part of the mapping key
            emit DepositCreated(msg.sender, _amount, _endingTime);
            token.safeTransferFrom(msg.sender, address(this), _amount);
        }
    }

    // Withdraw function lets users withdraw their deposit if the lock time has passed.
    function withdraw() external {
        // Access user's deposits and check that there have been deposits in the past.
        Deposit[] storage deposits = userDeposits[msg.sender];
        if (deposits.length == 0) revert NoActiveLocks(); // Must have an active lock
        // Find the first active deposit for the user
        for (uint256 i = 0; i < deposits.length; i++) {
            if (deposits[i].amount > 0) {
                uint256 _amount = deposits[i].amount;
                if (block.timestamp <= deposits[i].endingTime) revert TokensNotUnlocked();
                deposits[i].amount = 0; // Mark this deposit as withdrawn before the state change in order to follow CEI
                token.safeTransfer(msg.sender, _amount);
                emit WithdrawCreated(_amount);
                return;
            }
        }
        revert MustHaveAnActiveLock(); // If no active deposit found
    }
}
