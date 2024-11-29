// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/TimeLock.sol";
import "./mocks/MockERC20.sol"; // You'll need to create this mock token for testing

contract TimeLockTest is Test {
    TimeLock public timelock;
    MockERC20 public token;
    address public owner;
    address public addr1;

    uint256 constant LOCK_TIME = 1 days; // Lock for 1 day
    uint256 constant INITIAL_SUPPLY = 1000000 ether;

    function setUp() public {
        owner = address(this);
        addr1 = address(0x1);

        token = new MockERC20("MockToken", "MTK", INITIAL_SUPPLY);
        token.mint(owner, INITIAL_SUPPLY);

        timelock = new TimeLock(LOCK_TIME, address(token));
    }

    function testDeposit() public {
        uint256 amount = 1 ether;
        token.approve(address(timelock), amount);
        
        timelock.deposit(amount);
        assertEq(token.balanceOf(address(timelock)), amount, "Deposit amount mismatch");
    }

    function testFailDepositFromNonOwner() public {
        vm.startPrank(addr1); 
        token.approve(address(timelock), 1 ether);
        timelock.deposit(1 ether);
        vm.stopPrank();
    }

function testWithdraw() public {
    uint256 amount = 1 ether;

    token.approve(address(timelock), amount);
    timelock.deposit(amount);

    vm.warp(block.timestamp + LOCK_TIME + 1); 

    uint256 ownerBalanceBefore = token.balanceOf(owner);
    uint256 contractBalanceBefore = token.balanceOf(address(timelock));

    timelock.withdraw(amount);

    uint256 ownerBalanceAfter = token.balanceOf(owner);
    uint256 contractBalanceAfter = token.balanceOf(address(timelock));

    assertEq(contractBalanceAfter, contractBalanceBefore - amount, "Contract should have zero tokens after withdrawal");
    assertEq(ownerBalanceAfter, ownerBalanceBefore + amount, "Owner should have received the withdrawn amount");
}
    function testFailWithdrawBeforeLockTime() public {
        uint256 amount = 1 ether;
        token.approve(address(timelock), amount);
        timelock.deposit(amount);

        timelock.withdraw(amount);
    }

    function testFailWithdrawByNonOwner() public {
        uint256 amount = 1 ether;
        token.approve(address(timelock), amount);
        timelock.deposit(amount);

        vm.warp(block.timestamp + LOCK_TIME + 1);
        vm.startPrank(addr1); // Simulate transaction from addr1
        timelock.withdraw(amount);
        vm.stopPrank();
    }
}