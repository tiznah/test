// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/TimeLock.sol"; // Assuming your contract is at src/TimeLock.sol

contract DeployTimeLockScript is Script {
    function run() external {
        vm.startBroadcast();
        // MOG address 
        address tokenAddress = 0x2Da56AcB9Ea78330f947bD57C54119Debda7AF71; 
        // A year in seconds
        uint256 lockTimeInSeconds = 365*24*60*60;

        TimeLock timelock = new TimeLock(lockTimeInSeconds, tokenAddress);

        console.log("TimeLock deployed at:", address(timelock));

        vm.stopBroadcast();
    }
}
