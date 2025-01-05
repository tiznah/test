// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/TimeLock.sol";
import "./mocks/MockERC20.sol";

contract TimeLockTest is Test {
    TimeLock public timelock;
    MockERC20 public token;
    address public owner;
    address public addr1;
    address public addr2;

    uint256 constant LOCK_TIME = 1 days; // Lock for 1 day each as an example
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
        assertEq(token.balanceOf(address(timelock)), amount, "Deposit amount mismatch");
    }

    function testFailDepositZeroAmount() public {
        vm.startPrank(addr1);
        token.approve(address(timelock), amount);
        vm.expectRevert(TimeLock.MustBeGreaterThanZero.selector);
        timelock.makeDeposit(LOCK_TIME, 0);
        vm.stopPrank();
    }

    function testFailDepositWithExistingActiveLock() public {
        token.transfer(addr1, amount * 2);
        vm.startPrank(addr1);
        token.approve(address(timelock), amount * 2);
        timelock.makeDeposit(LOCK_TIME, amount);
        // Try to make another deposit before the lock expires
        vm.expectRevert(TimeLock.CanOnlyHaveOneActiveLock.selector);
        timelock.makeDeposit(LOCK_TIME, amount);
    }

    function testFailWithdrawByNonOwner() public {
        token.transfer(addr1, amount);
        token.transfer(addr2, amount);
        vm.startPrank(addr1);
        token.approve(address(timelock), amount);
        timelock.makeDeposit(LOCK_TIME, amount);
        vm.startPrank(addr2);
        vm.expectRevert(TimeLock.NoActiveLocks.selector);
        timelock.withdraw();
    }

    function testWithdraw() public {
        vm.prank(owner);
        token.approve(address(timelock), amount);
        timelock.makeDeposit(LOCK_TIME, amount);
        vm.warp(block.timestamp + LOCK_TIME + 1);
        uint256 ownerBalanceBefore = token.balanceOf(owner);
        uint256 contractBalanceBefore = token.balanceOf(address(timelock));
        timelock.withdraw();
        uint256 ownerBalanceAfter = token.balanceOf(owner);
        uint256 contractBalanceAfter = token.balanceOf(address(timelock));
        assertEq(
            contractBalanceAfter,
            contractBalanceBefore - amount,
            "Contract balance should decrease by withdrawal amount"
        );
        assertEq(ownerBalanceAfter, ownerBalanceBefore + amount, "Owner balance should increase by withdrawal amount");
    }

    function testFailWithdrawBeforeLockTime() public {
        vm.prank(owner);
        token.approve(address(timelock), amount);
        timelock.makeDeposit(LOCK_TIME, amount);
        // Trying to withdraw before the lock period
        vm.expectRevert(TimeLock.TokensNotUnlocked.selector);
        timelock.withdraw();
    }

    function testFailWithdrawWithNoActiveLocks() public {
        // No deposits made, so withdrawal should fail
        vm.prank(owner);
        vm.expectRevert(TimeLock.NoActiveLocks.selector);
        timelock.withdraw();
    }

    function testFailTransferInDepositFails() public {
        // Mock transferFrom to fail
        vm.mockCall(
            address(token),
            abi.encodeWithSelector(IERC20.transferFrom.selector, addr1, address(timelock), amount),
            abi.encode(false)
        );
        vm.startPrank(addr1);
        token.approve(address(timelock), amount);
        vm.expectRevert();
        timelock.makeDeposit(LOCK_TIME, amount);
    }

    function testFailTransferInWithdrawFails() public {
        // Mock transfer to fail
        vm.mockCall(address(token), abi.encodeWithSelector(IERC20.transfer.selector, owner, amount), abi.encode(false));
        vm.prank(owner);
        token.approve(address(timelock), amount);
        vm.prank(owner);
        timelock.makeDeposit(LOCK_TIME, amount);
        vm.warp(block.timestamp + LOCK_TIME + 1);
        vm.prank(owner);
        vm.expectRevert();
        timelock.withdraw();
    }
}
