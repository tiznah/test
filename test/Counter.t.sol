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
    address public addr2;

    uint256 constant LOCK_TIME = 1 days; // Lock for 1 day
    uint256 constant INITIAL_SUPPLY = 1000000 ether;
    uint256 amount = 1 ether;

    function setUp() public {
        owner = address(this);
        addr1 = address(0x1);
        addr2 = address(0x2);

        token = new MockERC20("MockToken", "MTK", INITIAL_SUPPLY);
        token.mint(owner, INITIAL_SUPPLY);

        timelock = new TimeLock(address(token));
    }

    function testDeposit() public {
        token.transfer(addr1, amount);

        vm.startPrank(addr1);
        token.approve(address(timelock), amount);
        timelock.makeDeposit(LOCK_TIME, amount);
        vm.stopPrank();

        // Check if the deposit was successful by verifying the balance of the timelock contract
        assertEq(token.balanceOf(address(timelock)), amount, "Deposit amount mismatch");
    }

    function testFailWithdrawByNonOwner() public {
        token.transfer(addr1, amount);
        token.transfer(addr2, amount);

        vm.startPrank(addr1);
        token.approve(address(timelock), amount);
        timelock.makeDeposit(LOCK_TIME, amount);
        vm.stopPrank();

        // Second address cannot withdraw because they don't have an active timelock
        vm.startPrank(addr2);
        timelock.withdraw();
        vm.expectRevert(TimeLock.NoActiveLocks.selector);
        vm.stopPrank();
    }

 function testWithdraw() public {
        // Approve tokens for transfer
        vm.prank(owner);
        token.approve(address(timelock), amount);

        // Make a deposit
        vm.prank(owner);
        timelock.makeDeposit(LOCK_TIME, amount);

        // Fast forward time past the lock period
        vm.warp(block.timestamp + LOCK_TIME + 1);

        // Get balances before withdrawal
        uint256 ownerBalanceBefore = token.balanceOf(owner);
        uint256 contractBalanceBefore = token.balanceOf(address(timelock));

        // Withdraw the tokens
        vm.prank(owner);
        timelock.withdraw();

        // Get balances after withdrawal
        uint256 ownerBalanceAfter = token.balanceOf(owner);
        uint256 contractBalanceAfter = token.balanceOf(address(timelock));

        // Check if the contract's balance decreased correctly
        assertEq(contractBalanceAfter, contractBalanceBefore - amount, "Contract balance should decrease by withdrawal amount");

        // Check if the owner's balance increased correctly
        assertEq(ownerBalanceAfter, ownerBalanceBefore + amount, "Owner balance should increase by withdrawal amount");

        // Check if the deposit was cleared (amount set to 0)
        uint256 index = timelock.getDepositIndex();
        (, uint256 amountAfter, ) = timelock.deposits(index);
        assertEq(amountAfter, 0, "Deposit amount should be zero after withdrawal");


    }
}

