# TimeLock token vault.

TimeLock is an implementation of a vault used to lock a single ERC-20 token for a given amount of time using exclusively onchain data for the locking mechanism.

Functionality has been kept simple as to prevent vulnerabilities as much as possible, this code has not yet been audited by professional auditors.

The two functions available for this contract are: 
`makeDeposit(uint256 _lockTime, uint256 _amount)` is used to deposit ERC20 tokens into the contract, each user can only create one deposit at a time and they choose how long it will last. The user cannot create another deposit while they have an active one and to create a new one they need to withdraw the tokens from the first deposit.
`withdraw()` is used to withdraw all of the the deposited ERC20 tokens from the contract, can only be called by the person who deposited funds in order to claim their own tokens.
The withdraw function will always claim all of the tokens that have been locked up by the user.

Standard forge usage applies, to install necessary interface:
```
forge install
```
To compile or build the project:
```
forge build
```
Testing the whole suite: 
```
forge test
```
Getting test coverage:
```
forge coverage
```
Or running only a specific test:
```
forge test --match-test (TEST_NAME)
```

