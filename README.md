# DnD On-Chain Game

A decentralized role-playing game built on Ethereum using Foundry.

## Overview

This project implements a DnD-inspired on-chain game with the following features:
- [x] Character NFTs with stats and equipment slots
- [x] Equipment NFTs for weapons and armor
- [x] In-game currency (GAME token)
- [x] Quest system with rewards
- [ ] Random item drops using Chainlink VRF (Coming soon)
- [ ] Marketplace for trading items (Coming soon)

## Smart Contracts

### Implemented:
- [x] `Character.sol`: ERC721 contract for character NFTs
- [x] `Equipment.sol`: ERC1155 contract for equipment NFTs
- [x] `GameToken.sol`: ERC20 contract for in-game currency
- [x] `Quest.sol`: Manages quests and rewards

### Coming Soon:
- [ ] `ItemDrop.sol`: Handles random item drops using Chainlink VRF
- [ ] `Marketplace.sol`: Facilitates trading of equipment NFTs

## Prerequisites

- [x] [Foundry](https://book.getfoundry.sh/getting-started/installation.html)
- [x] [Node.js](https://nodejs.org/) (for development tools)
- [ ] Ethereum wallet (e.g., MetaMask) - Required for deployment
- [ ] Chainlink VRF subscription (for random item drops) - Coming soon

## Setup

1. Clone the repository:

```bash
git clone <repository-url>
cd dnd
```

2. Install dependencies:

```bash
forge install
```

3. Create a `.env` file with the following variables:

```
SEPOLIA_RPC_URL=your_sepolia_rpc_url
MAINNET_RPC_URL=your_mainnet_rpc_url
ETHERSCAN_API_KEY=your_etherscan_api_key
PRIVATE_KEY=your_deployer_private_key
VRF_COORDINATOR=chainlink_vrf_coordinator_address    # Coming soon
VRF_SUBSCRIPTION_ID=your_vrf_subscription_id        # Coming soon
VRF_KEY_HASH=your_vrf_key_hash                     # Coming soon
```

4. Compile contracts:

```bash
forge build
```

5. Run tests:

```bash
forge test
```

## Deployment

1. Deploy to Sepolia testnet:

```bash
forge script script/Deploy.s.sol:Deploy --rpc-url sepolia --broadcast --verify
```

2. Deploy to mainnet:

```bash
forge script script/Deploy.s.sol:Deploy --rpc-url mainnet --broadcast --verify
```

## Testing

The project includes comprehensive tests for all contracts. Run them with:

```bash
# Run all tests
forge test

# Run specific test file
forge test --match-path test/Character.t.sol

# Run with gas reporting
forge test --gas-report

# Run with verbosity
forge test -vvv
```

## Security

Currently implemented:
- [x] OpenZeppelin's battle-tested implementations
- [x] Access control using `Ownable`
- [x] Comprehensive test coverage

Coming soon:
- [ ] Chainlink VRF for secure randomness
- [ ] Reentrancy protection in marketplace transactions

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
