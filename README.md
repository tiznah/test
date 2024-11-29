# TimeLock token vault.

TimeLockV1 is a barebones implementation of a personal vault used to lock a single ERC-20 token for a given amount of time using exclusively onchain data for the locking mechanism.

Functionality has been kept simple as to prevent vulnerabilities as much as possible, this code has not yet been audited by professional auditors.

The two functions available for this contract are: 
`deposit(uint256 _amount)` is used to deposit ERC20 tokens into the contract, this can only be called by the owner, or the contract's creator, bear in mind only the allowed token for a given vault can be deposited.

`withdraw(uint256 _amount)` is used to withdraw the deposited ERC20 tokens into the contract, can only be called by the owner or the contract's creator, only the allowed token can be withdrawn, all other tokens incluiding native tokens will get burnt.

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
For deployment without exposing one's private key [Remix](https://remix.ethereum.org) may be used on any EVM equivalent chain by flattening the code with forge to simplify verification:
```
forge flatten TimeLock.sol
```
The cotract's constructor parameters are as follows:
```
 constructor(uint256 _lockTime, address _tokenAddress) 
``` 
Meaning the  arguments when deploying the contract should be like so:
```
lockTime (in seconds), tokenAddress (Token's contract address)
```

Approvals should be given to the contract manually on the token's address, [Etherscan](https://etherscan.io/) is a good choice to give approvals.
Once approved call the `deposit()` function to deposit tokens which can only be retrieved with the `withdraw()` function after the chosen time has passed.
# Future Plans (Personal note)
This is the first project I start on my own and even my first repository that is not for schoolwork or a tutorial, this first implementation is EXTREMELY jank and barebones to a fault but it will be the project I learn with, my future plans for 
this project include:
1.- Support for multiple tokens
2.- NFT support
3.- FlipLock mode where you can lock ERC20 tokens until their marketcap flips a chosen token's marketcap using decentralized oracles.

All of this without mentioning general quality of life upgrades such as a usable front end and better security for tokens. 