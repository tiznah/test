// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/// @title Timelock
/// @author Tiznah
/// @notice Lock ERC20 tokens for a certain amount of blocks and then claim.
/// @dev Version 1 using only onchain data, single token, future upgrades will use oracles and support multiple tokens.

contract TimeLock {
    uint256 immutable startingTime;
    uint256 immutable lockTime;
    uint256 immutable endingTime;
    address immutable owner;
    IERC20 public immutable token;

    constructor(uint256 _lockTime, address _tokenAddress) {
        owner = msg.sender;
        token = IERC20(_tokenAddress);
        lockTime = _lockTime;
        startingTime = block.timestamp;
        endingTime = block.timestamp + _lockTime;
    }
    function deposit(uint256 _amount) public {
        require(msg.sender == owner, "Only the owner can call this function");
        require(_amount > 0, "deposit must be greater than zero");
        require(token.transferFrom(msg.sender,address(this),_amount), "transfer failed");
    }

    function withdraw(uint256 _amount) public{
        require(msg.sender == owner, "Only the owner can call this function"); 
        require(block.timestamp >=  endingTime, "Tokens have not been unlocked yet");
        require(_amount > 0, "withdraw must be greater than zero");
        require(token.transfer(msg.sender,_amount), "transfer failed");
    }

}
 